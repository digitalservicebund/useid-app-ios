import XCTest

final class BundIDUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSetupHappyPath() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Einrichtung starten"].tap()
        app.buttons["Nein, jetzt Online-Ausweis einrichten"].tap()
        app.buttons["Ja, PIN-Brief vorhanden"].tap()
        
        let transportPINTextField = app.textFields["Transport-PIN, fünfstellig"]
        transportPINTextField.tap()
        transportPINTextField.typeText("12345")
        
        app.toolbars["Toolbar"].buttons["Weiter"].tap()
        app.buttons["Persönliche PIN wählen"].tap()
        
        let pin1TextField = app.secureTextFields["Persönliche PIN, sechsstellig"]
        pin1TextField.tap()
        pin1TextField.typeText("123456")
        
        let pin2TextField = app.secureTextFields["Persönliche PIN bestätigen, sechsstellig"]
        pin2TextField.tap()
        pin2TextField.typeText("123456")
        
        app.navigationBars.buttons["Schraubenschlüssel"].tap()
        app.buttons["Success"].tap()
        
        XCTAssertTrue(app.staticTexts["Einrichtung abgeschlossen"].waitForExistence(timeout: 5))
        
        app.buttons["Schließen"].tap()
        
        XCTAssertTrue(app.buttons["Einrichtung starten"].waitForExistence(timeout: 1))
    }
}
