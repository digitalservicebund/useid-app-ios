import XCTest

final class BundIDUITests: XCTestCase {

    func testSetupHappyPath() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Einrichtung starten"].wait().tap()
        app.buttons["Nein, jetzt Online-Ausweis einrichten"].wait().tap()
        app.buttons["Ja, PIN-Brief vorhanden"].wait().tap()
        
        let transportPINTextField = app.textFields["Transport-PIN, fünfstellig"]
        transportPINTextField.wait().tap()
        transportPINTextField.waitAndTypeText("12345")
        
        app.toolbars["Toolbar"].buttons["Weiter"].wait().tap()
        app.buttons["Persönliche PIN wählen"].wait().tap()
        
        let pin1TextField = app.secureTextFields["Persönliche PIN, sechsstellig"]
        pin1TextField.wait().tap()
        pin1TextField.waitAndTypeText("123456")
        
        let pin2TextField = app.secureTextFields["Persönliche PIN bestätigen, sechsstellig"]
        pin2TextField.wait().tap()
        pin2TextField.waitAndTypeText("123456")
        
        app.navigationBars.buttons["Schraubenschlüssel"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.staticTexts["Einrichtung abgeschlossen"].assertExistence()
        
        app.buttons["Schließen"].wait().tap()
        
        app.buttons["Einrichtung starten"].assertExistence()
    }
}
