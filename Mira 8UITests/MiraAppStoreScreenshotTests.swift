import XCTest

/// Reproducible, rights-safe product-page screenshots. The seeded products are
/// fictitious and only exist when the app is launched by UI testing.
final class MiraAppStoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func test01ProductOverview() throws {
        let app = openSeededProductDetail()
        capture(app, name: "01-product-overview")
    }

    @MainActor
    func test02PersonalizedScoreComparison() throws {
        let app = openSeededProductDetail()

        let compareButton = app.buttons["productDetail.compareFocuses"]
        XCTAssertTrue(compareButton.waitForExistence(timeout: 10))
        compareButton.tap()
        XCTAssertTrue(app.navigationBars["Compare Health Focuses"].waitForExistence(timeout: 5))
        capture(app, name: "02-personalized-score")
    }

    @MainActor
    func test03Insights() throws {
        let app = launchApp(tab: "insights")

        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your General Wellness Snapshot"].waitForExistence(timeout: 10))
        capture(app, name: "03-insights")
    }

    @MainActor
    func test04History() throws {
        let app = launchApp(tab: "history")

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Harvest Oat Crunch"].waitForExistence(timeout: 5))
        capture(app, name: "04-history")
    }

    @MainActor
    func test05ShoppingList() throws {
        let app = launchApp(tab: "shopping-list")

        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Harvest Oat Crunch"].waitForExistence(timeout: 5))
        capture(app, name: "05-shopping-list")
    }

    @MainActor
    private func openSeededProductDetail() -> XCUIApplication {
        let app = launchApp(tab: "history")
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        let product = app.staticTexts["Harvest Oat Crunch"]
        XCTAssertTrue(product.waitForExistence(timeout: 5))
        product.tap()

        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Harvest Oat Crunch"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func launchApp(tab: String, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", tab
        ] + extraArguments
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, name: String) {
        // Give asynchronous image/score presentation a moment to settle so
        // captures are stable across local and hosted runners.
        Thread.sleep(forTimeInterval: 0.75)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
