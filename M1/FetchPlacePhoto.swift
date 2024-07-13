import Foundation
import GooglePlaces
import SwiftUI

func fetchPlacePhoto(placeID: String, completion: @escaping (UIImage?, Error?) -> Void) {
    let placesClient = GMSPlacesClient.shared()
    
    placesClient.lookUpPhotos(forPlaceID: placeID) { (photos, error) in
        guard let photos = photos, let photoMetadata = photos.results.first else {
            print("Error fetching photos: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil, error)
            return
        }

        // Request individual photos in the response list
        placesClient.loadPlacePhoto(photoMetadata) { (photo, error) in
            guard let photo = photo else {
                print("Error fetching photo: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, error)
                return
            }
            print("Photo loaded")
            completion(photo, nil)
        }
    }
}
