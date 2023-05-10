//
//  StartView.swift
//  BundesIdent
//
//  Created by Urs Kahmann on 10.05.23.
//

import SwiftUI

struct StartView: View {
    
    @ViewBuilder
    private var availableServices: some View {
        VStack(alignment: .leading) {
            Text("Verfügbar bei:")
                .bodyMBold(color: .gray)
                .padding(.vertical)
            
            ScrollView(.horizontal) {
                HStack(spacing: 25) {
                    ForEach(0..<5) { _ in
                            HStack {
                                Text("Bundesagentur für Arbeit")
                                    .bodyMBold(color: .blue700)
                                    .padding()
                                   
                            }
                            .background(.white)
                            .cornerRadius(8)
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var identTile: some View {
        VStack(alignment: .leading) {
            
                Text("Willkommen bei BundesIdent!")
                    .headingXL(color: .black)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.vertical)
            
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.")
                    .bodyMRegular(color: .black)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 40)
                
            
            
            NavigationLink(destination:
                            IdentificationInfoView()
            ) {
                Text("Ich will mich ausweisen")
            }
            .buttonStyle(BundButtonStyle(isOnDark: false))
            .padding(.vertical)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                Image(asset: Asset.eagle)
                    .padding(.top, 20)
                
                Text("BundesIdent App")
                    .bodyMBold(color: .neutral900)
                    .padding(.top)
                    .padding(.bottom, 48)
               

                identTile
                
//                availableServices
                
                Spacer()
                
            }
            .padding(.horizontal)
            .background(Color.blue100)
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
