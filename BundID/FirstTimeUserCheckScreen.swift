//
//  FirstTimeUserCheckScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 29.04.22.
//

import SwiftUI

struct FirstTimeUserCheckScreen: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Haben Sie Ihren Online-Ausweis bereits benutzt?")
                            .font(.bundLargeTitle)
                        Text("Folgende Dokumente bieten die Funktion an:\nDeutscher Personalausweis, Elektronischer Aufenthaltstitel, eID-Karte für Unionsbürger")
                            .font(.bundBody)
                    }
                    Image("eIDs")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        Button {
                            
                        } label: {
                            Text("Ja, ich habe es bereits genutzt")
                        }
                        .buttonStyle(BundButtonStyle(isPrimary: false))
                        Button {
                            
                        } label: {
                            Text("Nein, jetzt Online-Ausweis einrichten")
                        }
                        .buttonStyle(BundButtonStyle(isPrimary: true))
                    }
                    .padding()
                    .background(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FirstTimeUserCheckScreen_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeUserCheckScreen()
            .previewDevice("iPhone SE (2nd generation)")
        FirstTimeUserCheckScreen()
            .previewDevice("iPhone 12 mini")
    }
}
