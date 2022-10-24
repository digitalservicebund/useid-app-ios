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
    
    func testIdentificationHappyPath() throws {
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
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Identification.Scan.scan].tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["identifySuccessfully"].wait().tap()
        
        app.buttons[L10n.Home.startSetup].assertExistence()
        
        let safari = XCUIApplication(bundleIdentifier: SafariIdentifiers.bundleId.rawValue)
        XCTAssertEqual(safari.state, .runningForeground)
    }
    
    func testIdentificationOverviewBackToSetupIntro() throws {
        let app = XCUIApplication()
        app.launchWithResetUserDefaults()
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
        
        app.staticTexts[L10n.Identification.FetchMetadata.loadingData].assertExistence()
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
        app.buttons[L10n.ScanError.close].tap()

        app.buttons[L10n.Identification.Scan.scan].wait().tap()
    }
}
