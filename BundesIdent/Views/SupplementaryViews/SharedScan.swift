import SwiftUI
import ComposableArchitecture
import AVKit

struct ProgressCaption: Equatable {
    var title: String
    var body: String
}

struct SharedScan: ReducerProtocol {

    struct State: Equatable {
        var scanAvailable = true
        var startOnAppear = false
        var attempt = 0
    }

    enum Action: Equatable {
        case onAppear
        case onButtonTap
        case onAttemptChange

        case startScan(userInitiated: Bool)
        case showHelp
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear where state.startOnAppear,
                 .onAttemptChange:
                return EffectTask(value: .startScan(userInitiated: false))
            case .onButtonTap:
                if !state.startOnAppear {
                    state.startOnAppear = true
                }
                return EffectTask(value: .startScan(userInitiated: true))
            default:
                return .none
            }
        }
    }
}

struct SharedScanView: View {
    
    var store: Store<SharedScan.State, SharedScan.Action>

    @Namespace var namespace
    @State var animationSyncTime: CMTime = .init(seconds: 0.0, preferredTimescale: 1000)
    
    init(store: Store<SharedScan.State, SharedScan.Action>) {
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    scanAnimation(syncedTime: .init(get: { animationSyncTime }, set: { _ in }))

                    ScanBody(helpTapped: { viewStore.send(.showHelp) })
                }
                DialogButtons(store: store.stateless, primary: .init(title: L10n.Scan.button, action: .onButtonTap))
            }
            .onChange(of: viewStore.state.attempt, perform: { _ in
                viewStore.send(.onAttemptChange, animation: .easeInOut)
            })
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
    
    func scanAnimation(syncedTime: Binding<CMTime>) -> some View {
        LoopingPlayer(fileURL: Bundle.main.url(forResource: "animation_id-scan_800X544",
                                               withExtension: "mp4")!,
                      syncedTime: syncedTime)
            .aspectRatio(540.0 / 367.0, contentMode: .fit)
            .matchedGeometryEffect(id: "scanAnimation", in: namespace)
            .accessibilityLabel(L10n.Scan.animationAccessibilityLabel)
    }
}

struct SharedScan_Previews: PreviewProvider {

    static var store: Store<SharedScan.State, SharedScan.Action> = Store(initialState: SharedScan.State(),
                                                                         reducer: SharedScan())

    static var previews: some View {
        NavigationView {
            SharedScanView(store: store)
        }
    }
}
