import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationCANScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    var uuidCount = 0
    var mockAnalyticsClient: MockAnalyticsClient!
    
    var mockIDInteractionManager = MockIDInteractionManagerType()
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        mockAnalyticsClient = MockAnalyticsClient()
        scheduler = DispatchQueue.test
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(),
                                            uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager,
                                            analytics: mockAnalyticsClient)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }
    
    func testOnAppearDoesTriggerScanningWhenNotAlreadyScanning() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(
            initialState: IdentificationCANScanState(request: request,
                                                  pin: pin,
                                                  can: can,
                                                     pinCANCallback: pinCANCallback,
                                                  shared: SharedScanState(isScanning: false, showInstructions: false)),
            reducer: identificationCANScanReducer,
            environment: environment
        )
        
        store.send(.onAppear)
        store.receive(.shared(.startScan)) {
            $0.shared.isScanning = true
        }
    }
    
    func testOnAppearIgnoredWhenAlreadyScanning() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScanState(request: request,
                                                                       pin: pin,
                                                                       can: can,
                                                                       pinCANCallback: pinCANCallback,
                                                                       shared: SharedScanState(isScanning: true, showInstructions: false)),
                              reducer: identificationCANScanReducer,
                              environment: environment)
        
        store.send(.onAppear)
    }
    
    func testCancellation() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScanState(request: request,
                                                                       pin: pin,
                                                                       can: can,
                                                                       pinCANCallback: pinCANCallback,
                                                                       shared: SharedScanState(isScanning: true, showInstructions: false)),
                              reducer: identificationCANScanReducer,
                              environment: environment)
        
        let newCallback = { (_: String, _: String) in }
        store.send(.scanEvent(.success(.requestPINAndCAN(newCallback)))) {
            $0.shared.isScanning = false
            $0.pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: newCallback)
        }
    }
    
    func testWrongCAN() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScanState(request: request,
                                                                       pin: pin,
                                                                       can: can,
                                                                       pinCANCallback: pinCANCallback,
                                                                       shared: SharedScanState(isScanning: true, showInstructions: false)),
                              reducer: identificationCANScanReducer,
                              environment: environment)
        
        let newCallback = { (_: String, _: String) in }
        store.send(.scanEvent(.success(.requestPINAndCAN(newCallback)))) {
            $0.shared.isScanning = false
            $0.pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: newCallback)
        }
    }
    
    func testShowNFCInfo() {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScanState(request: request,
                                                                       pin: pin,
                                                                       can: can,
                                                                       pinCANCallback: pinCANCallback,
                                                                       shared: SharedScanState(isScanning: false, showInstructions: false)),
                              reducer: identificationCANScanReducer,
                              environment: environment)
        
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
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScanState(request: request,
                                                                       pin: pin,
                                                                       can: can,
                                                                       pinCANCallback: pinCANCallback,
                                                                       shared: SharedScanState(isScanning: false, showInstructions: false)),
                              reducer: identificationCANScanReducer,
                              environment: environment)
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "canScan"))
    }
}
