//
//  MenuView.swift
//  Guess The Doodle
//
//  Created by yuma@duck, 2023.
//

import SwiftUI
import MapKit
import GooglePlaces

struct GameView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var inputText = ""
    @State private var searchResults_MK: [MKMapItem] = []
    @State private var searchResults_GMS: [GMSPlace] = []
    
    @State private var position: MapCameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
    @State private var selectedGMSResult: GMSPlace?
    @State private var distance: CLLocationDistance?
    @State private var status: String?
    
    
    var body: some View {
        ZStack {
            GeometryReader { _ in
                Image("drawerBg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(1.1)
                
                VStack {
                    topBar
                    place
                    pastText
                }
                .padding(.horizontal, 30)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
            VStack {
                Spacer()
                
                promptGroup
            }
            .ignoresSafeArea(.container)
        }
    }
    var topBar: some View {
        ZStack {
            HStack {
                Button {
                    chatViewModel.endSession()
                } label: {
                    Image(systemName: "arrowshape.turn.up.left.circle.fill")
                        .font(.largeTitle)
                        .tint(Color("primaryYellow"))
                }
                
                Spacer()
                
                Text("TURN \(chatViewModel.turn)")
                    .bold()
                    .font(.title2)
                    .foregroundColor(Color("primaryYellow"))
                Spacer()
                Text("自分\(chatViewModel.my_point)")
                    .bold()
                    .font(.title2)
                    .foregroundColor(Color("primaryYellow"))
                Text("相手\(chatViewModel.opponent_point)")
                    .bold()
                    .font(.title2)
                    .foregroundColor(Color("primaryYellow"))
            }
        }
        .padding(.vertical, 15)
    }
    
    var pastText: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                ForEach(chatViewModel.messages, id: \.self) { message in
                    HStack {
                        Text(message)
                            .font(.title2)
                            .foregroundColor(Color("primaryYellow"))
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 1)
                }
            }
            .onChange(of: chatViewModel.messages) {
                if let lastMessage = chatViewModel.messages.last {
                    scrollViewProxy.scrollTo(lastMessage, anchor: .bottom)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 100)
        .background(
            (Color(red: 0.243, green: 0.773, blue: 0.745))
                .opacity(0.5)
                .brightness(-0.2)
        )
        
        .cornerRadius(20)
        .padding(.vertical)
        .padding(.bottom, 130)
        
    }
    var place: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) { // VStackで縦に並べる
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color(red: 0.243, green: 0.773, blue: 0.745)
                            .opacity(0.5)
                            .brightness(-0.2)
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height - 80) // 親ビューのサイズを調整して下部のスペースを確保
                    
                    if let image = chatViewModel.placeImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height - 80) // 下部のスペース分調整
                            .clipped()
                        
                        Map(position: $position, selection: $chatViewModel.selectedResult) {
                            if let selectedResult = chatViewModel.selectedResult {
                                Marker(item: selectedResult)
                            }
                        }
                        .frame(width: 100, height: 100) // マップのサイズを指定
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .padding([.top, .trailing], 10) // 右上に配置
                    }
                }
                
                if let distance = distance,
                   let previousSelectedResult = chatViewModel.previousSelectedResult_hiragana,
                   let selectedResult = chatViewModel.selectedResult_hiragana {
                    Text("\(previousSelectedResult)→ \(selectedResult): \(String(format: "%.1f", distance))km \(chatViewModel.point)pt")
                        .font(.title2)
                        .foregroundColor(Color("primaryYellow"))
                        .bold()
                        .frame(width: geometry.size.width, height: 80)
                        .background(
                            Color(red: 0.243, green: 0.773, blue: 0.745)
                                .opacity(0.5)
                                .brightness(-0.2)
                        )
                        .font(.title)
                    
                } else {
                    Rectangle()
                        .fill(Color(red: 0.243, green: 0.773, blue: 0.745))
                        .opacity(0.5)
                        .brightness(-0.2)
                        .frame(width: geometry.size.width, height: 80)
                }
            }
        }
        .onChange(of: chatViewModel.selectedResult) {
            updateMapRegion()
        }
        .onChange(of: chatViewModel.selectedResult) {
            updateMapRegion()
            calculateDistance()
        }
        .onChange(of: selectedGMSResult) {
            if let placeID = selectedGMSResult?.placeID {
                fetchPlacePhoto(placeID: placeID) { image, error in
                    if let image = image {
                        DispatchQueue.main.async {
                            chatViewModel.placeImage = image
                        }
                    } else {
                        print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    
    var promptGroup: some View {
        VStack {
            HStack {
                Label(
                    status != nil && !status!.isEmpty
                    ? status!
                    : (chatViewModel.currentlyThinking
                       ? (chatViewModel.selectedResult_hiragana != nil
                          ? (chatViewModel.mode == 0 ? "「\(chatViewModel.selectedResult_hiragana!.last!)」から始まる近い場所":"「\(chatViewModel.selectedResult_hiragana!.last!)」から始まる遠い場所")
                          : "場所を入力してください:")
                       : "相手のターン中..."),
                    systemImage: "exclamationmark.bubble.fill"
                )
                .font(.title2)
                .bold()
                .foregroundColor(Color("primaryYellow"))
                
                Spacer()
            }
            
            HStack {
                if (chatViewModel.currentlyThinking) {
                    TextField("Type place name", text: $inputText)
                        .padding()
                        .background(
                            Capsule(style: .circular)
                                .fill(.white)
                        )
                        .onSubmit(makeAnswer)
                    Button {
                        makeAnswer()
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .renderingMode(.original)
                            .foregroundColor(Color("primaryYellow"))
                            .font(.system(size: 50))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding([.horizontal, .bottom], 30)
        .padding(.vertical)
        .background(
            (Color(red: 0.243, green: 0.773, blue: 0.745))
                .opacity(0.5)
                .brightness(-0.2)
        )
    }
    func makeAnswer() {
        guard inputText != "" else { return }
        searchLocations_mapkit(searchText: inputText, location: chatViewModel.location, visibleRegion: chatViewModel.visibleRegion) { places in
            self.searchResults_MK = places
            let input_hiragana = TextConverter.convert(inputText, to: .hiragana)
            if input_hiragana.isEmpty {
                status = "文字を入力してください"
                return
            } else {
                if let selectedResultHiragana = chatViewModel.selectedResult_hiragana, !selectedResultHiragana.isEmpty {
                    print("selectedResult_hiragana: \(selectedResultHiragana)")
                    
                    if let inputFirst = input_hiragana.first, let inputLast = input_hiragana.last, var selectedLast = selectedResultHiragana.last {
                        if selectedLast == "ゃ" {
                            selectedLast = "や"
                        }
                        if selectedLast == "ゅ" {
                            selectedLast = "ゆ"
                        }
                        if selectedLast == "ょ" {
                            selectedLast = "よ"
                        }
                        if inputLast == "ん" {
                            status = "「ん」で終わります"
                            return
                        }
                        if inputFirst == selectedLast {
                            print("ok!")
                        } else {
                            status = "「\(selectedLast)」から始めてください"
                            return
                        }
                    } else {
                        print("inputFirst or selectedLast is nil")
                    }
                } else {
                    print("selectedResult_hiragana is nil or empty")
                }
            }
            if let firstResult = places.first {
                status = nil
                chatViewModel.previousSelectedResult = chatViewModel.selectedResult
                chatViewModel.previousSelectedResult_hiragana = chatViewModel.selectedResult_hiragana
                chatViewModel.selectedResult = places.first
                chatViewModel.selectedResult_hiragana = input_hiragana
                print(chatViewModel.selectedResult?.name ?? "")
                searchLocations_mapapi(searchText: firstResult.name ?? "") { places in
                    self.searchResults_GMS = places
                    if let firstPlace = places.first {
                        self.selectedGMSResult = firstPlace
                        print(self.selectedGMSResult?.name ?? "")
                        calculateDistance()
                        calculatePoint()
                        chatViewModel.my_point += chatViewModel.point
                        let message = "answer:\(inputText):\(input_hiragana):\(chatViewModel.selectedResult?.name ?? "No MK result"):\(self.selectedGMSResult?.placeID ?? "No GMS result"):\(chatViewModel.point)"
                        chatViewModel.sendMessage(message)
                        inputText = ""
                    }
                }
            } else {
                status = "そのような場所はありません"
            }
        }
    }
    private func updateMapRegion() {
        if let result = chatViewModel.selectedResult {
            let region = MKCoordinateRegion(center: result.placemark.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            position = .region(region)
            chatViewModel.location = result.placemark.coordinate // 位置情報を更新
            chatViewModel.visibleRegion = region // 可視領域を更新
        }
    }
    private func calculateDistance() {
        guard let previousResult = chatViewModel.previousSelectedResult, let currentResult = chatViewModel.selectedResult else { return }
        let previousLocation = CLLocation(latitude: previousResult.placemark.coordinate.latitude, longitude: previousResult.placemark.coordinate.longitude)
        let currentLocation = CLLocation(latitude: currentResult.placemark.coordinate.latitude, longitude: currentResult.placemark.coordinate.longitude)
        distance = previousLocation.distance(from: currentLocation)/1000
    }
    
    private func calculatePoint() {
        guard let distance = self.distance else { return }
        if chatViewModel.mode == 0 {
            if (distance <= 10) {
                chatViewModel.point = 5
            } else if (distance <= 50) {
                chatViewModel.point = 4
            } else if (distance <= 100) {
                chatViewModel.point = 3
            } else if (distance <= 500) {
                chatViewModel.point = 2
            } else {
                chatViewModel.point = 1
            }
        } else {
            if (distance < 50) {
                chatViewModel.point = 1
            } else if (distance < 100) {
                chatViewModel.point = 2
            } else if (distance < 300) {
                chatViewModel.point = 3
            } else if (distance < 500) {
                chatViewModel.point = 4
            } else {
                chatViewModel.point = 5
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(chatViewModel: ChatViewModel())
    }
}
