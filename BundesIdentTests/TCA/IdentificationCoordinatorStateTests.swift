import XCTest

@testable import BundesIdent

final class IdentificationCoordinatorStateTests: XCTestCase {

    func testTransformToLocalInteractionHandlerSingleState() throws {
        let subState = IdentificationOverviewLoadingState()
        let state = IdentificationCoordinatorState(tokenURL: demoTokenURL, states: [.root(.overview(.loading(subState)))])
        
        let effect = state.transformToLocalInteractionHandler(event: .failure(.cardBlocked))
        
        guard let effect = effect else {
            return XCTFail("Effect should not be nil")
        }
        
        XCTAssertEqual(effect, .routeAction(0, action: .overview(.loading(.idInteractionEvent(.failure(.cardBlocked))))))
    }
    
    func testTransformToLocalInteractionHandlerLastState() throws {

        let state = IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                   states: [
                                                    .root(.overview(.loading(IdentificationOverviewLoadingState()))),
                                                    .push(.overview(.loading(IdentificationOverviewLoadingState())))
                                                   ])
        
        let effect = state.transformToLocalInteractionHandler(event: .failure(.cardBlocked))
        
        guard let effect = effect else {
            return XCTFail("Effect should not be nil")
        }
        
        XCTAssertEqual(effect, .routeAction(1, action: .overview(.loading(.idInteractionEvent(.failure(.cardBlocked))))))
    }
    
    func testNoTransformToLocalInteractionHandler() throws {
        
        struct SomeError: Error { }
        let state = IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                   states: [
                                                    .root(.overview(.error(IdentificationOverviewErrorState(error: IdentifiableError(SomeError())))))
                                                   ])
        
        let effect = state.transformToLocalInteractionHandler(event: .failure(.cardBlocked))
        XCTAssertNil(effect)
    }
    
    func testNotLastTransformToLocalInteractionHandler() throws {
        
        struct SomeError: Error { }
        let state = IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                   states: [
                                                    .root(.overview(.loading(IdentificationOverviewLoadingState()))),
                                                    .push(.overview(.error(IdentificationOverviewErrorState(error: IdentifiableError(SomeError())))))
                                                   ])
        
        let effect = state.transformToLocalInteractionHandler(event: .failure(.cardBlocked))
        
        guard let effect = effect else {
            return XCTFail("Effect should not be nil")
        }
        
        XCTAssertEqual(effect, .routeAction(0, action: .overview(.loading(.idInteractionEvent(.failure(.cardBlocked))))))
    }

}
