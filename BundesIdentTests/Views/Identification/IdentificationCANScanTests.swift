import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationCANScanTests: XCTestCase {
    
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
        
        stub(mockEIDInteractionManager) {
            $0.interrupt().thenDoNothing()
            $0.setCAN(any()).thenDoNothing()
        }
    }
    
    override func tearDown() {
        verifyNoMoreInteractions(mockEIDInteractionManager)
    }
    
    func testOnAppearDoesTriggerScanningWhenNotAlreadyScanning() throws {
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(
            initialState: IdentificationCANScan.State(pin: pin,
                                                      can: can,
                                                      shared: SharedScan.State(startOnAppear: true)),
            reducer: IdentificationCANScan()
        )
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.onAppear)
        store.receive(.shared(.startScan)) {
            $0.shared.preventSecondScanningAttempt = true
        }
        
        verify(mockEIDInteractionManager).setCAN(can)
    }
    
    func testWrongCAN() throws {
        let pin = "123456"
        let can = "123456"
    
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(startOnAppear: true)),
                              reducer: IdentificationCANScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.send(.scanEvent(.success(.canRequested)))
        
        verify(mockEIDInteractionManager).interrupt()
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        let can = "123456"
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State()),
                              reducer: IdentificationCANScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.send(.shared(.startScan)) {
            $0.shared.preventSecondScanningAttempt = true
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "canScan"))
        
        verify(mockEIDInteractionManager).setCAN(can)
    }
}
