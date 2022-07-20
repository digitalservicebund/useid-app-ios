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
    
    override func setUp() {
        scheduler = DispatchQueue.test
        
        let uuidFactory = {
            let currentCount = self.uuidCount
            self.uuidCount += 1
            return UUID(number: currentCount)
        }
        
        environment = AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                     uuidFactory: uuidFactory,
                                     idInteractionManager: mockIDInteractionManager,
                                     debugIDInteractionManager: DebugIDInteractionManager())
    }
    
    func testOnAppearTriggersScanning() throws {
        
        let request = EIDAuthenticationRequest.preview
        let pin = "123456"
        let pinCallback = PINCallback(id: UUID(number: 0)) { pin in
            
        }
        let store = TestStore(initialState: IdentificationScanState(request: request, pin: pin, pinCallback: pinCallback),
                              reducer: identificationScanReducer,
                              environment: environment)
        
        store.send(.onAppear)
        store.receive(.startScan)
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

}
