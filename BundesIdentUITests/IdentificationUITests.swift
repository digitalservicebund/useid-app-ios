import XCTest

final class IdentificationUITests: XCTestCase {
    func testIdentificationTriggersSetupForFirstTimeUsers() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithResetUserDefaults()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.staticTexts[L10n.FirstTimeUser.Intro.title].assertExistence()
    }
    
    func testIdentificationShowAttributeDetails() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.moreInfo].wait().tap()
        
        app.staticTexts[L10n.Identification.AttributeConsentInfo.terms].assertExistence()
        app.navigationBars.buttons.firstMatch.wait().tap()
    }
    
    func testIdentificationHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Identification.Scan.scan].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["identifySuccessfully"].wait().tap()
        
        let safari = XCUIApplication(bundleIdentifier: SafariIdentifiers.bundleId.rawValue)
        XCTAssertEqual(safari.state, .runningForeground)
        
        app.activate()
        app.assertBeingOnHome()
    }
    
    func testIdentificationHappyPathSkippingInstructions() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.activityIndicators["ScanProgressView"].assertExistence()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["identifySuccessfully"].wait().tap()
        
        let safari = XCUIApplication(bundleIdentifier: SafariIdentifiers.bundleId.rawValue)
        XCTAssertEqual(safari.state, .runningForeground)
        
        app.activate()
        app.assertBeingOnHome()
    }
    
    func testIdentificationOverviewBackToSetupIntro() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.buttons[L10n.FirstTimeUser.Intro.skipSetup].wait().tap()
        
        app.navigationBars.buttons[L10n.General.back].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.Intro.title].assertExistence()
    }
    
    func testIdentificationLoadError() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["loadError"].wait().tap()
        
        app.buttons[L10n.Identification.FetchMetadataError.retry].wait().tap()
        
        app.staticTexts[L10n.Identification.FetchMetadata.pleaseWait].assertExistence()
    }
    
    func testIdentificationScanHelp() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Scan.helpScanning].wait().tap()
        
        app.staticTexts[L10n.ScanError.CardUnreadable.title].assertExistence()
        app.buttons[L10n.ScanError.close].wait().tap()
        
        app.buttons[L10n.Identification.Scan.scan].wait().tap()
    }
    
    func testIdentificationScanCancels() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["cancelPINScan"].wait().tap()
        app.buttons[L10n.Identification.Scan.scan].assertExistence()
    }
    
    func testIdentificationPINForgottenDismissesAfterConfirmation() throws {
        var remainingAttempts = 3
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launchWithDemoTokenURL()
        app.launchWithIdentifiedOnce()
        app.launch()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (\(remainingAttempts))"].wait().tap()
        remainingAttempts -= 1
        
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (\(remainingAttempts))"].wait().tap()
        
        app.navigationBars.buttons[L10n.General.cancel].wait().tap()
        app.buttons[L10n.Identification.ConfirmEnd.confirm].wait().tap()
        app.staticTexts[L10n.Home.Header.title].assertExistence()
    }
}
