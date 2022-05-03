//
//  FirstTimeUserPINLetterScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 29.04.22.
//

import SwiftUI

struct FirstTimeUserPINLetterScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Haben Sie noch Ihren PIN-Brief?")
                            .font(.bundLargeTitle)
                        Text("Der PIN-Brief wurde Ihnen nach der Beantragung des Ausweises zugesandt.")
                            .font(.bundBody)
                    }
                    .padding(.horizontal)
                    Image("PIN-Brief")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            VStack {
                NavigationLink {
                    FirstTimeUserTransportPINScreen()
                } label: {
                    Text("Ja, PIN-Brief vorhanden")
                }
                .buttonStyle(BundButtonStyle(isPrimary: false))
                NavigationLink {
                    
                } label: {
                    Text("Nein, neuen PIN-Brief bestellen")
                }
                .buttonStyle(BundButtonStyle(isPrimary: true))
                
            }
            .padding([.leading, .bottom, .trailing])
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstTimeUserPINLetterScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserPINLetterScreen()
        }
        .environment(\.sizeCategory, .extraExtraExtraLarge)
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPINLetterScreen()
        }
        .previewDevice("iPhone 12")
    }
}
