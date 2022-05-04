//
//  FirstTimeUserCheckScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 29.04.22.
//

import SwiftUI

struct FirstTimeUserCheckScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                HeaderView(title: "Haben Sie Ihren Online-Ausweis bereits benutzt?",
                           text: "Folgende Dokumente bieten die Funktion an: Deutscher Personalausweis, Elektronischer Aufenthaltstitel, eID-Karte für Unionsbürger",
                           imageName: "eIDs")
            }
            VStack {
                Button {
                    
                } label: {
                    Text("Ja, ich habe es bereits genutzt")
                }
                .buttonStyle(BundButtonStyle(isPrimary: false))
                NavigationLink {
                    FirstTimeUserPINLetterScreen()
                } label: {
                    Text("Nein, jetzt Online-Ausweis einrichten")
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

struct FirstTimeUserCheckScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserCheckScreen()
        }
            .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserCheckScreen()
        }
            .previewDevice("iPhone 12")
    }
}
