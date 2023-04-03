//
//  NavigationExample.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import SwiftUI

struct NavigationExample: View {
    @FocusState private var focusedField: String?
    @StateObject var viewModel: ViewModel = ViewModel()

    var body: some View {
        VStack {
            TextField("Departure", text: $viewModel.departureText)
                .focused($focusedField, equals: "departure")
                .frame(height: 40)
                .padding(.horizontal, 8)

            TextField("Arrival", text: $viewModel.arrivalText)
                .focused($focusedField, equals: "arrival")
                .frame(height: 40)
                .padding(.horizontal, 8)

            Menu {
                Button("Volkswagen ID.4") {
                    viewModel.didSelectVehicle(id: "5f7efa7f078a07ad0bde7877")
                }

                Button("Polestar 2") {
                    viewModel.didSelectVehicle(id: "6076309444b3fd170baded00")
                }
            } label: {
                 Text("Select vehicle")
            }

            Button("Navigate") {
                viewModel.computeNavigation()
            }
        }

        if !viewModel.data.isEmpty {
            List(viewModel.data) { result in
                Text(result.placeName)
                    .onTapGesture {
                        viewModel.didSelectLocation(location: result, focusedField: focusedField!)
                        focusedField = nil
                    }
            }
        }
    }
}

struct NavigationExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationExample()
    }
}
