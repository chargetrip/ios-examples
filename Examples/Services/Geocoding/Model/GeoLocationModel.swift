//
//  GeoLocationModel.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

// swiftlint:disable nesting

import Foundation

extension GeocodingService {
    struct GeoLocation: Codable {
        let type: String
        let query: [String]
        let features: [Feature]
        let attribution: String
    }

    // MARK: - Feature
    struct Feature: Codable, Identifiable {
        let id, type: String
        let placeType: [String]
        let relevance: Int
        let properties: Properties
        let text, placeName: String
        let bbox: [Double]?
        let center: [Double]
        let geometry: Geometry
        let context: [Context]

        enum CodingKeys: String, CodingKey {
            case id, type
            case placeType = "place_type"
            case relevance, properties, text
            case placeName = "place_name"
            case bbox, center, geometry, context
        }
    }

    // MARK: - Context
    struct Context: Codable {
        let id: String
        let wikidata: String?
        let mapboxID, text: String
        let shortCode: String?

        enum CodingKeys: String, CodingKey {
            case id, wikidata
            case mapboxID = "mapbox_id"
            case text
            case shortCode = "short_code"
        }
    }

    // MARK: - Geometry
    struct Geometry: Codable {
        let type: String
        let coordinates: [Double]
    }

    // MARK: - Properties
    struct Properties: Codable {
        let wikidata, mapboxID, foursquare: String?
        let landmark: Bool?
        let address, category, maki: String?

        enum CodingKeys: String, CodingKey {
            case wikidata
            case mapboxID = "mapbox_id"
            case foursquare, landmark, address, category, maki
        }
    }
}
