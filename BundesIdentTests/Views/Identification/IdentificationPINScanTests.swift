import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationPINScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockIDInteractionManager: MockIDInteractionManagerType!
    
    override func setUp() {
        mockAnalyticsClient = MockAnalyticsClient()
        mockIDInteractionManager = MockIDInteractionManagerType()
        scheduler = DispatchQueue.test
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }
    
    func testOnAppearDoesNotTriggerScanningWhenInstructionsShown() throws {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
        }
        let store = TestStore(
            initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                      pin: pin,
                                                      shared: SharedScan.State(isScanning: false, showInstructions: true)),
            reducer: IdentificationPINScan()
        )
        
        store.send(.onAppear)
    }
    
    func testOnAppearIgnoredWhenAlreadyScanning() throws {
        let pin = "123456"
        let store = TestStore(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                        pin: pin,
                                                                        shared: SharedScan.State(isScanning: true)),
                              reducer: IdentificationPINScan())
        
        store.send(.onAppear)
    }
    
    func testWrongPIN() throws {
        let pin = "123456"
        let store = TestStore(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                        pin: pin,
                                                                        lastRemainingAttempts: 3,
                                                                        shared: SharedScan.State(isScanning: true)),
                              reducer: IdentificationPINScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        stub(mockIDInteractionManager) {
            $0.interrupt().thenDoNothing()
        }
        
        store.send(.scanEvent(.success(.pinRequested(remainingAttempts: 2)))) {
            $0.shared.isScanning = false
            $0.lastRemainingAttempts = 2
        }
        
        verify(mockIDInteractionManager).interrupt()
        
        store.receive(.wrongPIN(remainingAttempts: 2))
    }
    
    func testShowNFCInfo() {
        let pin = "123456"
        
        let store = TestStore(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                        pin: pin,
                                                                        shared: SharedScan.State(isScanning: false)),
                              reducer: IdentificationPINScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.shared(.showNFCInfo)) {
            $0.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                  message: TextState(L10n.HelpNFC.body),
                                  dismissButton: .cancel(TextState(L10n.General.ok),
                                                         action: .send(.dismissAlert)))
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "alertShown",
                                                                name: "NFCInfo"))
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        
        let store = TestStore(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                        pin: pin,
                                                                        shared: SharedScan.State(isScanning: false)),
                              reducer: IdentificationPINScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.idInteractionManager = mockIDInteractionManager
        stub(mockIDInteractionManager) {
            $0.acceptAccessRights().thenDoNothing()
        }
        
        store.send(.shared(.startScan)) {
            $0.didAcceptAccessRights = true
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        verify(mockIDInteractionManager).acceptAccessRights()
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
