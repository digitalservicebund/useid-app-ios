//
//  StartView.swift
//  BundesIdent
//
//  Created by Urs Kahmann on 10.05.23.
//

import SwiftUI

struct StartView: View {
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    Color.blue800
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            Text("Willkommen bei BundesIdent!")
                                .headingL(color: .blue100)
                                .accessibilityAddTraits(.isHeader)
                                .padding()
                            
                            Spacer()
                            
                            Image(asset: Asset.homeIcon)
                                .padding()
                        }.padding(.bottom, 100)
                        
                        NavigationLink(destination:
                                        IdentificationInfoView()
                        ) {
                            Text("Jetzt ausweisen")
                        }
                        .buttonStyle(BundButtonStyle(isOnDark: true))
                        .padding()
                    }
                }
                .cornerRadius(8)
                
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
