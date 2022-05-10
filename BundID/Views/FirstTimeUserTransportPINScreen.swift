//
//  FirstTimeUserTransportPINScreen.swift
//  BundID
//
//  Created by Andreas Ganske on 03.05.22.
//

import SwiftUI

struct FirstTimeUserTransportPINScreen: View {
    
    @State var enteredPIN: String = ""
    @State var isFinished: Bool = false
    @State var previouslyUnsuccessful: Bool = false
    @State var remainingAttempts: Int = 3
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(localized: "FirstTimeUser.TransportPIN.Title")
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                    ZStack {
                        Image(decorative: "Transport-PIN")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        PINEntryView(pin: $enteredPIN,
                                     doneEnabled: enteredPIN.count == 5,
                                     doneText: NSLocalizedString("FirstTimeUser.TransportPIN.Continue", comment: "")) { _ in
                            withAnimation {
                                remainingAttempts -= 1
                                previouslyUnsuccessful = true
                                enteredPIN = ""
                            }
                        }
                        .font(.bundTitle)
                        .padding(40)
                        // Focus: iOS 15 only
                        // Done button above keyboard: iOS 15 only
                    }
                    if previouslyUnsuccessful {
                        VStack(spacing: 24) {
                            VStack {
                                if enteredPIN == "" {
                                    Text(localized: "FirstTimeUser.TransportPIN.Error.IncorrectPIN")
                                        .font(.bundBodyBold)
                                        .foregroundColor(.red900)
                                    Text(localized: "FirstTimeUser.TransportPIN.Error.TryAgain")
                                        .font(.bundBody)
                                        .foregroundColor(.blackish)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                                Text("FirstTimeUser.TransportPIN.RemainingAttempts\(remainingAttempts)")
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            Button {
                                
                            } label: {
                                Text("FirstTimeUser.TransportPIN.SwitchToPersonalPIN")
                                    .font(.bundBodyBold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    NavigationLink(isActive: $isFinished) {
                        EmptyView()
                    } label: {
                        Text(localized: "FirstTimeUser.TransportPIN.Continue")
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
            FirstTimeUserTransportPINScreen(previouslyUnsuccessful: true)
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserTransportPINScreen(enteredPIN: "1234",
                                            previouslyUnsuccessful: true)
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserTransportPINScreen(enteredPIN: "12345",
                                            previouslyUnsuccessful: true)
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserTransportPINScreen()
        }
        .previewDevice("iPhone 12")
    }
}
