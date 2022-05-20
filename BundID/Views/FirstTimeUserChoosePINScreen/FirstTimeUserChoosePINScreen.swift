import SwiftUI
import Combine

enum FirstTimeUserPersonalPINScreenError {
    case mismatch
}

struct FirstTimeUserPersonalPINScreen: View {
    
    @ObservedObject var viewModel: FirstTimeUserPersonalPINScreenViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.FirstTimeUser.PersonalPIN.title)
                    .font(.bundLargeTitle)
                    .foregroundColor(.blackish)
                VStack {
                    Spacer()
                    PINEntryView(pin: $viewModel.enteredPIN1,
                                 maxDigits: 6,
                                 groupEvery: 3,
                                 showPIN: false,
                                 label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first,
                                 shouldBeFocused: $viewModel.focusPIN1,
                                 doneConfiguration: nil)
                    .font(.bundTitle)
                    .modifier(Shake(animatableData: CGFloat(viewModel.attempts)))
                    if viewModel.showPIN2 {
                        VStack {
                            Spacer(minLength: 40)
                            Text(L10n.FirstTimeUser.PersonalPIN.confirmation)
                                .font(.bundBody)
                                .foregroundColor(.blackish)
                            PINEntryView(pin: $viewModel.enteredPIN2,
                                         maxDigits: 6,
                                         groupEvery: 3,
                                         showPIN: false,
                                         label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                         shouldBeFocused: $viewModel.focusPIN2,
                                         doneConfiguration: nil)
                            .font(.bundTitle)
                            .modifier(Shake(animatableData: CGFloat(viewModel.attempts)))
                            Spacer()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                if case .mismatch = viewModel.error {
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
                
                NavigationLink(isActive: $viewModel.isFinished) {
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
            viewModel.isFinished = false
        }
    }
}

struct FirstTimeUserPersonalPINScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserPersonalPINScreen(viewModel: FirstTimeUserPersonalPINScreenViewModel())
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPersonalPINScreen(viewModel: FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456", enteredPIN2: "12", isFinished: false, error: nil))
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPersonalPINScreen(viewModel: FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456", enteredPIN2: "987654", isFinished: false, error: .mismatch))
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPersonalPINScreen(viewModel: FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456"))
        }
        .previewDevice("iPhone 12")
    }
}
