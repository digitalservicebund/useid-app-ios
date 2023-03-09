import XCTest

final class HomeUITests: XCTestCase {

    func testLaunchSetupManually() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.Setup.setup].wait().tap()
        app.staticTexts[L10n.FirstTimeUser.Intro.title].assertExistence()
    }
    
    func testLicenses() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.More.licenses].wait().tap()
        app.staticTexts[L10n.Home.More.licenses].assertExistence()
        app.staticTexts["swift-composable-architecture"].assertExistence()
        app.backButton.assertExistence()
    }
    
    func testPrivacyPolicy() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.More.privacy].wait().tap()
        app.staticTexts[L10n.Privacy.title].assertExistence()
        app.staticTexts["E‑Mail: poststelle@bfdi.bund.de ↗"].assertExistence()
        app.backButton.assertExistence()
    }
    
    func testAccessibilityStatement() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.More.accessibilityStatement].wait().tap()
        app.staticTexts[L10n.Accessibility.title].assertExistence()
        app.longStaticText(containing: "www.schlichtungsstelle-bgg.de").assertExistence()
        app.backButton.assertExistence()
    }
    
    func testTermsOfUse() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.More.terms].wait().tap()
        app.staticTexts[L10n.TermsOfUse.title].assertExistence()
        app.backButton.assertExistence()
    }
    
    func testImprint() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        app.buttons[L10n.Home.More.imprint].wait().tap()
        app.staticTexts[L10n.Imprint.title].assertExistence()
        app.staticTexts["DigitalService GmbH des Bundes"].assertExistence()
        app.longStaticText(containing: "HRB 212879 B").assertExistence()
        app.backButton.assertExistence()
    }
    
    func testContainsAppVersionAndBuildNumber() throws {
        let app = XCUIApplication()
        app.launchWithDefaultArguments()
        app.launchWithSetupCompleted()
        app.launch()
        
        let bundle = Bundle(for: type(of: self))
        
        // swiftlint:disable force_cast
        let version = bundle.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildNumber = bundle.infoDictionary!["CFBundleVersion"] as! String
        // swiftlint:enable force_cast
        
        app.longStaticText(containing: version).assertExistence()
        app.longStaticText(containing: buildNumber).assertExistence()
    }
    
}
