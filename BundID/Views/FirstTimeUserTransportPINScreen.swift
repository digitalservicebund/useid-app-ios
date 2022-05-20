import SwiftUI

struct FirstTimeUserTransportPINScreen: View {
    
    @State var enteredPIN: String = ""
    @State var isFinished: Bool = false
    @State var previouslyUnsuccessful: Bool = false
    @State var remainingAttempts: Int = 3
    @State var focusTextField: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.FirstTimeUser.TransportPIN.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                    ZStack {
                        Image(decorative: "Transport-PIN")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        PINEntryView(pin: $enteredPIN,
                                     maxDigits: 5,
                                     label: L10n.FirstTimeUser.TransportPIN.textFieldLabel,
                                     shouldBeFocused: $focusTextField,
                                     doneConfiguration: DoneConfiguration(enabled: enteredPIN.count == 5,
                                                                          title: L10n.FirstTimeUser.TransportPIN.continue,
                                                                          handler: handleDone))
                        .font(.bundTitle)
                        .background(
                            Color.white.cornerRadius(10)
                        )
                        .padding(40)
                        // Focus: iOS 15 only
                        // Done button above keyboard: iOS 15 only
                    }
                    if previouslyUnsuccessful {
                        VStack(spacing: 24) {
                            VStack {
                                if enteredPIN == "" {
                                    Text(L10n.FirstTimeUser.TransportPIN.Error.incorrectPIN)
                                        .font(.bundBodyBold)
                                        .foregroundColor(.red900)
                                    Text(L10n.FirstTimeUser.TransportPIN.Error.tryAgain)
                                        .font(.bundBody)
                                        .foregroundColor(.blackish)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                                Text(L10n.FirstTimeUser.TransportPIN.remainingAttemptsLld(remainingAttempts))
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            Button {
                                
                            } label: {
                                Text(L10n.FirstTimeUser.TransportPIN.switchToPersonalPIN)
                                    .font(.bundBodyBold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    NavigationLink(isActive: $isFinished) {
                        FirstTimeUserChoosePINIntroScreen()
                    } label: {
                        Text(L10n.FirstTimeUser.TransportPIN.continue)
                    }
                    .frame(width: 0, height: 0)
                    .hidden()
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func handleDone(_: String) {
        withAnimation {
            isFinished = true
        }
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
