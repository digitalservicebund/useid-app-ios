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
                                                      shared: SharedScan.State()),
            reducer: IdentificationPINScan()
        )
        
        store.send(.onAppear)
    }

    func testWrongPIN() throws {
        let pin = "123456"
        let store = TestStore(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                        pin: pin,
                                                                        lastRemainingAttempts: 3,
                                                                        shared: SharedScan.State()),
                              reducer: IdentificationPINScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        stub(mockIDInteractionManager) {
            $0.interrupt().thenDoNothing()
        }
        
        store.send(.scanEvent(.success(.pinRequested(remainingAttempts: 2)))) {
            $0.lastRemainingAttempts = 2
        }
        
        verify(mockIDInteractionManager).interrupt()
        
        store.receive(.wrongPIN(remainingAttempts: 2))
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        
        let store = TestStore(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                        pin: pin,
                                                                        shared: SharedScan.State()),
                              reducer: IdentificationPINScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.idInteractionManager = mockIDInteractionManager
        stub(mockIDInteractionManager) {
            $0.acceptAccessRights().thenDoNothing()
        }
        
        store.send(.shared(.startScan)) {
            $0.didAcceptAccessRights = true
            $0.shared.startOnAppear = true
        }
        
        verify(mockIDInteractionManager).acceptAccessRights()
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
