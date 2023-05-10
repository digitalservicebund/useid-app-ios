//
//  IdentificationInfo.swift
//  BundesIdent
//
//  Created by Urs Kahmann on 10.05.23.
//

import ComposableArchitecture
import SwiftUI
import MarkdownUI


struct IdentificationInfoView: View {
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(asset: Asset.widgetSwitch)
                Spacer()
            }
            .padding(.top, 32)
            
            Text("Sie wollen sich bei einem Service ausweisen?")
                .headingL(color: .black)
                .padding(.vertical)
            
            Markdown("Suchen Sie auf der Internetseite Ihres Services nach der Option **\"Mit BundesIdent ausweisen**\". Tippen Sie darauf und starten Sie Ihre Identifizierung.")
                .markdownTheme(.bund)
                .padding(.vertical)
           
            Spacer()
            NavigationLink(destination: WaitingForIdentView()) {
                Text("Verstanden")
            }
            .buttonStyle(BundButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom)
        .navigationBarBackButtonHidden(true)
    }
}

struct IdentificationInfo_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationInfoView()
    }
}
