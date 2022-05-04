//
//  FirstTimeUserTransportPINScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 03.05.22.
//

import SwiftUI

struct FirstTimeUserTransportPINScreen: View {
    
    @State var enteredPin: String = ""
    @State var isFinished: Bool = false
    @State var showError: Bool = false
    @State var remainingAttempts: Int = 3
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Geben Sie Ihre 5-stellige Transport-PIN aus dem PIN-Brief ein")
                        .font(.bundLargeTitle)
                    ZStack {
                        Image("Transport-PIN")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        PINEntryView(pin: $enteredPin) { _ in
//                            isFinished = true
                            withAnimation {
                                remainingAttempts -= 1
                                showError = true
                                enteredPin = ""
                            }
                        }
                        .font(.bundTitle)
                        .padding(40)
                    }
                    if showError {
                        VStack(spacing: 24) {
                            VStack {
                                Text("Inkorrekte Transport-PIN")
                                    .font(.bundBodyBold)
                                    .foregroundColor(.red900)
                                Text("Versuchen Sie es erneut. Sie haben noch \(remainingAttempts) Versuche.")
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            Button {
                                
                            } label: {
                                Text("Klicken Sie hier, wenn Ihre PIN 6-stellig ist")
                                    .font(.bundBodyBold)
                                    .foregroundColor(.blue800)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    NavigationLink("Weiter", isActive: $isFinished) {
                        FirstTimeUserCheckScreen()
                    }
                    .frame(width: 0, height: 0)
                    .hidden()
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstTimeUserTransportPINScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserTransportPINScreen(showError: true)
                .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserTransportPINScreen()
        }
        .previewDevice("iPhone 12")
    }
}

