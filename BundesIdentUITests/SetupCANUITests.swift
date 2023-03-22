import XCTest

final class SetupCANUITests: XCTestCase {
    
    func testGivenSuspendedCard_ChangePIN_ByEnteringWrongCANOnceAndThenHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        let incorrectCANTextField = app.textFields[L10n.Identification.Can.IncorrectInput.canInputLabel]
        incorrectCANTextField.wait().tap()
        incorrectCANTextField.waitAndTypeText("123456")
        
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testGivenSuspendedCard_GoBackToIntroAfterEnteringWrongCAN_ThenHappyPath() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        app.navigationBars.buttons[L10n.General.back].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testGivenNormalCard_ChangePIN_ByEnteringCorrectCANAndWrongPINs() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        transportPINInCANTextField.waitAndTypeText("12345")
        app.buttons[L10n.FirstTimeUser.TransportPIN.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()

        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
    
    func testSuspendedCardAndWrongTransportPINToBlock() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (1)"].wait().tap()
        
        app.staticTexts[L10n.ScanError.CardBlocked.title].assertExistence()
        
        app.buttons[L10n.ScanError.close].wait().tap()
        app.assertBeingOnHome()
    }
    
    func testContinueWithIdentification_AfterCANInSetup() throws {
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
        app.buttons["runCardSuspended"].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        let canTextField = app.textFields[L10n.Identification.Can.Input.canInputLabel]
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runCANError"].wait().tap()
        
        app.navigationBars.buttons[L10n.General.back].wait().tap()
        
        app.buttons[L10n.Identification.Can.Intro.continue].wait().tap()
        
        canTextField.wait().tap()
        canTextField.waitAndTypeText("123456")
        app.buttons[L10n.Identification.Can.Input.continue].wait().tap()
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.identify].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
    }
    
    func testContinueWithIdentification_AfterCANInSetup_ConfirmingTransportPIN() throws {
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
        app.buttons["runPINError (3)"].wait().tap()
        
        let incorrectPINTextField = app.textFields[L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel]
        incorrectPINTextField.wait().tap()
        incorrectPINTextField.waitAndTypeText("12345")
        app.buttons[L10n.FirstTimeUser.IncorrectTransportPIN.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (2)"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Can.ConfirmTransportPIN.confirmInput].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.identify].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts[L10n.CardAttribute.dg04].assertExistence()
    }
    
    func testConfirmTransportPIN() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
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
        
        let incorrectPINTextField = app.textFields[L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel]
        incorrectPINTextField.wait().tap()
        incorrectPINTextField.waitAndTypeText("12345")
        app.buttons[L10n.FirstTimeUser.IncorrectTransportPIN.continue].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError (2)"].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Can.ConfirmTransportPIN.confirmInput].wait().tap()
        
        app.buttons[L10n.FirstTimeUser.Done.close].wait().tap()
        
        app.assertBeingOnHome()
    }
}
