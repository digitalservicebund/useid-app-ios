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
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                }
                .bodyMRegular(color: .blue800)
                .padding(.vertical)
                    
                    
                HStack {
                    Spacer()
                    Image(asset: Asset.widgetSwitch)
                    Spacer()
                }
                .padding(.vertical, 32)
                
                Text("Sie wollen sich bei einem Service ausweisen?")
                    .headingL(color: .black)
                    .padding(.vertical)
                
                Text("Suchen Sie auf der Internetseite Ihres Services nach der Option \"Mit BundesIdent ausweisen\". Tippen Sie darauf und starten Sie Ihre Identifizierung.")
                    .bodyLRegular(color: .black)
                    
               
                
//                Markdown("Suchen Sie auf der Internetseite Ihres Services nach der Option **\"Mit BundesIdent ausweisen**\". Tippen Sie darauf und starten Sie Ihre Identifizierung.")
//                    .markdownTheme(.bund)
//                    .padding(.vertical)
                
                Spacer()
                NavigationLink(destination: WaitingForIdentView()) {
                    Text("Loslegen")
                }
                .buttonStyle(BundButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom)
        }
    }
}

struct IdentificationInfo_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationInfoView()
    }
}
