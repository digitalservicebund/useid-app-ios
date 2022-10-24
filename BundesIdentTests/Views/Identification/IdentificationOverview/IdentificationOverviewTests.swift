import Analytics
import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundesIdent

final class IdentificationOverviewTests: XCTestCase {
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var environment: AppEnvironment!
    var uuidCount = 0
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        environment = AppEnvironment.mocked(uuidFactory: uuidFactory,
                                            analytics: mockAnalyticsClient)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }

    func testLoadingFailure() {
        let error = IdentifiableError(NSError(domain: "", code: 0))
        let store = TestStore(
            initialState: IdentificationOverviewState.loading(.init()),
            reducer: identificationOverviewReducer,
            environment: environment
        )
        
        store.send(IdentificationOverviewAction.loading(.failure(error))) {
            $0 = .error(IdentificationOverviewErrorState(error: error))
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "loadingFailed",
                                                                name: "attributes"))
    }
    
    func testLoadingSuccess() {
        let store = TestStore(
            initialState: IdentificationOverviewState.loading(.init()),
            reducer: identificationOverviewReducer,
            environment: environment
        )
        
        let request = EIDAuthenticationRequest.preview
        let handler: (FlaggedAttributes) -> Void = { attributes in }
        
        store.send(IdentificationOverviewAction.loading(.idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(request, handler)))))
        
        let callback = IdentifiableCallback(id: UUID(number: 0), callback: handler)
        store.receive(.loading(.done(request, callback))) {
            $0 = .loaded(.init(id: UUID(number: 1),
                               request: request,
                               handler: callback))
        }
    }
    
    func testLoadedConfirm() {
        let callbackExpectation = expectation(description: "Expect callback to be called")
        let request = EIDAuthenticationRequest.preview
        
        let callback: (FlaggedAttributes) -> Void = { attributes in
            XCTAssertEqual(attributes, [.DG01: true, .DG02: true, .DG03: true, .DG04: true])
            callbackExpectation.fulfill()
        }
        
        let identifiableCallback = IdentifiableCallback(id: UUID(number: 0), callback: callback)
        
        let loadedState = IdentificationOverviewLoadedState(id: UUID(number: 0), request: request, handler: identifiableCallback)
        let store = TestStore(
            initialState: IdentificationOverviewState.loaded(loadedState),
            reducer: identificationOverviewReducer,
            environment: environment
        )
        
        store.send(IdentificationOverviewAction.loaded(.confirm))
        
        wait(for: [callbackExpectation], timeout: 1.0)
    }
    
    func testReceivePINCallback() {
        let request = EIDAuthenticationRequest.preview
        let callback: (FlaggedAttributes) -> Void = { attributes in
            XCTFail("Should not be called")
        }
        
        let identifiableCallback = IdentifiableCallback(id: UUID(number: 0), callback: callback)
        
        let loadedState = IdentificationOverviewLoadedState(id: UUID(number: 0), request: request, handler: identifiableCallback)
        let store = TestStore(
            initialState: IdentificationOverviewState.loaded(loadedState),
            reducer: identificationOverviewReducer,
            environment: environment
        )
        
        let pinCallback: (String) -> Void = { _ in }
        let identifiablePINCallback = PINCallback(id: UUID(number: 0), callback: pinCallback)
        store.send(IdentificationOverviewAction.loaded(.idInteractionEvent(.success(.requestPIN(remainingAttempts: nil, pinCallback: pinCallback))))) {
            let newLoadedState = IdentificationOverviewLoadedState(
                id: UUID(number: 0),
                request: request,
                handler: identifiableCallback,
                pinHandler: identifiablePINCallback
            )
            $0 = .loaded(newLoadedState)
        }
        
        store.receive(.loaded(.callbackReceived(request, identifiablePINCallback)))
    }
    
    func testCallingPINHandlerWhenConfirming() {
        let request = EIDAuthenticationRequest.preview
        
        let callback: (FlaggedAttributes) -> Void = { attributes in
            XCTFail("Should not be called")
        }
        
        let identifiableCallback = IdentifiableCallback(id: UUID(number: 0), callback: callback)
        
        let pinCallback: (String) -> Void = { _ in }
        let identifiablePINCallback = PINCallback(id: UUID(number: 0), callback: pinCallback)
        
        let loadedState = IdentificationOverviewLoadedState(
            id: UUID(number: 0),
            request: request,
            handler: identifiableCallback,
            pinHandler: identifiablePINCallback
        )
        let store = TestStore(
            initialState: IdentificationOverviewState.loaded(loadedState),
            reducer: identificationOverviewReducer,
            environment: environment
        )
        
        store.send(IdentificationOverviewAction.loaded(.confirm))
        
        store.receive(.loaded(.callbackReceived(request, identifiablePINCallback)))
    }
}
