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
        var isScanning: Bool = false
        var scanAvailable: Bool = true
        var showInstructions: Bool = true
        var attempt = 0
        var cardRecognized: Bool = false
    }

    enum Action: Equatable {
        case startScan
        case initiateScan
        case showHelp
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
                state.showInstructions.toggle()
                state.isScanning.toggle()
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
                DialogButtons(store: store.stateless, primary: .init(title: L10n.Scan.button, action: .startScan))
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

    static var store: Store<SharedScan.State, SharedScan.Action> = Store(initialState: SharedScan.State(),
                                                                         reducer: SharedScan())

    static var previews: some View {
        NavigationView {
            SharedScanView(store: store)
        }
    }
}
