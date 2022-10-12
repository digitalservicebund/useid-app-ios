import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundesIdent

final class ScanErrorReducerTests: XCTestCase {
    let redirectURL = URL(string: "localhost")!
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    
    var openedURL: URL?
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment.mocked(urlOpener: { self.openedURL = $0 })
    }
    
    override func tearDown() {
        openedURL = nil
    }
    
    func testReducerRetry() {
        let store = TestStore(
            initialState: ScanErrorState(errorType: .help, retry: true),
            reducer: scanErrorReducer,
            environment: environment
        )
        
        store.send(.retry)
        
        XCTAssertNil(openedURL)
    }
    
    
    func testReducerWithoutRedirectURL() {
        let store = TestStore(
            initialState: ScanErrorState(errorType: .idCardInteraction(.processFailed(resultCode: .INTERNAL_ERROR,
                                                                                      redirectURL: nil,
                                                                                      resultMinor: nil)),
                                         retry: false),
            reducer: scanErrorReducer,
            environment: environment
        )
        
        store.send(.end(redirectURL: nil))
        
        XCTAssertNil(openedURL)
    }
    
    func testReducerOpensRedirectURL() {
        let store = TestStore(
            initialState: ScanErrorState(errorType: .idCardInteraction(.processFailed(resultCode: .BAD_REQUEST,
                                                                                      redirectURL: redirectURL,
                                                                                      resultMinor: nil)),
                                         retry: false),
            reducer: scanErrorReducer,
            environment: environment
        )
        
        store.send(.end(redirectURL: redirectURL))
        
        XCTAssertEqual(openedURL, redirectURL)
    }
}

final class ScanErrorStateTests: XCTestCase {
    let redirectURL = URL(string: "localhost")!
    
    func testStateRetryPrimaryButton() {
        let state = ScanErrorState(errorType: .help, retry: true)
        
        XCTAssertEqual(state.primaryButton.title, L10n.ScanError.close)
        XCTAssertEqual(state.primaryButton.action, .retry)
    }
    
    func testRedirectErrorPrimaryButton() {
        let state = ScanErrorState(errorType: .idCardInteraction(.processFailed(resultCode: .CLIENT_ERROR,
                                                                                redirectURL: redirectURL,
                                                                                resultMinor: nil)),
                                   retry: false)
        
        XCTAssertEqual(state.primaryButton.title, L10n.ScanError.redirect)
        XCTAssertEqual(state.primaryButton.action, .end(redirectURL: redirectURL))
        
        
    }
    
    func testGenericErrorPrimaryButton() {
        let state = ScanErrorState(errorType: .idCardInteraction(.frameworkError(message: nil)), retry: false)
        
        XCTAssertEqual(state.primaryButton.title, L10n.ScanError.close)
        XCTAssertEqual(state.primaryButton.action, .end(redirectURL: nil))
    }
    
    func testNoBoxWithRetry() {
        let state = ScanErrorState(errorType: .help, retry: true)
        XCTAssertNil(state.boxContent)
    }
    
    func testBoxWithoutRetry() {
        let state = ScanErrorState(errorType: .idCardInteraction(.processFailed(resultCode: .CLIENT_ERROR,
                                                                                redirectURL: redirectURL,
                                                                                resultMinor: nil)),
                                   retry: false)
        
        XCTAssertEqual(state.boxContent?.title, L10n.ScanError.Box.title)
        XCTAssertEqual(state.boxContent?.message, L10n.ScanError.Box.body)
    }
    
    func testBoxWithCardBlocked() {
        let state = ScanErrorState(errorType: .idCardInteraction(.cardBlocked), retry: false)
        XCTAssertNil(state.boxContent)
        
        let cardInteractionState = ScanErrorState(errorType: .cardBlocked, retry: false)
        XCTAssertNil(cardInteractionState.boxContent)
    }
    
    func testBoxWithCardDeactivated() {
        let state = ScanErrorState(errorType: .idCardInteraction(.cardDeactivated), retry: false)
        XCTAssertNil(state.boxContent)
        
        let cardInteractionState = ScanErrorState(errorType: .cardDeactivated, retry: false)
        XCTAssertNil(cardInteractionState.boxContent)
    }
}
