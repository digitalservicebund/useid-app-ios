import XCTest

extension XCUIElement {
    
    func wait(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        assertExistence(file: file, line: line)
  
        // Element might be behind system overlays (e.g. home indicator).
        // This blocks interacting with it (e.g. tapping).
        // Scrolling until the element is completly visible on screen resolves this issue (in most cases).
        XCUIApplication().scrollElementIntoVisibility(self)
        
        return self
    }
    
    func waitAndTypeText(_ text: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        assertExistence(timeout: timeout, file: file, line: line)
        if !hasFocus {
            print("Element \(self) does not have focus yet. Tapping it to hopefully get focus. This should be investigated. \(file):\(line)")
            tap()
        }
    
        // Type new text as individual characters to work around issue not having fully typed in text sometimes
        for char in text {
            typeText("\(char)")
        }
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
        staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", text))
    }
}

extension XCUIApplication {
    
    var backButton: XCUIElement {
        navigationBars.buttons.element(boundBy: 0)
    }
    
    func hasVisible(element: XCUIElement) -> Bool {
        let safeFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height - 34)
        return safeFrame.contains(element.frame)
    }
    
    func scrollElementIntoVisibility(_ element: XCUIElement, maxSwipeActions: Int = 10) {
        guard !hasVisible(element: element) else { return }
        
        for _ in 0 ..< maxSwipeActions {
            swipeUp()
            
            if hasVisible(element: element) {
                break
            }
        }
    }
}
