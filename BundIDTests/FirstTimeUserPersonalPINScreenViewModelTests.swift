import XCTest

@testable import BundID

class FirstTimeUserPersonalPINScreenViewModelTests: XCTestCase {

    func testCompletePIN1() throws {
        let viewModel = FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456")
        viewModel.handlePIN1Change("123456")
        
        XCTAssertTrue(viewModel.showPIN2)
        XCTAssertTrue(viewModel.focusPIN2)
    }
    
    func testCorrectPIN2() throws {
        let viewModel = FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456", enteredPIN2: "123456")
        viewModel.handlePIN2Change("123456")
        
        XCTAssertTrue(viewModel.isFinished)
        XCTAssertNil(viewModel.error)
    }
    
    func testMismatchingPIN2() throws {
        let viewModel = FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456", enteredPIN2: "987654")
        viewModel.handlePIN2Change("987654")
        
        XCTAssertFalse(viewModel.isFinished)
        XCTAssertEqual(viewModel.error, .mismatch)
    }
    
    func testTypingPIN2() throws {
        let viewModel = FirstTimeUserPersonalPINScreenViewModel(enteredPIN1: "123456", enteredPIN2: "123")
        viewModel.handlePIN2Change("123")
        
        XCTAssertFalse(viewModel.isFinished)
        XCTAssertNil(viewModel.error)
    }
}
