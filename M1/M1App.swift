import SwiftUI
import GooglePlaces
import GoogleMaps

@main
struct M1App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    let locationManager = CLLocationManager()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyDj-CmPmozmkXKyb6MBwXeT9TDNd5w8sW8")
        GMSPlacesClient.provideAPIKey("AIzaSyDj-CmPmozmkXKyb6MBwXeT9TDNd5w8sW8")
        return true
    }
}
