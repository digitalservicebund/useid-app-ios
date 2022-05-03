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
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Haben Sie Ihren Online-Ausweis bereits benutzt?")
                            .font(.bundLargeTitle)
                        Text("Folgende Dokumente bieten die Funktion an:\nDeutscher Personalausweis, Elektronischer Aufenthaltstitel, eID-Karte für Unionsbürger")
                            .font(.bundBody)
                    }
                    .padding(.horizontal)
                    Image("eIDs")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
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
