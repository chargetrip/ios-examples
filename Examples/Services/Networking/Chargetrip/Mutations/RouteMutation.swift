//
//  RouteMutation.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import Foundation
import Combine

struct Query: Encodable {
    let operationName: String
    let query: String
}

extension ChargetripService {
    func createRoute(
            vehicleId: String,
            stateOfCharge: Int,
            departure: GeocodingService.Feature?,
            arrival: GeocodingService.Feature?
    ) -> AnyPublisher<Data, Error> {
        Request<Data>()
            .scheme(.secure)
            .host(.chargetrip)
            .method(.post)
            // request.addValue("application/json", forHTTPHeaderField: "content-type")
            .headers(["content-type": "application/json"])
            .path("/graphql")
            .body(Query(
                operationName: "newRoute",
                query: """
            mutation newRoute {
              newRoute(
                input: {
                  ev: {
                    id: "5d161be5c9eef46132d9d20a",
                    battery: {
                      stateOfCharge: {
                        value: 60.5,
                        type: kwh
                      }
                    },
                    climate: true,
                    occupants: 1
                  }
                  routeRequest: {
                    origin: {
                      type: Feature
                      geometry: { type: Point, coordinates: [9.9936818, 53.5510846] }
                      properties: { name: "Hamburg, Germany" }
                    }
                    destination: {
                      type: Feature
                      geometry: { type: Point, coordinates: [9.1829321, 48.7758459] }
                      properties: { name: "Stuttgart, Germany" }
                    }
                  }
                }
              )
            }
            """))
            .fetch()
    }
}
