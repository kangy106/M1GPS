import Foundation
import SwiftUI
import MultipeerConnectivity
import MapKit

class ChatViewModel: NSObject, ObservableObject {
    @Published var messages: [String] = []
    @Published var currentMessage = ""
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var inGame = false
    @Published var currentlyThinking = true
    @Published var status = ""
    @Published var placeImage: UIImage?
    @Published var selectedResult: MKMapItem?
    @Published var selectedResult_hiragana: String?
    @Published var previousSelectedResult: MKMapItem?
    @Published var previousSelectedResult_hiragana: String?
    @Published var swapNum = 0
    @Published var turn = 1
    @Published var mode = 0
    @Published var opponent_point = 0
    @Published var my_point = 0
    @Published var isEnd = false
    @Published var firstText = "天橋立荘"
    @Published var firstText_hiragana = "あまのはしだてそう"
    @Published var firstId = "ChIJy93PbGuR_18Rhglqqos3w04"
    @Published var point = 0
    
    @Published var location: CLLocationCoordinate2D = .tokyoStation
    @Published var visibleRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: .tokyoStation,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    
    private let serviceType = "simple-chat"
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    var playerUUIDKey = UUID().uuidString
    
    override init() {
        super.init()
        setupConnectivity()
    }
    
    private func setupConnectivity() {
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    func startSession() {
        DispatchQueue.main.async {
            self.isConnecting = true
            self.mode = Int.random(in: 0...1)
        }
        DispatchQueue.main.async {
            searchLocations_mapkit(searchText: self.firstText, location: self.location, visibleRegion: self.visibleRegion) { places in
                let searchResults_MK = places
                self.selectedResult = places.first
                self.selectedResult_hiragana = self.firstText_hiragana
                if let firstPlace = places.first {
                    self.location = firstPlace.placemark.coordinate // locationを更新
                    self.visibleRegion = MKCoordinateRegion(
                        center: firstPlace.placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
                self.mode = Int.random(in: 0...1)
            }
            
            fetchPlacePhoto(placeID: self.firstId) { image, error in
                if let image = image {
                    DispatchQueue.main.async {
                        self.placeImage = image
                    }
                } else {
                    print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        print("Starting advertising and browsing...")
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func swapRoles() {
        DispatchQueue.main.async {
            self.currentlyThinking = !self.currentlyThinking
            self.swapNum += 1
            self.turn = Int(self.swapNum/2) + 1
            if self.turn == 6 {
                self.isEnd = true
            }
        }
    }
    
    func endSession() {
        print("Stopping advertising and browsing...")
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        DispatchQueue.main.async {
            self.isConnecting = false
            self.isConnected = false
            self.inGame = false
            self.currentlyThinking = true
            self.messages = []
            self.currentMessage = ""
            self.status = ""
            self.placeImage = nil
            self.selectedResult = nil
            self.selectedResult_hiragana = nil
            self.location = .tokyoStation
            self.visibleRegion = MKCoordinateRegion(
                center: .tokyoStation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            self.previousSelectedResult = nil
            self.previousSelectedResult_hiragana = nil
            self.swapNum = 0
            self.turn = 1
            self.mode = 0
            self.opponent_point = 0
            self.my_point = 0
            self.isEnd = false
        }
    }
    
    func sendMessage(_ message: String) {
        if let data = message.data(using: .utf8) {
            do {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                print("データ：\(message)")
                let messageSplit = message.split(separator: ":")
                guard let messagePrefix = messageSplit.first else { return }
                let parameter: String
                if messageSplit.indices.contains(2) {
                    parameter = String(messageSplit[2])
                } else {
                    parameter = ""
                }
                DispatchQueue.main.async {
                    switch messagePrefix {
                    case "answer":
                        self.messages.append("自分:\(parameter)")
                    case "correct":
                        self.messages.append("相手:\(parameter)")
                    default:
                        break
                    }
                    print(self.messages)
                    self.currentMessage = ""
                }
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendString(_ message: String) {
        guard let encoded = message.data(using: .utf8) else { return }
        sendData(encoded, mode: .reliable)
    }
    
    private func sendData(_ data: Data, mode: MCSessionSendDataMode) {
        do {
            try session.send(data, toPeers: session.connectedPeers, with: mode)
        } catch {
            print(error)
        }
    }
    
    private func handleBeganMessage(_ parameter: String) {
        DispatchQueue.main.async {
            if self.playerUUIDKey == parameter {
                self.playerUUIDKey = UUID().uuidString
                self.sendString("began:\(self.playerUUIDKey)")
                return
            }
            
            self.currentlyThinking = self.playerUUIDKey < parameter
            self.inGame = true
        }
    }
    
    private func handleAnswerMessage(_ parameter: String) {
        let messageSplit = parameter.split(separator: ":")
        guard messageSplit.count >= 3 else {
            print("Invalid message format")
            return
        }
        let id = String(messageSplit[3])
        let text = String(messageSplit[2])
        let text_hiragana = String(messageSplit[1])
        guard let point = Int(messageSplit[4]) else {
            print("Invalid point value")
            return
        }
        DispatchQueue.main.async {
            searchLocations_mapkit(searchText: text, location: self.location, visibleRegion: self.visibleRegion) { places in
                let searchResults_MK = places
                self.previousSelectedResult = self.selectedResult
                self.previousSelectedResult_hiragana = self.selectedResult_hiragana
                self.selectedResult = places.first
                self.selectedResult_hiragana = text_hiragana
                self.mode = Int.random(in: 0...1)
            }
            
            fetchPlacePhoto(placeID: id) { image, error in
                if let image = image {
                    DispatchQueue.main.async {
                        self.placeImage = image
                    }
                } else {
                    print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            self.point = point
            self.sendMessage("correct:\(parameter)")
            self.opponent_point += point
            self.swapRoles()
        }
    }
    
    private func handleCorrectMessage(_ parameter: String) {
        DispatchQueue.main.async {
            self.swapRoles()
        }
    }
}

extension ChatViewModel: MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.isConnected = !session.connectedPeers.isEmpty
            let message: String
            switch state {
            case .connected:
                self.isConnecting = false
                self.isConnected = true
                message = "\(peerID.displayName) connected."
                self.sendMessage("began:\(self.playerUUIDKey)")
            case .connecting:
                self.isConnecting = true
                message = "\(peerID.displayName) connecting..."
            case .notConnected:
                self.isConnecting = false
                self.isConnected = false
                self.inGame = false
                message = "\(peerID.displayName) disconnected."
                self.endSession()
            @unknown default:
                message = "\(peerID.displayName) unknown state."
            }
            print(message)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            print(message)
            let messageSplit = message.split(separator: ":")
            guard let messagePrefix = messageSplit.first else { return }
            print(messagePrefix)
            let parameter = String(messageSplit.last ?? "")
            print(parameter)
            switch messagePrefix {
            case "began":
                handleBeganMessage(parameter)
            case "answer":
                let parameter = messageSplit.dropFirst().joined(separator: ":")
                handleAnswerMessage(parameter)
            case "correct":
                handleCorrectMessage(message)
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            print("Advertising failed: \(error.localizedDescription)")
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            print("Browsing failed: \(error.localizedDescription)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}
