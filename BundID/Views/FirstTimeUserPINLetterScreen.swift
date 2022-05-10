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
                HeaderView(titleKey: "firstTimeUser_pinLetter_title",
                           bodyKey: "firstTimeUser_pinLetter_body",
                           imageMeta: ImageMeta(name: "PIN-Brief"))
            }
            VStack {
                NavigationLink {
                    FirstTimeUserTransportPINScreen()
                } label: {
                    Text("firstTimeUser_pinLetter_yes")
                }
                .buttonStyle(BundButtonStyle(isPrimary: false))
                NavigationLink {
                    
                } label: {
                    Text("firstTimeUser_pinLetter_no")
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
