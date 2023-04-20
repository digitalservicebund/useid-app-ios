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
                                                      shared: SharedScan.State(isScanning: false, showInstructions: false)),
            reducer: IdentificationCANScan()
        )
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.onAppear)
        store.receive(.shared(.startScan)) {
            $0.shared.isScanning = true
        }
        
        verify(mockIDInteractionManager).setCAN(can)
    }
    
    func testOnAppearIgnoredWhenAlreadyScanning() throws {
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(isScanning: true, showInstructions: false)),
                              reducer: IdentificationCANScan())
        
        store.send(.onAppear)
    }
    
    func testWrongCAN() throws {
        let pin = "123456"
        let can = "123456"
    
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(isScanning: true, showInstructions: false)),
                              reducer: IdentificationCANScan())
        store.dependencies.uuid = .incrementing
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(.scanEvent(.success(.canRequested))) {
            $0.shared.isScanning = false
        }
        
        verify(mockIDInteractionManager).interrupt()
    }
    
    func testStartScanTracking() {
        let pin = "123456"
        let can = "123456"
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(isScanning: false, showInstructions: false)),
                              reducer: IdentificationCANScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "canScan"))
        
        verify(mockIDInteractionManager).setCAN(can)
    }
}
