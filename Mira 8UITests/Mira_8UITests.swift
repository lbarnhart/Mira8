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

        let productName = app.staticTexts["Harvest Oat Crunch"]
        XCTAssertTrue(productName.waitForExistence(timeout: 5))
        productName.tap()

        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 5))
        let focusSnapshot = app.descendants(matching: .any)["productDetail.focusSnapshot"]
        XCTAssertTrue(focusSnapshot.waitForExistence(timeout: 5))
        let scoreExplanation = app.buttons["productDetail.scoreExplanation"]
        XCTAssertTrue(scoreExplanation.waitForExistence(timeout: 2))
        scoreExplanation.tap()
        XCTAssertTrue(app.navigationBars["How Mira Scored This"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["scoreExplanation.componentSummary"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["productDetail.compareFocuses"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testHistoryAndProductDetailPassAccessibilityAudit() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-seed-demo-data-limit", "2",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL",
            "-selected-tab", "history"
        ])

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        if #available(iOS 17.0, *) {
            try performCoreAccessibilityAudit(in: app)
        }

        // Dynamic Type auditing mutates the live UI environment. Relaunch so
        // navigation starts from a stable, production-equivalent state on
        // both compact iPhone and regular-width iPad layouts.
        app.terminate()
        app.launchArguments = [
            "-ui-testing",
            "-complete-onboarding",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL",
            "-selected-tab", "history"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        let productName = app.staticTexts["Harvest Oat Crunch"]
        XCTAssertTrue(productName.waitForExistence(timeout: 5))
        productName.tap()
        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 5))

        if #available(iOS 17.0, *) {
            try performCoreAccessibilityAudit(in: app)
        }
    }

    @MainActor
    func testSeededShoppingListShowsSavedItem() throws {
        let app = launchApp(arguments: [
            "-reset-state",
            "-seed-demo-data",
            "-selected-tab", "shopping-list"
        ])

        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Harvest Oat Crunch"].waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts["Harvest Oat Crunch"].waitForExistence(timeout: 5))
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

    @available(iOS 17.0, *)
    private func performCoreAccessibilityAudit(in app: XCUIApplication) throws {
        let recordIssue: (XCUIAccessibilityAuditIssue) -> Void = { issue in
            XCTContext.runActivity(named: "Accessibility audit issue details") { activity in
                var internalDescription = ""
                dump(
                    issue,
                    to: &internalDescription,
                    name: "XCAccessibilityAuditIssue",
                    maxDepth: 6,
                    maxItems: 200
                )
                let description = [
                    issue.compactDescription,
                    issue.detailedDescription,
                    issue.element?.debugDescription ?? "No matching accessibility element",
                    internalDescription
                ].joined(separator: "\n\n")
                let attachment = XCTAttachment(string: description)
                attachment.name = "Accessibility Issue.txt"
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
        }

        let issueHandler: (XCUIAccessibilityAuditIssue) -> Bool = { issue in
            recordIssue(issue)

            // iOS 26 can report an unidentified text-clipping issue while it
            // exercises the system tab bar at accessibility sizes. There is no
            // element for the app to repair, so keep the evidence attachment.
            if issue.auditType == .textClipped && issue.element == nil {
                return true
            }

            // The floating system tab bar overlays scroll content. Xcode can
            // audit clipped, offscreen descendants as though they were visible
            // through that material. Only suppress contrast findings whose
            // element frame actually intersects the system tab bar.
            if issue.auditType == .contrast,
               let element = issue.element,
               app.tabBars.firstMatch.exists,
               element.frame.intersects(app.tabBars.firstMatch.frame) {
                return true
            }

            return false
        }

        try app.performAccessibilityAudit(for: [
            .contrast,
            .elementDetection,
            .hitRegion,
            .sufficientElementDescription,
            .textClipped,
            .trait
        ], issueHandler)

        // Dynamic Type changes the live app's content-size environment while it
        // runs. Keep it isolated so subsequent visual checks are not performed
        // against a transient, partially clipped accessibility-size layout.
        try app.performAccessibilityAudit(for: [.dynamicType]) { issue in
            recordIssue(issue)

            // iPadOS can also report a system UILabel without returning an
            // element that belongs to the app. Preserve the diagnostic, but
            // only suppress unidentified system findings.
            return issue.element == nil
        }
    }
}
