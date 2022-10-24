import ComposableArchitecture
import SwiftUI

struct IdentificationOverviewLoadedState: Identifiable, Equatable {
    let id: UUID
    let request: EIDAuthenticationRequest
    var handler: IdentifiableCallback<FlaggedAttributes>
    let canGoBackToSetupIntro: Bool
    
    // used when going back to the overview screen when we already received a pin handler
    var pinHandler: PINCallback?
    
    init(id: UUID, request: EIDAuthenticationRequest, handler: IdentifiableCallback<FlaggedAttributes>, canGoBackToSetupIntro: Bool = false, pinHandler: PINCallback? = nil) {
        self.id = id
        self.request = request
        self.handler = handler
        self.canGoBackToSetupIntro = canGoBackToSetupIntro
        self.pinHandler = pinHandler
    }
    
    var requiredReadAttributes: IdentifiedArrayOf<IDCardAttribute> {
        let requiredAttributes = request.readAttributes.compactMap { (key: IDCardAttribute, isRequired: Bool) in
            isRequired ? key : nil
        }
        return IdentifiedArrayOf(uniqueElements: requiredAttributes)
    }
}

enum IdentificationOverviewLoadedAction: Equatable {
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case moreInfo
    case callbackReceived(EIDAuthenticationRequest, PINCallback)
    case confirm
    case failure(IdentifiableError)
}

let identificationOverviewLoadedReducer = Reducer<IdentificationOverviewLoadedState, IdentificationOverviewLoadedAction, AppEnvironment> { state, action, environment in
    switch action {
    case .idInteractionEvent(.success(.requestPIN(remainingAttempts: nil, pinCallback: let handler))):
        let pinHandler = PINCallback(id: environment.uuidFactory(), callback: handler)
        state.pinHandler = pinHandler
        return Effect(value: .callbackReceived(state.request, pinHandler))
    case .idInteractionEvent(.failure(let error)):
        return Effect(value: .failure(IdentifiableError(error)))
    case .idInteractionEvent:
        return .none
    case .confirm:
        if let pinHandler = state.pinHandler {
            return Effect(value: .callbackReceived(state.request, pinHandler))
        } else {
            let dict = Dictionary(uniqueKeysWithValues: state.requiredReadAttributes.map { ($0, true) })
            state.handler(dict)
            return .none
        }
    case .failure:
        return .none
    case .callbackReceived:
        return .none
    case .moreInfo:
        return .none
    }
}

struct IdentificationOverviewLoaded: View {
    var store: Store<IdentificationOverviewLoadedState, IdentificationOverviewLoadedAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HeaderView(title: L10n.Identification.AttributeConsent.title(viewStore.request.subject),
                                   message: L10n.Identification.AttributeConsent.body)
                        .padding(.horizontal)
                        
                        attributesBox
                        
                        NavigationLink.init(L10n.Identification.AttributeConsent.moreInfo) {
                            IdentificationAbout(request: viewStore.request)
                        }
                        .buttonStyle(BundTextButtonStyle())
                        .padding([.horizontal, .bottom])
                    }
                }
                DialogButtons(store: store.stateless,
                              primary: .init(title: L10n.Identification.AttributeConsent.continue, action: .confirm))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var attributesBox: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                WithViewStore(store) { viewStore in
                    ForEach(viewStore.requiredReadAttributes) { attribute in
                        HStack(spacing: 10) {
                            Text("•")
                            Text(attribute.localizedTitle)
                        }
                    }
                }
            }
            Spacer()
        }
        .font(.bundBody)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.blue100, strokeColor: Color.blue400)
        )
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
        .padding(.vertical, 24)
    }
}
