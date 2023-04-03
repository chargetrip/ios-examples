//
//  ContentView.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import SwiftUI

struct ContentView: View {
    var views = [
        (label: "Navigation example", view: AnyView(NavigationExample()))
    ]

    var body: some View {
        ZStack {
            NavigationView {
                List(views.indices, id: \.self) { index in
                    NavigationLink(destination: views[index].view) {
                        Text(views[index].label)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
