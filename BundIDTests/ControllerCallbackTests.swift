//
//  ControllerCallbackTests.swift
//  BundIDTests
//
//  Created by Andreas Ganske on 19.09.22.
//

import XCTest
import Cuckoo
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

    func testOKActivationCode() throws {
        
        let activationResult = MockActivationResult(code: .OK)
            
        let controllerCallback = ControllerCallback()
            
        let completionExpectation = expectation(description: "Expect complection")
        let valueExpectation = expectation(description: "Expect value")
        let cancellable = controllerCallback.publisher.sink { completion in
            completionExpectation.fulfill()
            XCTAssertEqual(completion, .finished)
        } receiveValue: { value in
            valueExpectation.fulfill()
            XCTAssertEqual(value, .processCompletedSuccessfullyWithoutRedirect)
        }
        
        controllerCallback.onAuthenticationCompletion(activationResult)
            
        wait(for: [completionExpectation, valueExpectation], timeout: 0.5)
    }
    
    func testRedirectActivationCode() throws {
        
        let redirectUrl = "https://redirect.url"
        let activationResult = MockActivationResult(redirectUrl: redirectUrl, code: .REDIRECT)
        
        let controllerCallback = ControllerCallback()
        
        let completionExpectation = expectation(description: "Expect complection")
        let valueExpectation = expectation(description: "Expect value")
        let cancellable = controllerCallback.publisher.sink { completion in
            completionExpectation.fulfill()
            XCTAssertEqual(completion, .finished)
        } receiveValue: { value in
            valueExpectation.fulfill()
            XCTAssertEqual(value, .processCompletedSuccessfullyWithRedirect(url: redirectUrl))
        }
        
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
            let activationResult = MockActivationResult(redirectUrl: "", code: activationResultCode)
            
            let controllerCallback = ControllerCallback()
            
            let exp = expectation(description: "Expect complection")
            let cancellable = controllerCallback.publisher.sink { completion in
                exp.fulfill()
                XCTAssertEqual(completion, .failure(.processFailed(resultCode: activationResultCode)))
            } receiveValue: { _ in
                XCTFail("Should not receive any value")
            }
            
            controllerCallback.onAuthenticationCompletion(activationResult)
            
            wait(for: [exp], timeout: 0.1)
        }
    }

}
