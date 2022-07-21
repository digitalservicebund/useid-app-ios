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
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["changePINSuccessfully"].wait().tap()
        
        app.staticTexts["Einrichtung abgeschlossen"].assertExistence()
        
        app.buttons["Schließen"].wait().tap()
        
        app.buttons["Einrichtung starten"].assertExistence()
    }
    
    func testSetupWrongTransportPINAndEndEarly() throws {
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
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["runPINError"].wait().tap()
        
        app.staticTexts["Falsche Transport-PIN"].assertExistence()
        
        app.buttons["Einrichtung beenden"].wait().tap()
        
        app.buttons["Beenden"].wait().tap()
        
        app.buttons["Einrichtung starten"].assertExistence()
    }
    
    func testIdentificationHappyPath() throws {
        let app = XCUIApplication()
        app.launchArguments = ["TOKEN_URL=bundid://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%3A443%2FAutent-DemoApplication%2FWebServiceRequesterServlet%3Fdummy%3Dfalse%26useCan%3Dfalse%26ta%3Dfalse"]
        app.launch()
        
        app.buttons["Identifizierung erneut starten"].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["requestAuthorization"].wait().tap()
        
        app.staticTexts["Subject"].assertExistence()
        app.staticTexts["Vorname(n)"].assertExistence()
        
        app.buttons["Weitere Informationen zu „Subject“"].wait().tap()
        
        app.staticTexts["Terms"].assertExistence()
        app.navigationBars.buttons.firstMatch.wait().tap()
        
        app.buttons["PIN eingeben"].wait().tap()
        
        let pinTextField = app.secureTextFields["Persönliche PIN, sechsstellig"]
        pinTextField.wait().tap()
        pinTextField.waitAndTypeText("123456")
        
        app.toolbars["Toolbar"].buttons["Weiter"].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["identifySuccessfully"].wait().tap()
        
        app.staticTexts["Sie haben sich erfolgreich ausgewiesen"].assertExistence()
        
        app.buttons["Schließen"].wait().tap()
        
        app.buttons["Einrichtung starten"].assertExistence()
    }
    
    func testIdentificationLoadError() throws {
        let app = XCUIApplication()
        app.launchArguments = ["TOKEN_URL=bundid://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%3A443%2FAutent-DemoApplication%2FWebServiceRequesterServlet%3Fdummy%3Dfalse%26useCan%3Dfalse%26ta%3Dfalse"]
        app.launch()
        
        app.buttons["Identifizierung erneut starten"].wait().tap()
        
        app.navigationBars.buttons["Debug"].wait().tap()
        app.buttons["loadError"].wait().tap()
        
        app.buttons["Erneut versuchen"].wait().tap()
        
        app.staticTexts["Einen Moment bitte…\n\nDaten werden geladen"].assertExistence()
    }
}
