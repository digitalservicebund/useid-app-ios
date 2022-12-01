import SwiftUI
import Combine
import ComposableArchitecture

struct IdentificationPersonalPINState: Equatable {
    
    var request: EIDAuthenticationRequest
    var callback: PINCallback
    @BindableState var enteredPIN: String = ""
    
    var doneButtonEnabled: Bool {
        return enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
    }
}

enum IdentificationPersonalPINAction: BindableAction, Equatable {
    case onAppear
    case done(request: EIDAuthenticationRequest, pin: String, pinCallback: PINCallback)
    case binding(BindingAction<IdentificationPersonalPINState>)
}

let identificationPersonalPINReducer = Reducer<IdentificationPersonalPINState, IdentificationPersonalPINAction, AppEnvironment> { _, action, _ in
    switch action {
    default:
        return .none
    }
}.binding()

struct IdentificationPersonalPIN: View {
    
    var store: Store<IdentificationPersonalPINState, IdentificationPersonalPINAction>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Identification.PersonalPIN.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                     maxDigits: Constants.PERSONAL_PIN_DIGIT_COUNT,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.Identification.PersonalPIN.textFieldLabel,
                                     backgroundColor: .neutral100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.Identification.PersonalPIN.continue,
                                                                          handler: { pin in
                            viewStore.send(.done(request: viewStore.request,
                                                 pin: pin,
                                                 pinCallback: viewStore.callback))
                        }))
                        .focused($pinEntryFocused)
                        .font(.bundTitle)
                    }
                    Spacer()
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(false)
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
    }
}

struct IdentificationPersonalPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationPersonalPIN(store: Store(initialState: IdentificationPersonalPINState(request: .preview, callback: PINCallback(id: UUID(), callback: { _ in }), enteredPIN: "12345"),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
        NavigationView {
            IdentificationPersonalPIN(store: Store(initialState: IdentificationPersonalPINState(request: .preview, callback: PINCallback(id: UUID(), callback: { _ in })),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
