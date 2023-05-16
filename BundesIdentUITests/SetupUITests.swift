import XCTest

final class SetupUITests: XCTestCase {

    func testFirstTimeUserHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launch()
        
        app.assertBeingOnHome()
        
        app.buttons[L10n.Home.Setup.setup].wait().tap()
        app.buttons[L10n.FirstTimeUser.Intro.startSetup].wait().tap()
        app.buttons[L10n.FirstTimeUser.PinLetter.letterPresent].wait().tap()
        
        let transportPINTextField = app.textFields[L10n.FirstTimeUser.TransportPIN.textFieldLabel]
        transportPINTextField.wait().tap()
        transportPINTextField.waitAndTypeText("12345")
        
        app.toolbars["Toolbar"].buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        app.buttons[L10n.FirstTimeUser.PersonalPINIntro.continue].wait().tap()
        
        let pin1TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first]
        pin1TextField.wait().tap()
        pin1TextField.waitAndTypeText("123456")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        let pin2TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second]
        pin2TextField.wait().tap()
        pin2TextField.waitAndTypeText("123456")
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Scan.button].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()

        app.buttons["Not Now"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.Done.title].assertExistence()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testFirstTimeUserSkipSetup() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launch()
        
        app.assertBeingOnHome()
        
        app.buttons[L10n.Home.Setup.setup].wait().tap()
        app.buttons[L10n.FirstTimeUser.Intro.skipSetup].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.AlreadySetupConfirmation.title].assertExistence()
        
        app.buttons[L10n.FirstTimeUser.AlreadySetupConfirmation.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testIdentificationWithSetupInbetween() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithDemoTokenURL()
        app.launch()
        
        app.buttons[L10n.FirstTimeUser.Intro.startSetup].wait().tap()
        app.buttons[L10n.FirstTimeUser.PinLetter.letterPresent].wait().tap()
        
        let transportPINTextField = app.textFields[L10n.FirstTimeUser.TransportPIN.textFieldLabel]
        transportPINTextField.wait().tap()
        transportPINTextField.waitAndTypeText("12345")
        
        app.toolbars["Toolbar"].buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        app.buttons[L10n.FirstTimeUser.PersonalPINIntro.continue].wait().tap()
        
        let pin1TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first]
        pin1TextField.wait().tap()
        pin1TextField.waitAndTypeText("123456")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        let pin2TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second]
        pin2TextField.wait().tap()
        pin2TextField.waitAndTypeText("123456")
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Scan.button].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.Done.title].assertExistence()
        
        app.buttons[L10n.FirstTimeUser.Done.identify].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
        
        app.buttons[L10n.Identification.AttributeConsent.continue].wait().tap()
        
        let pinTextField = app.secureTextFields[L10n.Identification.PersonalPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.buttons[L10n.Identification.PersonalPIN.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["identifySuccessfully"].wait().tap()
        
        let safari = XCUIApplication(bundleIdentifier: SafariIdentifiers.bundleId.rawValue)
        guard safari.wait(for: .runningForeground, timeout: 5.0) else {
            return XCTFail("Safari is not in the foreground")
        }
        
        app.activate()
        app.assertBeingOnHome()
    }
    
    func testSetupWrongTransportPINAndEndEarly() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.Setup.setup].wait().tap()
        app.buttons[L10n.FirstTimeUser.Intro.startSetup].wait().tap()
        app.buttons[L10n.FirstTimeUser.PinLetter.letterPresent].wait().tap()
        
        let transportPINTextField = app.textFields[L10n.FirstTimeUser.TransportPIN.textFieldLabel]
        transportPINTextField.wait().tap()
        transportPINTextField.waitAndTypeText("12345")
        
        app.toolbars["Toolbar"].buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        app.buttons[L10n.FirstTimeUser.PersonalPINIntro.continue].wait().tap()
        
        let pin1TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first]
        pin1TextField.wait().tap()
        pin1TextField.waitAndTypeText("123456")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        let pin2TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second]
        pin2TextField.wait().tap()
        pin2TextField.waitAndTypeText("123456")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Scan.button].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (3)"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.IncorrectTransportPIN.title].assertExistence()
        
        app.buttons[L10n.General.cancel].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.ConfirmEnd.confirm].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testSetupWrongTransportPINAndThenHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.Setup.setup].wait().tap()
        app.buttons[L10n.FirstTimeUser.Intro.startSetup].wait().tap()
        app.buttons[L10n.FirstTimeUser.PinLetter.letterPresent].wait().tap()
        
        let transportPINTextField = app.textFields[L10n.FirstTimeUser.TransportPIN.textFieldLabel]
        transportPINTextField.wait().tap()
        transportPINTextField.waitAndTypeText("12345")
        
        app.toolbars["Toolbar"].buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        app.buttons[L10n.FirstTimeUser.PersonalPINIntro.continue].wait().tap()
        
        let pin1TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first]
        pin1TextField.wait().tap()
        pin1TextField.waitAndTypeText("123456")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        let pin2TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second]
        pin2TextField.wait().tap()
        pin2TextField.waitAndTypeText("123456")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        app.buttons[L10n.Scan.button].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (3)"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.IncorrectTransportPIN.title].assertExistence()
        
        let pinTextField = app.textFields[L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.buttons[L10n.FirstTimeUser.IncorrectTransportPIN.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()

        app.buttons["Not Now"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.Done.title].assertExistence()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testSetupMismatchingPINs() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.Setup.setup].wait().tap()
        app.buttons[L10n.FirstTimeUser.Intro.startSetup].wait().tap()
        app.buttons[L10n.FirstTimeUser.PinLetter.letterPresent].wait().tap()
        
        let transportPINTextField = app.textFields[L10n.FirstTimeUser.TransportPIN.textFieldLabel]
        transportPINTextField.wait().tap()
        transportPINTextField.waitAndTypeText("12345")
        
        app.toolbars["Toolbar"].buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        app.buttons[L10n.FirstTimeUser.PersonalPINIntro.continue].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.PersonalPIN.title].assertExistence()
        let pin1TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first]
        pin1TextField.wait().tap()
        pin1TextField.waitAndTypeText("111111")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.PersonalPIN.Confirmation.title].assertExistence()
        let pin2TextField = app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second]
        pin2TextField.wait().tap()
        pin2TextField.waitAndTypeText("222222")
        
        app.buttons[L10n.FirstTimeUser.PersonalPIN.continue].wait().tap()
        
        app.alerts.staticTexts[L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title].assertExistence()
        app.alerts.buttons[L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.retry].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.PersonalPIN.title].assertExistence()
        XCTAssertEqual(app.secureTextFields[L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first].value as! String, "")
    }
    
}
