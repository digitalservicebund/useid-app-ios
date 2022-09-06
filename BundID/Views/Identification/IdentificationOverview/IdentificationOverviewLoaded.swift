import ComposableArchitecture
import SwiftUI

let identificationOverviewLoadedReducer = Reducer<IdentificationOverviewLoadedState, IdentificationOverviewLoadedAction, AppEnvironment> { state, action, environment in
    switch action {
    case .idInteractionEvent(.success(.requestPIN(remainingAttempts: nil, pinCallback: let handler))):
        return Effect(value: .callbackReceived(state.request, PINCallback(id: environment.uuidFactory(), callback: handler)))
    case .idInteractionEvent(.failure(let error)):
        return Effect(value: .failure(IdentifiableError(error)))
    case .idInteractionEvent:
        return .none
    case .done:
        var dict: [IDCardAttribute: Bool] = [:]
        for attribute in state.requiredReadAttributes {
            dict[attribute] = true
        }
        state.handler(dict)
        return .none
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
                        HeaderView(title: L10n.Identification.Overview.Loaded.title(viewStore.request.subject),
                                   message: L10n.Identification.Overview.Loaded.body(viewStore.request.subject))
                        
                        attributesBox
                        
                        NavigationLink.init(L10n.Identification.Overview.Loaded.moreInfo) {
                            IdentificationAbout(request: viewStore.request)
                        }
                        .buttonStyle(BundTextButtonStyle())
                        .padding([.horizontal, .bottom])
                    }
                }
                DialogButtons(store: store.stateless,
                              primary: .init(title: L10n.Identification.Overview.Loaded.continue, action: .done))
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
        .padding(.bottom, 24)
    }
}
