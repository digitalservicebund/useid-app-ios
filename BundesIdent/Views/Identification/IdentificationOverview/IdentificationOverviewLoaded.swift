import ComposableArchitecture
import SwiftUI

struct IdentificationOverviewLoaded: ReducerProtocol {

    struct State: Identifiable, Equatable {
        let id: UUID
        let identificationInformation: IdentificationInformation
        let canGoBackToSetupIntro: Bool

        init(id: UUID, identificationInformation: IdentificationInformation, canGoBackToSetupIntro: Bool = false) {
            self.id = id
            self.identificationInformation = identificationInformation
            self.canGoBackToSetupIntro = canGoBackToSetupIntro
        }
        
        var requiredReadAttributes: IdentifiedArrayOf<EIDAttribute> {
            IdentifiedArrayOf(uniqueElements: identificationInformation.request.requiredAttributes)
        }
    }
    
    enum Action: Equatable {
        case moreInfo
        case confirm(IdentificationInformation)
        case failure(IdentifiableError)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .confirm:
            return .none
        case .failure:
            return .none
        case .moreInfo:
            return .none
        }
    }
}

struct IdentificationOverviewLoadedView: View {
    var store: Store<IdentificationOverviewLoaded.State, IdentificationOverviewLoaded.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HeaderView(title: L10n.Identification.AttributeConsent.title(viewStore.identificationInformation.certificateDescription.subjectName),
                                   message: L10n.Identification.AttributeConsent.body)
                            .padding(.horizontal)
                        
                        attributesBox
                        
                        NavigationLink(L10n.Identification.AttributeConsent.moreInfo) {
                            IdentificationAbout(request: viewStore.identificationInformation.certificateDescription)
                        }
                        .buttonStyle(BundTextButtonStyle())
                        .padding([.horizontal, .bottom])
                    }
                }
                DialogButtons(store: store.stateless,
                              primary: .init(title: L10n.Identification.AttributeConsent.continue, action: .confirm(viewStore.identificationInformation)))
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
                                .accessibilityHidden(true)
                            Text(attribute.localizedTitle)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            Spacer()
        }
        .bodyLRegular()
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
