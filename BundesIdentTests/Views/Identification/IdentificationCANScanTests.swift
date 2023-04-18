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
        let newCallback = { (_: String, _: String) in }
        store.send(.scanEvent(.success(.canRequested))) {
            $0.shared.isScanning = false
        }
    }
    
    func testShowNFCInfo() {
        let pin = "123456"
        let can = "123456"
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(isScanning: false, showInstructions: false)),
                              reducer: IdentificationCANScan())
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
        let can = "123456"
        let store = TestStore(initialState: IdentificationCANScan.State(pin: pin,
                                                                        can: can,
                                                                        shared: SharedScan.State(isScanning: false, showInstructions: false)),
                              reducer: IdentificationCANScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "canScan"))
    }
}
