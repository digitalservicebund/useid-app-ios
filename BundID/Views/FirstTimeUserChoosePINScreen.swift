import SwiftUI

struct FirstTimeUserPersonalPINScreen: View {
    
    enum Error {
        case mismatch
    }
    
    @State var enteredPIN1: String = ""
    @State var enteredPIN2: String = ""
    @State var isFinished: Bool = false
    @State var error: Error?
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.FirstTimeUser.TransportPIN.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                    VStack {
                        Spacer()
                        PINEntryView(pin: $enteredPIN1,
                                     maxDigits: 6,
                                     showPIN: false,
                                     label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first,
                                     doneConfiguration: nil,
                        textChangeHandler: handlePIN1Change)
                        .font(.bundTitle)
                        Spacer()
                        // Focus: iOS 15 only
                        // Done button above keyboard: iOS 15 only
                        if enteredPIN1.count >= 6 || enteredPIN2.count > 0 {
                            Text(L10n.FirstTimeUser.PersonalPIN.confirmation)
                                .font(.bundBody)
                                .foregroundColor(.blackish)
                            PINEntryView(pin: $enteredPIN2,
                                         maxDigits: 6,
                                         showPIN: false,
                                         label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                         doneConfiguration: nil,
                                         textChangeHandler: handlePIN2Change)
                            .font(.bundTitle)
                            .animation(.easeInOut)
                            .transition(.move(edge: .bottom))
                            Spacer()
                        }
                    }
                    if case .mismatch = error {
                        VStack(spacing: 24) {
                            VStack {
                                Text(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title)
                                    .font(.bundBodyBold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.red900)
                                Text(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.body)
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    NavigationLink(isActive: $isFinished) {
                        EmptyView()
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
        .onAppear {
            isFinished = false
        }
    }
    
    func handlePIN1Change(_: String) {
        if !enteredPIN1.isEmpty {
            error = nil
        }
    }
    
    func handlePIN2Change(_: String) {
        if enteredPIN2.count == 6 {
            if enteredPIN1 != enteredPIN2 {
                withAnimation {
                    error = .mismatch
                    enteredPIN1 = ""
                    enteredPIN2 = ""
                }
            } else {
                isFinished = true
            }
        }
    }
}

struct FirstTimeUserPersonalPINScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserPersonalPINScreen()
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPersonalPINScreen(enteredPIN1: "123456", enteredPIN2: "12", isFinished: false, error: nil)
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPersonalPINScreen(enteredPIN1: "123456", enteredPIN2: "987654", isFinished: false, error: .mismatch)
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPersonalPINScreen(enteredPIN1: "123456")
        }
        .previewDevice("iPhone 12")
    }
}
