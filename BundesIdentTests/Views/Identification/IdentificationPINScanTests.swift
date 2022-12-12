import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationPINScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    
    override func setUp() {
        mockAnalyticsClient = MockAnalyticsClient()
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
            initialState: IdentificationPINScan.State(request: request,
                                                      pin: pin,
                                                      pinCallback: pinCallback,
                                                      shared: SharedScan.State(isScanning: false, showInstructions: true)),
            reducer: IdentificationPINScan()
        )
        
        store.send(.onAppear)
    }
    
    func testOnAppearIgnoredWhenAlreadyScanning() throws {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
        }
        let store = TestStore(initialState: IdentificationPINScan.State(request: request,
                                                                        pin: pin,
                                                                        pinCallback: pinCallback,
                                                                        shared: SharedScan.State(isScanning: true)),
                              reducer: IdentificationPINScan())
        
        store.send(.onAppear)
    }
    
    func testCancellation() throws {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { _ in }
        
        let store = TestStore(initialState: IdentificationPINScan.State(request: request,
                                                                        pin: pin,
                                                                        pinCallback: pinCallback,
                                                                        shared: SharedScan.State(isScanning: true)),
                              reducer: IdentificationPINScan())
        store.dependencies.uuid = .incrementing
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
        let store = TestStore(initialState: IdentificationPINScan.State(request: request,
                                                                        pin: pin,
                                                                        pinCallback: pinCallback,
                                                                        shared: SharedScan.State(isScanning: true)),
                              reducer: IdentificationPINScan())
        store.dependencies.uuid = .incrementing
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
        
        let store = TestStore(initialState: IdentificationPINScan.State(request: request,
                                                                        pin: pin,
                                                                        pinCallback: pinCallback,
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
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { _ in }
        
        let store = TestStore(initialState: IdentificationPINScan.State(request: request,
                                                                        pin: pin,
                                                                        pinCallback: pinCallback,
                                                                        shared: SharedScan.State(isScanning: false)),
                              reducer: IdentificationPINScan())
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
