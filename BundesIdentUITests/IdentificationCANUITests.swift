import XCTest

final class IdentificationCANUITests: XCTestCase {
    
    func testIdentificationCANThirdAttemptToSuccessFullyIdentified() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        let incorrectCANTextField = app.textFields[L10n.Identification.Can.IncorrectInput.canInputLabel]
        incorrectCANTextField.wait().tap()
        incorrectCANTextField.waitAndTypeText("123456")
        
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        let matchingButtons = app.navigationBars.buttons.matching(identifier: L10n.Identification.Can.IncorrectInput.back)
        matchingButtons.element(boundBy: 0).tap()
        app.staticTexts[L10n.Identification.Can.Intro.title].assertExistence()
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        incorrectCANTextField.wait().tap()
        incorrectCANTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["identifySuccessfully"].wait().tap()
        
        let safari = XCUIApplication(bundleIdentifier: SafariIdentifiers.bundleId.rawValue)
        guard safari.wait(for: .runningForeground, timeout: 5.0) else {
            return XCTFail("Safari is not in the foreground")
        }
        
        app.activate()
        app.assertBeingOnHome()
    }
    
    func testIdentificationCANThirdAttemptDismissesInIntro() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCardSuspended"].wait().tap()
        
        app.navigationBars.buttons[L10n.General.cancel].wait().tap()
        app.buttons[L10n.Identification.ConfirmEnd.confirm].wait().tap()
        app.staticTexts[L10n.Home.Header.title].assertExistence()
    }
    
    func testIdentificationCANDismissesScan() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.navigationBars.buttons[L10n.General.cancel].wait().tap()
        app.staticTexts[L10n.Home.Header.title].assertExistence()
    }
    
    func testIdentificationCANScanCancels() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
//      When we get an AA2SDK with cancellation working, we do the following:
//        app.navigationBars.staticTexts["Debug"].wait().tap()
//        app.buttons["cancelCANScan"].wait().tap()
        
        app.buttons[L10n.Scan.button].assertExistence()
    }
    
    func testIdentificationCANAfterTwoAttemptsToCardBlocked() throws {
        var remainingAttempts = 3
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runPINError (\(remainingAttempts))"].wait().tap()
        remainingAttempts -= 1
        
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runPINError (\(remainingAttempts))"].wait().tap()
        remainingAttempts -= 1
        
        app.buttons[L10n.Identification.Can.PinForgotten.orderNewPin].wait().tap()
        app.backButton.wait().tap()
        
        app.buttons[L10n.Identification.Can.PinForgotten.retry].wait().tap()
        app.backButton.wait().tap()
        
        app.buttons[L10n.Identification.Can.PinForgotten.retry].wait().tap()
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        let incorrectCANTextField = app.textFields[L10n.Identification.Can.IncorrectInput.canInputLabel]
        incorrectCANTextField.wait().tap()
        incorrectCANTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        let matchingButtons = app.navigationBars.buttons.matching(identifier: L10n.Identification.Can.IncorrectInput.back)
        matchingButtons.element(boundBy: 0).tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        incorrectCANTextField.wait().tap()
        incorrectCANTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.Can.Input.continue].wait().tap()
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        
        app.navigationBars.staticTexts["Debug"].wait().tap()
        app.buttons["runPINError (\(remainingAttempts))"].wait().tap()
        app.staticTexts[L10n.ScanError.CardBlocked.title].assertExistence()
    }
}
