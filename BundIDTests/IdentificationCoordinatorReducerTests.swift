import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundID

class IdentificationCoordinatorReducerTests: XCTestCase {
    
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
    
    func testOverviewLoadingSuccess() throws {
        let store = TestStore(initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL),
                              reducer: identificationCoordinatorReducer,
                              environment: environment)
        
        let request = EIDAuthenticationRequest.preview
        let closure = { (attributes: FlaggedAttributes) in }
        let callback = IdentifiableCallback<FlaggedAttributes>(id: UUID(number: 0), callback: closure)
        
        store.send(.idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(request, closure))))
        
        store.receive(.routeAction(0, action: .overview(.loading(.idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(request, closure)))))))
        
        store.receive(.routeAction(0, action: .overview(.loading(.done(request, callback))))) {
            $0.states = [
                .sheet(.overview(.loaded(.init(id: UUID(number: 1), request: request, handler: callback))))
            ]
        }
    }
    
    func testOverviewLoadedToPINEntry() throws {
        let request = EIDAuthenticationRequest.preview
        let closure = { (attributes: FlaggedAttributes) in }
        let callback = IdentifiableCallback<FlaggedAttributes>(id: UUID(number: 0), callback: closure)
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         states: [
                                                            .root(.overview(.loaded(.init(id: UUID(number: 0),
                                                                                          request: request,
                                                                                          handler: callback))))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        let pinCallback = PINCallback(id: UUID(number: 1), callback: { pin in })
        store.send(.routeAction(0, action: .overview(.loaded(.callbackReceived(request, pinCallback))))) {
            $0.states.append(.push(.personalPIN(IdentificationPersonalPINState(request: request, callback: pinCallback))))
        }
    }
    
    func testPINEntryToScan() throws {
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         states: [
                                                            .root(.personalPIN(.init(request: request,
                                                                                     callback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .personalPIN(.done(request: request, pin: "123456", pinCallback: callback)))) {
            $0.pin = "123456"
            $0.states.append(.push(.scan(IdentificationScanState(request: request, pin: "123456", pinCallback: callback))))
        }
    }
    
    func testScanToDone() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .scan(.identifiedSuccessfully(request)))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail("Unexpected state") }
            scanState.isScanning = false
            $0.states = [.root(.scan(scanState)), .push(.done(.init(request: request)))]
        }
    }
    
    func testScanToIncorrectPIN() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .scan(.wrongPIN(remainingAttempts: 2)))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail("Unexpected state") }
            scanState.remainingAttempts = 2
            $0.states = [.root(.scan(scanState)), .sheet(.incorrectPersonalPIN(.init(error: .incorrect, remainingAttempts: 2)))]
        }
    }
    
    func testIncorrectPINToScan() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback,
                                                                              remainingAttempts: 2))),
                                                            .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPINState(enteredPIN: "112233", remainingAttempts: 2)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(1, action: .incorrectPersonalPIN(.done(pin: "112233")))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail("Unexpected state") }
            $0.attempt += 1
            $0.pin = "112233"
            scanState.attempt = $0.attempt
            scanState.pin = $0.pin!
            $0.states = [.root(.scan(scanState))]
        }
    }
}
