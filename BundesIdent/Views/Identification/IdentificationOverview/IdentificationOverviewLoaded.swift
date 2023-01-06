import ComposableArchitecture
import FaviconFinder
import IdentifiedCollections
import MarkdownUI
import SwiftUI

struct TransactionInfo: Codable, Equatable {
    var providerName: String
    var providerURL: URL
    var additionalInfo: IdentifiedArrayOf<AdditionalInfo>
    
    struct AdditionalInfo: Codable, Identifiable, Equatable {
        var key: String
        var value: String
        
        var id: String { key }
    }
    
#if PREVIEW
    static var preview: TransactionInfo = .init(
        providerName: "Sparkasse",
        providerURL: URL(string: "https://sparkasse.de")!,
        additionalInfo: [
            AdditionalInfo(key: "Kundennummer", value: "345978121"),
            AdditionalInfo(key: "Name", value: "Max Mustermann")
        ]
    )
#endif
}

struct IdentificationOverviewLoaded: ReducerProtocol {
    @Dependency(\.uuid) var uuid
    struct State: Identifiable, Equatable {
        let id: UUID
        let request: EIDAuthenticationRequest
        var transactionInfo: TransactionInfo
        var handler: IdentifiableCallback<FlaggedAttributes>
        let canGoBackToSetupIntro: Bool
        
        // used when going back to the overview screen when we already received a pin handler
        var pinHandler: PINCallback?
        
        var faviconURL: URL?
        
        init(id: UUID, request: EIDAuthenticationRequest, transactionInfo: TransactionInfo, handler: IdentifiableCallback<FlaggedAttributes>, canGoBackToSetupIntro: Bool = false, pinHandler: PINCallback? = nil) {
            self.id = id
            self.request = request
            self.transactionInfo = transactionInfo
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
    
    enum Action: Equatable {
        case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
        case moreInfo
        case callbackReceived(EIDAuthenticationRequest, PINCallback)
        case confirm
        case failure(IdentifiableError)
        case onInitialAppear
        case retrievedFaviconURL(TaskResult<URL>)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .idInteractionEvent(.success(.requestPIN(remainingAttempts: nil, pinCallback: let handler))):
            let pinHandler = PINCallback(id: uuid.callAsFunction(), callback: handler)
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
        case .onInitialAppear:
            return .task { [providerURL = state.transactionInfo.providerURL] in
                await .retrievedFaviconURL(TaskResult {
                    let favIcon = try await FaviconFinder(url: providerURL, downloadImage: false).downloadFavicon()
                    return favIcon.url
                })
            }
        case .retrievedFaviconURL(.success(let faviconURL)):
            state.faviconURL = faviconURL
            return .none
        case .retrievedFaviconURL(.failure):
            // TODO: No favicon, what should we do?
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
                        VStack(alignment: .leading, spacing: 24) {
                            Text(L10n.Identification.AttributeConsent.title(viewStore.transactionInfo.providerName))
                                .headingXL()

                            HStack {
                                VStack(alignment: .leading) {
                                    HStack(alignment: .center, spacing: 8) {
                                        AsyncImage(url: viewStore.faviconURL) { image in
                                            image
                                                .resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 24, height: 24)
                                        
                                        Button {} label: {
                                            Text(viewStore.transactionInfo.providerName)
                                                .underline()
                                                .bodyLRegular()
                                        }
                                    }
                                    ForEach(viewStore.transactionInfo.additionalInfo) { info in
                                        HStack {
                                            Text(L10n.Identification.AttributeConsent.AdditionalInformation.key(info.key))
                                                .bodyMBold()
                                            Text(L10n.Identification.AttributeConsent.AdditionalInformation.value(info.value))
                                                .bodyMRegular()
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.neutral100)
                            .foregroundColor(Color.blackish)
                            .cornerRadius(10)
                            
                            Markdown(L10n.Identification.AttributeConsent.body)
                                .markdownStyle(MarkdownStyle(font: .bundBody))
                                .foregroundColor(.blackish)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)
                        
                        attributesBox
                        
                        NavigationLink(L10n.Identification.AttributeConsent.moreInfo) {
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
            .onInitialAppear {
                viewStore.send(.onInitialAppear)
            }
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

struct IdentificationOverviewLoaded_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverviewLoadedView(
            store: .init(initialState: .init(id: UUID(),
                                             request: EIDAuthenticationRequest.preview,
                                             transactionInfo: .preview,
                                             handler: IdentifiableCallback(id: UUID(),
                                                                           callback: { _ in })),
                         reducer: EmptyReducer())
        )
    }
}
