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
        var showProgressCaption: ProgressCaption?
        var showInstructions: Bool = true
        var attempt = 0
        var cardRecognized: Bool = false
    }

    enum Action: Equatable {
        case startScan
        case showNFCInfo
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
    
    var instructionsTitle: String
    var instructionsBody: String
    var instructionsScanButtonTitle: String
    var scanTitle: String
    var scanBody: String
    var scanButton: String
    
    @Namespace var namespace
    @State var animationSyncTime: CMTime = .init(seconds: 0.0, preferredTimescale: 1000)
    
    init(store: Store<SharedScan.State, SharedScan.Action>,
         instructionsTitle: String,
         instructionsBody: String,
         instructionsScanButtonTitle: String,
         scanTitle: String,
         scanBody: String,
         scanButton: String) {
        self.store = store
        self.instructionsTitle = instructionsTitle
        self.instructionsBody = instructionsBody
        self.instructionsScanButtonTitle = instructionsScanButtonTitle
        self.scanTitle = scanTitle
        self.scanBody = scanBody
        self.scanButton = scanButton
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    if viewStore.showInstructions {
                        VStack(alignment: .leading) {
                            ScanBody(title: instructionsTitle,
                                     message: instructionsBody,
                                     primaryButton: nil,
                                     nfcInfoTapped: { viewStore.send(.showNFCInfo) },
                                     helpTapped: { viewStore.send(.showHelp) })
                            
                            scanAnimation(syncedTime: .init(get: { animationSyncTime },
                                                            set: { animationSyncTime = $0 }))
                                .padding([.horizontal, .bottom])
                        }
                        
                    } else {
                        scanAnimation(syncedTime: .init(get: { animationSyncTime },
                                                        set: { _ in }))
                        
                        if viewStore.isScanning {
                            VStack {
                                ProgressView()
                                    .accessibilityIdentifier("ScanProgressView")
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                                    .scaleEffect(3)
                                    .frame(maxWidth: .infinity)
                                    .padding(50)
                                if let progressCaption = viewStore.showProgressCaption {
                                    VStack(spacing: 24) {
                                        Text(progressCaption.title)
                                            .headingL()
                                        Text(progressCaption.body)
                                            .bodyLRegular()
                                    }
                                    .padding(.bottom, 50)
                                }
                            }
                            .transition(AnyTransition.asymmetric(insertion: .opacity.animation(.default.delay(0.5)),
                                                                 removal: .opacity))
                        } else {
                            ScanBody(title: scanTitle,
                                     message: scanBody,
                                     primaryButton: .init(title: scanButton,
                                                          action: { viewStore.send(.startScan) }),
                                     nfcInfoTapped: { viewStore.send(.showNFCInfo) },
                                     helpTapped: { viewStore.send(.showHelp) })
                                .disabled(!viewStore.scanAvailable)
                        }
                    }
                }
                if viewStore.showInstructions {
                    DialogButtons(store: store.stateless,
                                  secondary: nil,
                                  primary: .some(.init(title: scanButton,
                                                       action: .startScan)))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: viewStore.showInstructions)
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
            SharedScanView(store: store,
                           instructionsTitle: "instructionsTitle",
                           instructionsBody: "instructionsBody",
                           instructionsScanButtonTitle: "instructionsScanButtonTitle",
                           scanTitle: "scanTitle",
                           scanBody: "scanBody",
                           scanButton: "scanButton")
        }
    }
}
