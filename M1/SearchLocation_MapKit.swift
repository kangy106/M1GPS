import Foundation
import MapKit

func searchLocations_mapkit(searchText: String, location: CLLocationCoordinate2D, visibleRegion: MKCoordinateRegion?, completion: @escaping ([MKMapItem]) -> Void) {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchText
    request.resultTypes = .pointOfInterest
    request.region = visibleRegion ?? MKCoordinateRegion(
        center: location,
        span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))

    let search = MKLocalSearch(request: request)
    search.start { response, error in
        if let error = error {
            print(error.localizedDescription)
            completion([])
            return
        }
        completion(response?.mapItems ?? [])
    }
}
