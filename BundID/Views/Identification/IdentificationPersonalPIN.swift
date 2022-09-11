import SwiftUI
import Combine
import ComposableArchitecture

struct IdentificationPersonalPINState: Equatable {
    
    var request: EIDAuthenticationRequest
    var callback: PINCallback
    @BindableState var enteredPIN: String = ""
    
    var doneButtonEnabled: Bool {
        return enteredPIN.count == 6
    }
    
    mutating func handlePINChange(_ enteredPIN: String) -> Effect<IdentificationPersonalPINAction, Never> {
        return .none
    }
}

enum IdentificationPersonalPINAction: BindableAction, Equatable {
    case onAppear
    case done(request: EIDAuthenticationRequest, pin: String, pinCallback: PINCallback)
    case binding(BindingAction<IdentificationPersonalPINState>)
}

let identificationPersonalPINReducer = Reducer<IdentificationPersonalPINState, IdentificationPersonalPINAction, AppEnvironment> { state, action, _ in
    switch action {
    case .onAppear:
        return .none
    case .binding(\.$enteredPIN):
        return state.handlePINChange(state.enteredPIN)
    case .binding:
        return .none
    case .done:
        return .none
    }
}.binding()

struct IdentificationPersonalPIN: View {
    
    var store: Store<IdentificationPersonalPINState, IdentificationPersonalPINAction>
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Identification.PersonalPIN.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                     maxDigits: 6,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.Identification.PersonalPIN.textFieldLabel,
                                     shouldBeFocused: .constant(true),
                                     backgroundColor: .gray100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.Identification.PersonalPIN.continue,
                                                                          handler: { pin in
                            viewStore.send(.done(request: viewStore.request,
                                                 pin: pin,
                                                 pinCallback: viewStore.callback))
                        }))
                        .font(.bundTitle)
                    }
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
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
