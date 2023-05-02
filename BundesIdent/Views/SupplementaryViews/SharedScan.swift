import SwiftUI
import ComposableArchitecture
import AVKit

struct ProgressCaption: Equatable {
    var title: String
    var body: String
}

struct SharedScan: ReducerProtocol {
    @Dependency(\.context) var context
    struct State: Equatable {
        var scanAvailable = true
        var startOnAppear = false
        var attempt = 0
        var cardRecognized = false
        // TODO: Wait for AA2 fix or delete this TODO for release
        var preventSecondScanningAttempt = false
        var forceDismissButtonTitle: String = L10n.FirstTimeUser.ConfirmEnd.confirm
    }

    enum Action: Equatable {
        case startScan
        case initiateScan
        case showHelp
        case forceDismiss
    }
    
    var body: some ReducerProtocol<State, Action> {
        if context == .preview {
            Reduce(preview())
        }
    }
    
    func preview() -> some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .startScan:
                state.startOnAppear.toggle()
                state.preventSecondScanningAttempt.toggle()
                return .none
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
                DialogButtons(store: store.stateless,
                              primary: viewStore.preventSecondScanningAttempt
                              ? .init(title: viewStore.forceDismissButtonTitle, action: .forceDismiss)
                              : .init(title: L10n.Scan.button, action: .startScan))
            }
            .onChange(of: viewStore.state.attempt, perform: { _ in
                viewStore.send(.startScan, animation: .easeInOut)
            })
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

    static var store = Store<SharedScan.State, SharedScan.Action>(initialState: .init(forceDismissButtonTitle: "End flow"),
                                                                  reducer: SharedScan())

    static var previews: some View {
        NavigationView {
            SharedScanView(store: store)
        }
    }
}
