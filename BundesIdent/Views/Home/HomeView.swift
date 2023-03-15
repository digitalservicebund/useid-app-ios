import SwiftUI
import Combine
import ComposableArchitecture
import Analytics
import MarkdownUI

struct Home: ReducerProtocol {
#if PREVIEW
    @Dependency(\.previewIDInteractionManager) var previewIDInteractionManager
#endif
    
    struct State: Equatable {
        var appVersion: String
        var buildNumber: Int
        
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
                    for await value in previewIDInteractionManager.publishedIsDebugModeEnabled.values {
                        await send(.updateDebugModeEnabled(value))
                    }
                }
#else
                return .none
#endif
#if PREVIEW
            case .setDebugModeEnabled(let enabled):
#if targetEnvironment(simulator)
                previewIDInteractionManager.isDebugModeEnabled = false
#else
                previewIDInteractionManager.isDebugModeEnabled = enabled
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
                    overscrollBackground
                    
                    headerView
                        .padding(.bottom, 24)
                    
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
            .ignoresSafeArea(.container, edges: .top)
            .task {
                await ViewStore(store.stateless).send(.task).finish()
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 0) {
            Image(asset: Asset.homeIcon)
                .padding(24)
            Text(L10n.Home.Header.title)
                .bodyLBold(color: .blue800)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 8)
                .padding(.horizontal, 36)
#if PREVIEW
                .onTapGesture {
                    ViewStore(store.stateless).send(.triggerIdentification(tokenURL: demoTokenURL))
                }
#endif
            Text(L10n.Home.Header.infoText)
                .font(.bundCustom(size: 20, relativeTo: .body))
                .foregroundColor(.blackish)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            Text(L10n.Home.Header.infoCTA)
                .headingM()
                .padding(.bottom, 10)
            
            ImageMeta(asset: Asset.abstractWidget).image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal)
                .padding(.bottom, 36)
        }
        .padding(EdgeInsets(top: 60, leading: 24, bottom: 20, trailing: 24))
        .background(LinearGradient(colors: [.blue100, .blue200], startPoint: .top, endPoint: .bottom))
    }
    
#if PREVIEW
    @ViewBuilder
    private var previewView: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        .padding()
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
            Button(L10n.Home.Setup.setup) {
                ViewStore(store.stateless).send(.triggerSetup)
            }
            .buttonStyle(BundTextButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
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
    private var overscrollBackground: some View {
        let height = 1000.0
        Color.blue100
            .frame(height: height)
            .offset(y: -height)
            .padding(.bottom, -height)
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
                                                       isDebugModeEnabled: false),
                              reducer: Home()))
#else
        HomeView(store: Store(initialState: Home.State(appVersion: "1.2.3",
                                                       buildNumber: 42),
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
