import XCTest

final class MiraUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingFlowCompletesAndShowsMainExperience() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-selected-tab", "history"
        ])

        XCTAssertTrue(app.buttons["onboarding.primary"].waitForExistence(timeout: 5))

        app.buttons["onboarding.primary"].tap()
        let healthFocusOption = app.buttons["onboarding.healthFocus.generalWellness"]
        XCTAssertTrue(healthFocusOption.waitForExistence(timeout: 2))
        healthFocusOption.tap()
        app.buttons["onboarding.primary"].tap()
        app.buttons["onboarding.primary"].tap()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHistoryOpensProductDetail() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "history"
        ])

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        let productName = app.staticTexts["UI Test Granola"]
        XCTAssertTrue(productName.waitForExistence(timeout: 5))
        productName.tap()

        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["productDetail.focusSnapshot"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["productDetail.compareFocuses"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSeededShoppingListShowsSavedItem() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "shopping-list"
        ])

        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Granola"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfileSettingsCanClearSeededHistory() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "profile"
        ])

        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))

        app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        app.buttons["settings.clearHistory"].tap()
        let clearButton = app.alerts.buttons["Clear"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2))
        clearButton.tap()
        app.buttons["settings.close"].tap()

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["No scans yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func launchApp(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + arguments
        app.launch()
        return app
    }
}
