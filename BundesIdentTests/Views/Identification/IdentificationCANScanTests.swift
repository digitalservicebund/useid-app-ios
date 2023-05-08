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
        let can = "123456"
        let store = TestStore(
            initialState: IdentificationCANScan.State(pin: "123456",
                                                      can: can,
                                                      identificationInformation: .preview,
                                                      shared: SharedScan.State(startOnAppear: true)),
            reducer: IdentificationCANScan()
        )
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.shared(.onAppear))
        store.receive(.shared(.startScan(userInitiated: false))) {
            $0.shared.scanAvailable = false
        }
        
        verify(mockEIDInteractionManager).setCAN(can)
    }
    
    func testWrongCAN() throws {
        let pin = "123456"
        let can = "123456"
    
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        identificationInformation: .preview,
                                                                        shared: SharedScan.State(startOnAppear: true)),
                              reducer: IdentificationCANScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.send(.scanEvent(.success(.canRequested)))
        store.receive(.wrongCAN)
        
        verify(mockEIDInteractionManager).interrupt()
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        let can = "123456"
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        identificationInformation: .preview,
                                                                        shared: SharedScan.State()),
                              reducer: IdentificationCANScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.send(.shared(.startScan(userInitiated: true))) {
            $0.shared.scanAvailable = false
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "canScan"))
        
        verify(mockEIDInteractionManager).setCAN(can)
    }
}
