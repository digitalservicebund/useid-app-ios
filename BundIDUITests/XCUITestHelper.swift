import XCTest

extension XCUIElement {
    
    func wait(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        assertExistence(file: file, line: line)
        return self
    }
    
    func waitAndTypeText(_ text: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        assertExistence(file: file, line: line)
        if !hasFocus {
            print("Element \(self) does not have focus yet. Tapping it to hopefully get focus. This should be investigated. \(file):\(line)")
            tap()
        }
        typeText(text)
    }
    
    func assertExistence(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(waitForExistence(timeout: timeout), "Element \(self) does not exist.", file: file, line: line)
    }
    
    func assertInexistence(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: self)
        guard XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed else {
            return XCTFail("Element \(self) exists", file: file, line: line)
        }
    }
    
    func longStaticText(containing text: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        return staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", text))
    }
}
