//
//  MiraUITestsLaunchTests.swift
//  Mira UITests
//
//  Created by Lauren Barnhart on 9/29/25.
//

import XCTest

final class MiraUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-complete-onboarding", "-selected-tab", "history"]
        app.launch()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
