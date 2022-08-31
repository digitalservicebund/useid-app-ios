import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundID

final class IdentificationScanTests: XCTestCase {

    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    var uuidCount = 0
    
    var mockIDInteractionManager = MockIDInteractionManagerType()
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(),
                                            uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager)
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
                                                  isScanning: false),
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
        let store = TestStore(initialState: IdentificationScanState(request: request, pin: pin, pinCallback: pinCallback, isScanning: true),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        store.send(.onAppear)
    }
    
    func testCancellation() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
            
        }
        let store = TestStore(initialState: IdentificationScanState(request: request,
                                                                    pin: pin,
                                                                    pinCallback: pinCallback,
                                                                    isScanning: true),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        let newCallback = { (_: String) in }
        store.send(.idInteractionEvent(.success(.requestPIN(remainingAttempts: nil, pinCallback: newCallback)))) {
            $0.isScanning = false
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
                                                                    isScanning: true),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        let newCallback = { (_: String) in }
        store.send(.idInteractionEvent(.success(.requestPIN(remainingAttempts: 2, pinCallback: newCallback)))) {
            $0.isScanning = false
            $0.pinCallback = PINCallback(id: UUID(number: 0), callback: newCallback)
        }
        
        store.receive(.wrongPIN(remainingAttempts: 2))
    }

}
