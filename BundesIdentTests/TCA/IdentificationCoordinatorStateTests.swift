import XCTest

@testable import BundesIdent

final class IdentificationCoordinatorStateTests: XCTestCase {

    func testTransformToLocalInteractionHandlerSingleState() throws {
        let subState = IdentificationOverviewLoading.State()
        let state = IdentificationCoordinator.State(tokenURL: demoTokenURL, states: [.root(.overview(.loading(subState)))])
        
        let effect = state.transformToLocalAction(.failure(.cardBlocked))
        
        guard let effect else {
            return XCTFail("Effect should not be nil")
        }
        
        XCTAssertEqual(effect, .routeAction(0, action: .overview(.loading(.idInteractionEvent(.failure(.cardBlocked))))))
    }
    
    func testTransformToLocalInteractionHandlerLastState() throws {
        let state = IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                    states: [
                                                        .root(.overview(.loading(IdentificationOverviewLoading.State()))),
                                                        .push(.overview(.loading(IdentificationOverviewLoading.State())))
                                                    ])
        
        let effect = state.transformToLocalAction(.failure(.cardBlocked))
        
        guard let effect else {
            return XCTFail("Effect should not be nil")
        }
        
        XCTAssertEqual(effect, .routeAction(1, action: .overview(.loading(.idInteractionEvent(.failure(.cardBlocked))))))
    }
    
    func testNoTransformToLocalInteractionHandler() throws {
        struct SomeError: Error {}
        let state = IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                    states: [
                                                        .root(.overview(.error(IdentificationOverviewErrorState(error: IdentifiableError(SomeError())))))
                                                    ])
        
        let effect = state.transformToLocalAction(.failure(.cardBlocked))
        XCTAssertNil(effect)
    }
    
    func testNotLastTransformToLocalInteractionHandler() throws {
        struct SomeError: Error {}
        let state = IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                    states: [
                                                        .root(.overview(.loading(IdentificationOverviewLoading.State()))),
                                                        .push(.overview(.error(IdentificationOverviewErrorState(error: IdentifiableError(SomeError())))))
                                                    ])
        
        let effect = state.transformToLocalAction(.failure(.cardBlocked))
        
        guard let effect else {
            return XCTFail("Effect should not be nil")
        }
        
        XCTAssertEqual(effect, .routeAction(0, action: .overview(.loading(.idInteractionEvent(.failure(.cardBlocked))))))
    }

}
