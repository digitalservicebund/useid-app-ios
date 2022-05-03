//
//  FirstTimeUserTransportPINScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 03.05.22.
//

import SwiftUI

struct FirstTimeUserTransportPINScreen: View {
    
    enum ResponderFields: Int {
            case pin
        }
    
    @State private var firstResponder: ResponderFields? = nil
    @State var text: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Geben Sie Ihre 5-stellige Transport-PIN aus dem PIN-Brief ein")
                        .font(.bundLargeTitle)
                    ZStack {
                        Image("Transport-PIN")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        PINEntryView(handler: { _ in })
                        .font(.bundTitle)
                        .padding(40)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstTimeUserTransportPINScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserTransportPINScreen()
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserTransportPINScreen()
        }
        .previewDevice("iPhone 12")
    }
}

