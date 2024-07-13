import Foundation
import GooglePlaces

func searchLocations_mapapi(searchText: String, completion: @escaping ([GMSPlace]) -> Void) {
    let placesClient = GMSPlacesClient.shared()
    let filter = GMSAutocompleteFilter()
    filter.type = .establishment

    placesClient.findAutocompletePredictions(fromQuery: searchText, filter: filter, sessionToken: nil) { (predictions, error) in
        guard let predictions = predictions, error == nil else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            completion([])
            return
        }

        var places: [GMSPlace] = []
        let dispatchGroup = DispatchGroup()

        for prediction in predictions {
            dispatchGroup.enter()
            placesClient.fetchPlace(fromPlaceID: prediction.placeID, placeFields: [.name, .placeID, .coordinate, .formattedAddress], sessionToken: nil) { (place, error) in
                if let place = place {
                    places.append(place)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(places)
        }
    }
}
