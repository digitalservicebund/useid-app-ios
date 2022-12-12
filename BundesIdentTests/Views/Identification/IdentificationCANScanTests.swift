import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

final class IdentificationCANScanTests: XCTestCase {
    
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
    
    func testOnAppearDoesTriggerScanningWhenNotAlreadyScanning() throws {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(
            initialState: IdentificationCANScan.State(request: request,
                                                      pin: pin,
                                                      can: can,
                                                      pinCANCallback: pinCANCallback,
                                                      shared: SharedScan.State(isScanning: false, showInstructions: false)),
            reducer: IdentificationCANScan()
        )
        store.dependencies.analytics = mockAnalyticsClient
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
        let store = TestStore(initialState: IdentificationCANScan.State(request: request,
                                                                        pin: pin,
                                                                        can: can,
                                                                        pinCANCallback: pinCANCallback,
                                                                        shared: SharedScan.State(isScanning: true, showInstructions: false)),
                              reducer: IdentificationCANScan())
        
        store.send(.onAppear)
    }
    
    func testCancellation() throws {
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScan.State(request: request,
                                                                        pin: pin,
                                                                        can: can,
                                                                        pinCANCallback: pinCANCallback,
                                                                        shared: SharedScan.State(isScanning: true, showInstructions: false)),
                              reducer: IdentificationCANScan())
        store.dependencies.uuid = .incrementing
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
        let store = TestStore(initialState: IdentificationCANScan.State(request: request,
                                                                        pin: pin,
                                                                        can: can,
                                                                        pinCANCallback: pinCANCallback,
                                                                        shared: SharedScan.State(isScanning: true, showInstructions: false)),
                              reducer: IdentificationCANScan())
        store.dependencies.uuid = .incrementing
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
        let store = TestStore(initialState: IdentificationCANScan.State(request: request,
                                                                        pin: pin,
                                                                        can: can,
                                                                        pinCANCallback: pinCANCallback,
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
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let can = "123456"
        let pinCANCallback = PINCANCallback(id: UUID(number: 0)) { pin, can in }
        let store = TestStore(initialState: IdentificationCANScan.State(request: request,
                                                                        pin: pin,
                                                                        can: can,
                                                                        pinCANCallback: pinCANCallback,
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
