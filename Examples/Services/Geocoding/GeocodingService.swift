//
//  Geocoding.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import Foundation
import Combine

struct GeocodingService {
    func forward(searchText: String) -> AnyPublisher<GeocodingService.GeoLocation, Error> {
        // swiftlint:disable line_length
        Request<GeoLocation>()
            .scheme(.secure)
            .host(.mapbox)
            .path("/geocoding/v5/mapbox.places/\(searchText).json")
            .queryItems([
                URLQueryItem(
                    name: "access_token",
                    value: ""
                )
            ])
            .fetchAsModel()
    }
}
