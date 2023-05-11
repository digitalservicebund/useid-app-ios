//
//  FaqTile.swift
//  BundesIdent
//
//  Created by Urs Kahmann on 11.05.23.
//

import SwiftUI

struct FaqTile: View {
    let question: String
    let text: String
    @State var showModal: Bool = false
    
    var body: some View {
        Button(action: {
            showModal = true
        }, label: {
            Text(question).bodyMBold().multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 140)
                .frame(height: 50)
                .padding(24)
        })
        .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.04), radius: 32, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.neutral300, lineWidth: 1)
        )
        .popover(isPresented: $showModal) {
            VStack(alignment: .leading) {
                Text(question).headingL()
                    .padding(.vertical)
                Text(text).bodyMRegular()
                Spacer()
                Button("Schließen") { showModal = false }
                    .buttonStyle(BundButtonStyle(isOnDark: false))
                    .padding(.vertical)
            }.padding()
        }
    }
}

struct FaqTile_Previews: PreviewProvider {
    static var previews: some View {
        FaqTile(question: "What do we want?", text: "Pigeon")
    }
}
