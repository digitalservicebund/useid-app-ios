import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationCANScanTests: XCTestCase {
    
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
        
        stub(mockIDInteractionManager) {
            $0.interrupt().thenDoNothing()
            $0.setCAN(any()).thenDoNothing()
        }
    }
    
    override func tearDown() {
        verifyNoMoreInteractions(mockIDInteractionManager)
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
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.onAppear)
        store.receive(.shared(.startScan))
        
        verify(mockIDInteractionManager).setCAN(can)
    }
    
    func testWrongCAN() throws {
        let pin = "123456"
        let can = "123456"
    
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(startOnAppear: true)),
                              reducer: IdentificationCANScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(.scanEvent(.success(.canRequested)))
        
        verify(mockIDInteractionManager).interrupt()
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        let can = "123456"
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(startOnAppear: true)),
                              reducer: IdentificationCANScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(.shared(.startScan)) {
            $0.shared.startOnAppear = true
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "canScan"))
        
        verify(mockIDInteractionManager).setCAN(can)
    }
}
