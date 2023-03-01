import XCTest

final class SetupUITests: XCTestCase {

    func testFirstTimeUserHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launch()
        
        app.assertBeingOnHome()
        
        app.buttons[L10n.Home.startSetup].wait().tap()
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
        
        app.buttons[L10n.FirstTimeUser.Scan.scan].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.Done.title].assertExistence()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testSetupWrongTransportPINAndEndEarly() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.startSetup].wait().tap()
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
        
        app.buttons[L10n.FirstTimeUser.Scan.scan].wait().tap()
        
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
        
        app.buttons[L10n.Home.startSetup].wait().tap()
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
        
        app.buttons[L10n.FirstTimeUser.Scan.scan].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (3)"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.IncorrectTransportPIN.title].assertExistence()
        
        let pinTextField = app.textFields[L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        app.buttons[L10n.FirstTimeUser.IncorrectTransportPIN.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.staticTexts[L10n.FirstTimeUser.Done.title].assertExistence()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testSetupMismatchingPINs() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.startSetup].wait().tap()
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
