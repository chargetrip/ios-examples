//
//  NavigationExampleViewModel.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import Foundation
import Combine

extension NavigationExample {
    class ViewModel: ObservableObject {
        @Published var data: [GeocodingService.Feature] = []
        @Published var departureText: String = ""
        @Published var arrivalText: String = ""

        private var cancellable = Set<AnyCancellable>()

        private var selectedVehicleID: String = "5f7efa7f078a07ad0bde7877"
        private var departureLocation: GeocodingService.Feature?
        private var arrivalLocation: GeocodingService.Feature?

        init() {
            // FIX prevent empty request when there is no typing going on init
            $departureText
                .removeDuplicates()
                .debounce(for: 0.2, scheduler: DispatchQueue.main)
                .sink { _ in
                    self.search(text: self.departureText)
                }
                .store(in: &cancellable)

            $arrivalText
                .removeDuplicates()
                .debounce(for: 0.2, scheduler: DispatchQueue.main)
                .sink { _ in
                    self.search(text: self.arrivalText)
                }
                .store(in: &cancellable)
        }

        func search(text: String) {
            GeocodingService()
                .forward(searchText: text)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] value in
                    guard let self = self else { return }
                    self.data = value.features
                })
                .store(in: &cancellable)
        }

        func didSelectVehicle(id: String) {
            selectedVehicleID = id
        }

        func didSelectLocation(location: GeocodingService.Feature, focusedField: String) {
            if focusedField == "departure" {
                departureLocation = location
            } else {
                arrivalLocation = location
            }

            data = []
        }

        func computeNavigation() {
            ChargetripService()
                .createRoute(
                    vehicleId: selectedVehicleID,
                    stateOfCharge: 80,
                    departure: departureLocation,
                    arrival: arrivalLocation
                )
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        break
                    }
                }, receiveValue: { value in
                    let str = String(decoding: value, as: UTF8.self)
                    print(str)
//                    do {
//                        let json = try JSONSerialization.jsonObject(with: value, options: []) as? [String : Any]
//                        print(json)
//                    } catch let error {
//                        print("errorMsg", error)
//                    }
                })
                .store(in: &cancellable)
        }
    }
}
