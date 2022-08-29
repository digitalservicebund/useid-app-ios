import Foundation
import XCTest

extension XCUIApplication {
    func launchWithResetUserDefaults() {
        launchArguments.append(LaunchArgument.resetUserDefaults)
    }
    
    func launchWithSetupCompleted() {
        launchArguments.append(LaunchArgument.setupCompleted)
    }
    
    func launchWithDemoTokenURL() {
        launchArguments.append(LaunchArgument.useDemoTokenURL)
    }
    
    func launchWithDefaultArguments() {
        launchArguments.append(LaunchArgument.uiTesting)
    }
}
