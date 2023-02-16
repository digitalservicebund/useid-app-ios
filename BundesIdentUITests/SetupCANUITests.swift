import XCTest

final class SetupCANUITests: XCTestCase {
    
    func testSuspendedCardWrongCANOnceAndThenHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        app.buttons["askForCAN"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.activityIndicators["ScanProgressView"].assertExistence()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["askForCAN"].wait().tap()
        
        let incorrectCANTextField = app.textFields[L10n.Identification.Can.IncorrectInput.canInputLabel]
        incorrectCANTextField.wait().tap()
        incorrectCANTextField.waitAndTypeText("123456")
        
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.activityIndicators["ScanProgressView"].assertExistence()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.buttons[L10n.Home.startSetup].assertExistence()
    }
    
    func testSuspendAndBlockCardByEnteringCANAndWrongPINs() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        
        let incorrectPINTextField = app.textFields[L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel]
        incorrectPINTextField.wait().tap()
        incorrectPINTextField.waitAndTypeText("12345")
        app.buttons[L10n.FirstTimeUser.IncorrectTransportPIN.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (2)"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Can.ConfirmTransportPIN.confirmInput].wait().tap()
        app.staticTexts[L10n.FirstTimeUser.Can.AlreadySetup.title].assertExistence()
        app.backButton.wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Can.ConfirmTransportPIN.incorrectInput].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        let transportPINInCANTextField = app.textFields[L10n.FirstTimeUser.TransportPIN.textFieldLabel]
        transportPINInCANTextField.wait().tap()
        transportPINInCANTextField.typeText("12345")
        app.buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        
        app.activityIndicators["ScanProgressView"].assertExistence()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.buttons[L10n.Home.startSetup].assertExistence()
    }
    
    func testSuspendedCardAndWrongTransportPINToBlock() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        app.buttons["askForCAN"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.activityIndicators["ScanProgressView"].assertExistence()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (1)"].wait().tap()
        
        app.staticTexts[L10n.ScanError.CardBlocked.title].assertExistence()
        
        app.buttons[L10n.ScanError.close].wait().tap()
        app.buttons[L10n.Home.startSetup].assertExistence()
    }
}
