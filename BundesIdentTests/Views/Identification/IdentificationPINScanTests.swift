import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationPINScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockEIDInteractionManager: MockEIDInteractionManagerType!
    
    override func setUp() {
        mockAnalyticsClient = MockAnalyticsClient()
        mockEIDInteractionManager = MockEIDInteractionManagerType()
        scheduler = DispatchQueue.test
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }
    
    func testOnAppearDoesNotTriggerScanningWhenInstructionsShown() throws {
        let pin = "123456"
        let store = TestStore(
            initialState: IdentificationPINScan.State(identificationInformation: .preview,
                                                      pin: pin,
                                                      shared: SharedScan.State()),
            reducer: IdentificationPINScan()
        )
        
        store.send(.onAppear)
    }

    func testWrongPIN() throws {
        let pin = "123456"
        let store = TestStore(initialState: IdentificationPINScan.State(identificationInformation: .preview,
                                                                        pin: pin,
                                                                        lastRemainingAttempts: 3,
                                                                        shared: SharedScan.State()),
                              reducer: IdentificationPINScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        stub(mockEIDInteractionManager) {
            $0.interrupt().thenDoNothing()
        }
        
        store.send(.scanEvent(.success(.pinRequested(remainingAttempts: 2)))) {
            $0.lastRemainingAttempts = 2
        }
        
        verify(mockEIDInteractionManager).interrupt()
        
        store.receive(.wrongPIN(remainingAttempts: 2))
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        
        let store = TestStore(initialState: IdentificationPINScan.State(identificationInformation: .preview,
                                                                        pin: pin,
                                                                        shared: SharedScan.State()),
                              reducer: IdentificationPINScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        stub(mockEIDInteractionManager) {
            $0.acceptAccessRights().thenDoNothing()
        }
        
        store.send(.shared(.startScan)) {
            $0.didAcceptAccessRights = true
            $0.shared.startOnAppear = true
        }
        
        verify(mockEIDInteractionManager).acceptAccessRights()
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
