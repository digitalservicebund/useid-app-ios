import SwiftUI
import ComposableArchitecture
import Analytics

struct Home: ReducerProtocol {
    struct State: Equatable {
        var appVersion: String
        var buildNumber: Int
        
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
        case triggerSetup
#if PREVIEW
        case triggerIdentification(tokenURL: URL)
#endif
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
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
                        .padding(.bottom)
                        .background(Color.blue200)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text(L10n.Home.More.title)
                                .headingXL()
                                .padding(.top)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                        }
                        setupActionView
                        listView
                        Spacer(minLength: 0)
                        WithViewStore(store) { viewStore in
                            Text(L10n.Home.version(viewStore.state.versionInfo))
                                .captionL(color: .neutral900)
                                .padding(.bottom)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .top)
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 0) {
            ImageMeta(asset: Asset.abstractWidget).image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(EdgeInsets(top: 60, leading: 24, bottom: 20, trailing: 24))
            
            Text(L10n.Home.Header.title)
                .headingXL()
                .padding(.bottom, 8)
                .padding(.horizontal, 36)
#if PREVIEW
                .onTapGesture {
                    ViewStore(store.stateless).send(.triggerIdentification(tokenURL: demoTokenURL))
                }
#endif
            Text(L10n.Home.Header.infoText)
                .font(.bundCustom(size: 20, relativeTo: .body))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private var setupActionView: some View {
        VStack {
            ImageMeta(asset: Asset.setupPINLetterEId).image
                .resizable()
                .aspectRatio(contentMode: .fit)
            Button(L10n.Home.startSetup) {
                ViewStore(store.stateless).send(.triggerSetup)
            }
            .buttonStyle(BundButtonStyle(isPrimary: true))
            .offset(y: -60)
            .padding(.bottom, -40)
            .padding(.horizontal)
        }
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
        Color.blue200
            .frame(height: height)
            .offset(y: -height)
            .padding(.bottom, -height)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(store: Store(initialState: Home.State(appVersion: "1.2.3",
                                                      buildNumber: 42),
                              reducer: Home()))
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
