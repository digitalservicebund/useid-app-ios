import SwiftUI
import ComposableArchitecture
import AVKit

struct ProgressCaption: Equatable {
    var title: String
    var body: String
}

struct SharedScanState: Equatable {
    var isScanning: Bool = false
    var scanAvailable: Bool = true
    var showProgressCaption: ProgressCaption?
    var showInstructions: Bool = true
    var attempt = 0
}

enum SharedScanAction: Equatable {
    case startScan
    case showNFCInfo
    case showHelp
}

struct SharedScan: View {
    
    var store: Store<SharedScanState, SharedScanAction>
    
    var instructionsTitle: String
    var instructionsBody: String
    var instructionsScanButtonTitle: String
    var scanTitle: String
    var scanBody: String
    var scanButton: String
    
    @Namespace var namespace
    @State var animationSyncTime: CMTime = CMTime(seconds: 0.0, preferredTimescale: 1000)
    
    init(store: Store<SharedScanState, SharedScanAction>,
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
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                                    .scaleEffect(3)
                                    .frame(maxWidth: .infinity)
                                    .padding(50)
                                if let progressCaption = viewStore.showProgressCaption {
                                    VStack(spacing: 24) {
                                        Text(progressCaption.title)
                                            .font(.bundTitle)
                                            .foregroundColor(.blackish)
                                        Text(progressCaption.body)
                                            .font(.bundBody)
                                            .foregroundColor(.blackish)
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
        LoopingPlayer(fileURL: Bundle.main.url(forResource: "scanAnimation",
                                               withExtension: "mp4")!,
                      syncedTime: syncedTime)
        .aspectRatio(540.0 / 367.0, contentMode: .fit)
        .matchedGeometryEffect(id: "scanAnimation", in: namespace)
    }
}

struct SharedScan_Previews: PreviewProvider {
    
    static var store: Store<SharedScanState, SharedScanAction> = Store(initialState: SharedScanState(),
                                                                       reducer: previewReducer,
                                                                       environment: AppEnvironment.preview)
    
    static var previewReducer = Reducer<SharedScanState, SharedScanAction, AppEnvironment> { state, action, _ in
        switch action {
        case .startScan:
            state.showInstructions.toggle()
            state.isScanning.toggle()
            return .none
        default:
            return .none
        }
    }
    
    static var previews: some View {
        NavigationView {
            SharedScan(store: store,
                       instructionsTitle: "instructionsTitle",
                       instructionsBody: "instructionsBody",
                       instructionsScanButtonTitle: "instructionsScanButtonTitle",
                       scanTitle: "scanTitle",
                       scanBody: "scanBody",
                       scanButton: "scanButton")
        }
    }
}
