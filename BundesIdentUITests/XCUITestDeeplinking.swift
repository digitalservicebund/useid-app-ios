import Foundation
import XCTest

enum UIStatus: String {
    case exist = "exists == true"
    case notExist = "exists == false"
    case selected = "selected == true"
    case notSelected = "selected == false"
    case hittable = "isHittable == true"
    case notHittable = "isHittable == false"
    case isEqual = "label MATCHES '%@'"
}

enum SafariIdentifiers: String {
    case bundleId = "com.apple.mobilesafari"
    case url = "URL"
    case clearText = "Clear text"
    case webView = "WebView"
    case open = "Open"
    case cancel = "Cancel"
    case continueText = "Continue"
    case quickPathText = "Speed up your typing by sliding your finger across the letters to compose a word."
}

enum KeyboardKeys: String {
    case go = "Go"
}

func expect(element: XCUIElement, status: UIStatus, timeout: TimeInterval = 5, message: String? = nil) {
    let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: status.rawValue), object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    
    if result == .timedOut {
        XCTFail(message ?? expectation.description)
    }
}

func openDeeplink(deeplink: String, app: XCUIApplication, timeout: TimeInterval = 5) {
    let safari = XCUIApplication(bundleIdentifier: SafariIdentifiers.bundleId.rawValue)
    let openButton = safari.otherElements["SFDialogView"].buttons.element(boundBy: 1)
    let urlTextField = safari.textFields[SafariIdentifiers.url.rawValue]
    let urlField = safari.textFields["TabBarItemTitle"]
    let quickPathDialog = safari.otherElements["UIContinuousPathIntroductionView"]
    let quickPathContinueTextButton = quickPathDialog.buttons.element
    
    safari.launch()
    
    expect(element: safari, status: .hittable)
    
    if !urlTextField.waitForExistence(timeout: 3) {
        expect(element: urlField, status: .hittable)
        urlField.tap()
    }
    
    if quickPathDialog.exists {
        quickPathContinueTextButton.tap()
    }
    
    urlTextField.typeText(deeplink)
    
    safari.buttons[KeyboardKeys.go.rawValue].wait(timeout: timeout).tap()
    expect(element: openButton, status: .hittable)
    
    openButton.tap()
    
    expect(element: app, status: .hittable)
}
