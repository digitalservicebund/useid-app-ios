import SwiftUI

struct FirstTimeUserPersonalPINScreen: View {
    
    enum Error {
        case mismatch
    }
    
    @State var enteredPIN1: String = ""
    @State var enteredPIN2: String = ""
    @State var showPIN2: Bool = false
    @State var focusPIN1: Bool = true
    @State var focusPIN2: Bool = false
    @State var isFinished: Bool = false
    @State var error: Error?
    @State var attempts: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.FirstTimeUser.PersonalPIN.title)
                    .font(.bundLargeTitle)
                    .foregroundColor(.blackish)
                VStack {
                    Spacer()
                    PINEntryView(pin: $enteredPIN1,
                                 maxDigits: 6,
                                 groupEvery: 3,
                                 showPIN: false,
                                 label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first,
                                 shouldBeFocused: $focusPIN1,
                                 doneConfiguration: nil,
                                 textChangeHandler: handlePIN1Change)
                    .font(.bundTitle)
                    .modifier(Shake(animatableData: CGFloat(attempts)))
                    // Focus: iOS 15 only
                    // Done button above keyboard: iOS 15 only
                    if showPIN2 {
                        VStack {
                            Spacer(minLength: 40)
                            Text(L10n.FirstTimeUser.PersonalPIN.confirmation)
                                .font(.bundBody)
                                .foregroundColor(.blackish)
                            PINEntryView(pin: $enteredPIN2,
                                         maxDigits: 6,
                                         groupEvery: 3,
                                         showPIN: false,
                                         label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                         shouldBeFocused: $focusPIN2,
                                         doneConfiguration: nil,
                                         textChangeHandler: handlePIN2Change)
                            .font(.bundTitle)
                            .modifier(Shake(animatableData: CGFloat(attempts)))
                            Spacer()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                NavigationLink(isActive: $isFinished) {
                    EmptyView()
                } label: {
                    Text("")
                }
                .frame(width: 0, height: 0)
                .hidden()
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFinished = false
        }
    }
    
    func handlePIN1Change(_: String) {
        if !enteredPIN1.isEmpty {
            withAnimation {
                error = nil
            }
        }

        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || enteredPIN2.count > 0
        }
        
        if enteredPIN1.count == 6 {
            focusPIN1 = false
            focusPIN2 = true
        }
    }
    
    func handlePIN2Change(_: String) {
        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || enteredPIN2.count > 0
        }
        
        if enteredPIN2.count == 6 {
            if enteredPIN1 != enteredPIN2 {
                withAnimation {
                    attempts += 1
                }
                withAnimation(.default.delay(0.2)) {
                    error = .mismatch
                    showPIN2 = false
                    enteredPIN2 = ""
                    enteredPIN1 = ""
                    focusPIN2 = false
                    focusPIN1 = true
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
