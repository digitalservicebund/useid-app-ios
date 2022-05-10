//
//  FirstTimeUserCheckScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 29.04.22.
//

import SwiftUI

extension Text {
    init(localized: String) {
        self.init(LocalizedStringKey(localized))
    }
}

struct FirstTimeUserCheckScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                HeaderView(titleKey: "firstTimeUser_intro_title",
                           bodyKey: "firstTimeUser_intro_body",
                           imageMeta: ImageMeta(name: "eIDs"))
            }
            VStack {
                Button {
                    
                } label: {
                    Text("firstTimeUser_intro_yes")
                }
                .buttonStyle(BundButtonStyle(isPrimary: false))
                NavigationLink {
                    FirstTimeUserPINLetterScreen()
                } label: {
                    Text("firstTimeUser_intro_no")
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
