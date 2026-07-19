import XCTest

final class MiraUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
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
        let focusSnapshot = app.descendants(matching: .any)["productDetail.focusSnapshot"]
        XCTAssertTrue(focusSnapshot.waitForExistence(timeout: 5))
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
    func testDeniedCameraPermissionCanContinueWithSearch() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-complete-onboarding",
            "-selected-tab", "scan",
            "-simulate-camera-denied"
        ])

        XCTAssertTrue(app.staticTexts["Camera Access Required"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["scanner.openSettings"].exists)

        app.buttons["scanner.permissionBrowse"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSimulatedBarcodeScanOpensProductDetail() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "scan",
            "-simulate-scanned-barcode", "900000000001"
        ])

        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["UI Test Granola"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPhotoScanEntryOffersCameraAndPhotoLibrary() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-complete-onboarding",
            "-selected-tab", "scan",
            "-simulate-camera-available"
        ])

        XCTAssertTrue(app.buttons["scanner.photoMode"].waitForExistence(timeout: 5))
        app.buttons["scanner.photoMode"].tap()

        XCTAssertTrue(app.navigationBars["Photo Scan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["photoScan.camera"].exists)
        XCTAssertTrue(app.buttons["photoScan.photos"].exists)
    }

    @MainActor
    func testPhotoScanSingleMatchOpensProductDetailAfterConfirmation() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "scan",
            "-simulate-camera-available",
            "-simulate-photo-result", "single"
        ])

        XCTAssertTrue(app.buttons["scanner.photoMode"].waitForExistence(timeout: 5))
        app.buttons["scanner.photoMode"].tap()

        let match = app.buttons["photoScan.singleMatch"]
        XCTAssertTrue(match.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Granola"].exists)
        match.tap()

        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["UI Test Granola"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPhotoScanDisambiguationSelectsProductAndOpensDetail() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "scan",
            "-simulate-camera-available",
            "-simulate-photo-result", "multiple"
        ])

        XCTAssertTrue(app.buttons["scanner.photoMode"].waitForExistence(timeout: 5))
        app.buttons["scanner.photoMode"].tap()

        XCTAssertTrue(app.navigationBars["Select Product"].waitForExistence(timeout: 5))
        let granolaMatch = app.buttons["photoScan.match.900000000001"]
        XCTAssertTrue(granolaMatch.waitForExistence(timeout: 3))
        granolaMatch.tap()

        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 8))
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

        // Relaunch directly into History to verify the deletion persisted. This
        // also avoids relying on Xcode's device-dependent floating-tab role.
        app.terminate()
        app.launchArguments = [
            "-ui-testing",
            "-complete-onboarding",
            "-selected-tab", "history"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["No scans yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testResetAllAppDataReturnsToOnboarding() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "profile"
        ])

        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.buttons["settings.resetAllData"].waitForExistence(timeout: 5))

        app.buttons["settings.resetAllData"].tap()
        let resetButton = app.alerts.buttons["Reset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 2))
        resetButton.tap()

        XCTAssertTrue(app.buttons["onboarding.primary"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func launchApp(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + arguments
        app.launch()
        return app
    }
}
