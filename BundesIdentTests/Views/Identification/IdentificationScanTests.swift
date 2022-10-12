import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationScanTests: XCTestCase {
    
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
    
    func testOnAppearDoesNotTriggerScanning() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
            
        }
        let store = TestStore(
            initialState: IdentificationScanState(request: request,
                                                  pin: pin,
                                                  pinCallback: pinCallback,
                                                  shared: SharedScanState(isScanning: false)),
            reducer: identificationScanReducer,
            environment: environment
        )
        
        store.send(.onAppear)
    }
    
    func testOnAppearIgnoredWhenAlreadyScanning() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
            
        }
        let store = TestStore(initialState: IdentificationScanState(request: request,
                                                                    pin: pin,
                                                                    pinCallback: pinCallback,
                                                                    shared: SharedScanState(isScanning: true)),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        store.send(.onAppear)
    }
    
    func testCancellation() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { _ in }
        
        let store = TestStore(initialState: IdentificationScanState(request: request,
                                                                    pin: pin,
                                                                    pinCallback: pinCallback,
                                                                    shared: SharedScanState(isScanning: true)),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        let newCallback = { (_: String) in }
        store.send(.scanEvent(.success(.requestPIN(remainingAttempts: nil, pinCallback: newCallback)))) {
            $0.shared.isScanning = false
            $0.pinCallback = PINCallback(id: UUID(number: 0), callback: newCallback)
        }
    }
    
    func testWrongPIN() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
            
        }
        let store = TestStore(initialState: IdentificationScanState(request: request,
                                                                    pin: pin,
                                                                    pinCallback: pinCallback,
                                                                    shared: SharedScanState(isScanning: true)),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        let newCallback = { (_: String) in }
        store.send(.scanEvent(.success(.requestPIN(remainingAttempts: 2, pinCallback: newCallback)))) {
            $0.shared.isScanning = false
            $0.pinCallback = PINCallback(id: UUID(number: 0), callback: newCallback)
        }
        
        store.receive(.wrongPIN(remainingAttempts: 2))
    }
    
    func testShowNFCInfo() {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { _ in }
        
        let store = TestStore(initialState: IdentificationScanState(request: request,
                                                                    pin: pin,
                                                                    pinCallback: pinCallback,
                                                                    shared: SharedScanState(isScanning: false)),
                              reducer: identificationScanReducer,
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
        let pinCallback = PINCallback(id: UUID(number: 0)) { _ in }
        
        let store = TestStore(initialState: IdentificationScanState(request: request,
                                                                    pin: pin,
                                                                    pinCallback: pinCallback,
                                                                    shared: SharedScanState(isScanning: false)),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
