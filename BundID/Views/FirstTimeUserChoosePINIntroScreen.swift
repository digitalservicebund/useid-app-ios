//
//  FirstTimeUserChoosePINIntroScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 04.05.22.
//

import SwiftUI

struct FirstTimeUserChoosePINIntroScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                HeaderView(titleKey: L10n.FirstTimeUser.PersonalPINIntro.title,
                           bodyKey: L10n.FirstTimeUser.PersonalPINIntro.body,
                           imageMeta: ImageMeta(name: "eIDs+PIN"))
            }
            VStack {
                NavigationLink {
                    EmptyView()
                } label: {
                    Text(L10n.FirstTimeUser.PersonalPINIntro.continue)
                }
                .buttonStyle(BundButtonStyle(isPrimary: true))
            }
            .padding()
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}
