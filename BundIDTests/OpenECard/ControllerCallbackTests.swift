import XCTest
import Cuckoo
import Combine
import OpenEcard

@testable import BundID

class MockActivationResult: NSObject, ActivationResultProtocol {
    
    var redirectUrl: String!
    var code: ActivationResultCode
    var errorMessage: String!
    var processResultMinor: String!
    
    init(redirectUrl: String? = nil, code: ActivationResultCode = .OK, errorMessage: String? = nil, processResultMinor: String? = nil) {
        self.redirectUrl = redirectUrl
        self.code = code
        self.errorMessage = errorMessage
        self.processResultMinor = processResultMinor
    }
    
    func getRedirectUrl() -> String! {
        return redirectUrl
    }
    
    func getCode() -> ActivationResultCode {
        return code
    }
    
    func getErrorMessage() -> String! {
        return errorMessage
    }
    
    func getProcessResultMinor() -> String! {
        return processResultMinor
    }
}

final class ControllerCallbackTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func tearDown() async throws {
        cancellables.removeAll()
    }
    
    func testOKActivationCode() throws {
        
        let activationResult = MockActivationResult(code: .OK)
        
        let controllerCallback = ControllerCallback()
        
        let completionExpectation = expectation(description: "Expect complection")
        let valueExpectation = expectation(description: "Expect value")
        controllerCallback.publisher.sink { completion in
            completionExpectation.fulfill()
            XCTAssertEqual(completion, .finished)
        } receiveValue: { value in
            valueExpectation.fulfill()
            XCTAssertEqual(value, .processCompletedSuccessfullyWithoutRedirect)
        }
        .store(in: &cancellables)
        
        controllerCallback.onAuthenticationCompletion(activationResult)
        
        wait(for: [completionExpectation, valueExpectation], timeout: 0.5)
    }
    
    func testRedirectActivationCode() throws {
        
        let redirectURL = URL(string: "https://redirect.url")!
        let activationResult = MockActivationResult(redirectUrl: redirectURL.absoluteString, code: .REDIRECT)
        
        let controllerCallback = ControllerCallback()
        
        let completionExpectation = expectation(description: "Expect complection")
        let valueExpectation = expectation(description: "Expect value")
        
        controllerCallback.publisher.sink { completion in
            completionExpectation.fulfill()
            XCTAssertEqual(completion, .finished)
        } receiveValue: { value in
            valueExpectation.fulfill()
            XCTAssertEqual(value, .processCompletedSuccessfullyWithRedirect(url: redirectURL))
        }
        .store(in: &cancellables)
        
        controllerCallback.onAuthenticationCompletion(activationResult)
        
        wait(for: [completionExpectation, valueExpectation], timeout: 0.5)
    }
    
    func testAllOtherActivationResultsTriggerFailure() throws {
        
        let allActivationResultCodes: [ActivationResultCode] = [
            .CLIENT_ERROR,
            .INTERRUPTED,
            .INTERNAL_ERROR,
            .DEPENDING_HOST_UNREACHABLE,
            .BAD_REQUEST
        ]
        
        for activationResultCode in allActivationResultCodes {
            let activationResult = MockActivationResult(code: activationResultCode)
            
            let controllerCallback = ControllerCallback()
            
            let exp = expectation(description: "Expect complection")
            controllerCallback.publisher.sink { completion in
                exp.fulfill()
                XCTAssertEqual(completion, .failure(.processFailed(resultCode: activationResultCode, redirectURL: nil, resultMinor: nil)))
            } receiveValue: { _ in
                XCTFail("Should not receive any value")
            }
            .store(in: &cancellables)
            
            controllerCallback.onAuthenticationCompletion(activationResult)
            
            wait(for: [exp], timeout: 0.1)
        }
    }
    
    func testFailureRedirect() throws {
        let minor = "http://www.bsi.bund.de/ecard/api/1.1/resultminor/ifdl/common#invalidSlotHandle"
        let redirectURL = URL(string: "https://redirect.url")!
        let activationResult = MockActivationResult(redirectUrl: redirectURL.absoluteString,
                                                    code: .REDIRECT,
                                                    processResultMinor: minor)
        
        let controllerCallback = ControllerCallback()
        let completionExpectation = expectation(description: "Expect complection")
        
        controllerCallback.publisher.sink { completion in
            completionExpectation.fulfill()
            XCTAssertEqual(completion, .failure(.processFailed(resultCode: .REDIRECT,
                                                               redirectURL: redirectURL,
                                                               resultMinor: minor)))
        } receiveValue: { value in
            XCTFail("Should not receive any value")
        }
        .store(in: &cancellables)
        
        controllerCallback.onAuthenticationCompletion(activationResult)
        
        wait(for: [completionExpectation], timeout: 0.5)
    }
}
