import SwiftUI
import Combine
import ComposableArchitecture
import Analytics
import MarkdownUI

struct Home: ReducerProtocol {
#if PREVIEW
    @Dependency(\.previewEIDInteractionManager) var previewEIDInteractionManager
#endif
    
    struct State: Equatable {
        var appVersion: String
        var buildNumber: Int
        var shouldShowVariation: Bool = false
        
#if PREVIEW
        var isDebugModeEnabled: Bool = false
#endif
        
        var versionInfo: String {
            let appVersion = "\(appVersion) - \(buildNumber)"
#if PREVIEW
            return "\(appVersion) (PREVIEW)"
#else
            return appVersion
#endif
        }
    }
    
    enum Action: Equatable {
        case task
        case triggerSetup
        case triggerIdentificationInfo
#if PREVIEW
        case triggerIdentification(tokenURL: URL)
        case setDebugModeEnabled(Bool)
        case updateDebugModeEnabled(Bool)
#endif
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .task:
#if PREVIEW
                return .run { send in
                    for await value in previewEIDInteractionManager.publishedIsDebugModeEnabled.values {
                        await send(.updateDebugModeEnabled(value))
                    }
                }
#else
                return .none
#endif
#if PREVIEW
            case .setDebugModeEnabled(let enabled):
#if targetEnvironment(simulator)
                previewEIDInteractionManager.isDebugModeEnabled = false
#else
                previewEIDInteractionManager.isDebugModeEnabled = enabled
#endif
                return .none
            case .updateDebugModeEnabled(let enabled):
                state.isDebugModeEnabled = enabled
                return .none
#endif
            default:
                return .none
            }
        }
    }
}

extension Home.State: AnalyticsView {
    var route: [String] {
        []
    }
}

struct HomeView: View {
    let store: Store<Home.State, Home.Action>
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    VStack(alignment: .leading, spacing: 16) {
#if PREVIEW
                        previewView
#endif
                        setupActionView
                        listView
                        Spacer(minLength: 0)
                        versionView
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
            .task {
                await ViewStore(store.stateless).send(.task).finish()
            }
        }
    }
    
#if PREVIEW
    @ViewBuilder
    private var previewView: some View {
        VStack(alignment: .leading, spacing: 4) {
            WithViewStore(store) { viewStore in
                Toggle("Simulator Mode", isOn: viewStore.binding(get: \.isDebugModeEnabled, send: Home.Action.setDebugModeEnabled))
                    .bodyLRegular(color: viewStore.isDebugModeEnabled ? .red : nil)
#if targetEnvironment(simulator)
                    .disabled(true)
#endif
                Text("If enabled, all interaction with the eID card and the server is simulated. Use the \(Image(systemName: "wrench")) to simulate the steps.")
                    .captionM(color: .secondary)
            }
        }
        .padding(24)
        .grouped()
    }
#endif
    
    @ViewBuilder
    private var setupActionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Home.Setup.title)
                    .headingM()
                Text(L10n.Home.Setup.body)
                    .bodyMRegular()
            }
            WithViewStore(store) { viewStore in
                Button(viewStore.state.shouldShowVariation ? L10n.Home.Setup.setupVariation : L10n.Home.Setup.setup) {
                    viewStore.send(.triggerSetup)
                }
                .buttonStyle(BundTextButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .grouped()
    }
    
    @ViewBuilder
    private var listView: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink {
                    AboutView(title: L10n.Privacy.title,
                              markdown: L10n.Privacy.text)
                } label: {
                    Text(L10n.Home.More.privacy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                listDivider
                NavigationLink {
                    LicensesView()
                        .navigationTitle(L10n.Home.More.licenses)
                        .ignoresSafeArea()
                } label: {
                    Text(L10n.Home.More.licenses)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                listDivider
                NavigationLink {
                    // Use NSLocalizedString here, as SwiftGen has problems with the single % sign we have in that text.
                    AboutView(title: L10n.Accessibility.title,
                              markdown: NSLocalizedString("accessibility_text", comment: ""))
                } label: {
                    Text(L10n.Home.More.accessibilityStatement)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                listDivider
                NavigationLink {
                    AboutView(title: L10n.TermsOfUse.title,
                              markdown: L10n.TermsOfUse.text)
                } label: {
                    Text(L10n.Home.More.terms)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                listDivider
                
                NavigationLink {
                    AboutView(title: L10n.Imprint.title,
                              markdown: L10n.Imprint.text)
                } label: {
                    Text(L10n.Home.More.imprint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
            .padding(24)
        }
        .buttonStyle(.plain)
        .bodyLRegular()
        .grouped()
    }
    
    @ViewBuilder
    private var listDivider: some View {
        Divider()
            .foregroundColor(.neutral300)
            .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var versionView: some View {
        WithViewStore(store, observe: \.versionInfo) { viewStore in
            HStack {
                Spacer()
                Text(L10n.Home.version(viewStore.state))
                    .captionL(color: .neutral900)
                    .padding(.bottom)
                Spacer()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
#if PREVIEW
        HomeView(store: Store(initialState: Home.State(appVersion: "1.2.3",
                                                       buildNumber: 42,
                                                       shouldShowVariation: true,
                                                       isDebugModeEnabled: false),
                              reducer: Home()))
#else
        HomeView(store: Store(initialState: Home.State(appVersion: "1.2.3",
                                                       buildNumber: 42,
                                                       shouldShowVariation: true),
                              reducer: Home()))
#endif
    }
}

private struct Grouped: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.04), radius: 32, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.neutral300, lineWidth: 1)
            )
    }
}

private extension View {
    func grouped() -> some View {
        modifier(Grouped())
    }
}
