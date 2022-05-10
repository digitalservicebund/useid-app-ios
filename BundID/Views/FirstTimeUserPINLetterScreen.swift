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
                HeaderView(titleKey: "FirstTimeUser.PINLetter.Title",
                           bodyKey: "FirstTimeUser.PINLetter.Body",
                           imageMeta: ImageMeta(name: "PIN-Brief", labelKey: "FirstTimeUser.PINLetter.ImageAlt"))
            }
            VStack {
                NavigationLink {
                    FirstTimeUserTransportPINScreen()
                } label: {
                    Text("FirstTimeUser.PINLetter.Yes")
                }
                .buttonStyle(BundButtonStyle(isPrimary: false))
                NavigationLink {
                    
                } label: {
                    Text("FirstTimeUser.PINLetter.No")
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
