import XCTest

/// Plan intelligence: routine time and difficulty, the cool-down suggestion and "Improve my plan".
final class PlanInsightsTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFTab", "plan"] + extra
        app.launch()
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, max: Int = 12) {
        for _ in 0..<max where !(element.exists && element.isHittable) { app.swipeUp(velocity: .slow) }
    }

    /// Keeps a screenshot in the test results and, with GF_SHOTS set (TEST_RUNNER_GF_SHOTS for
    /// xcodebuild), as a PNG in that folder.
    private func shot(_ app: XCUIApplication, _ name: String) {
        let image = app.screenshot()
        let a = XCTAttachment(screenshot: image); a.name = name; a.lifetime = .keepAlways; add(a)
        if let dir = ProcessInfo.processInfo.environment["GF_SHOTS"] {
            try? image.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    func testRoutineRowsShowTheirTimeAndTheWeekItsTotal() {
        let app = launch(["-GFStarter", "full-body"])
        let total = app.staticTexts["week.total"]
        reveal(total, in: app)
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertTrue(total.label.contains("3 sessions"), total.label)
        let row = app.descendants(matching: .any).matching(identifier: "routine.summary").firstMatch
        reveal(row, in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("min"), row.label)
        shot(app, "plan-routine-times")
    }

    func testImprovePlanAddsARoutine() {
        // Push/pull/legs has no core work: the sheet offers a short core routine on free days.
        let app = launch(["-GFStarter", "ppl"])
        let improve = app.buttons["plan.improve"]
        reveal(improve, in: app, max: 16)
        XCTAssertTrue(improve.waitForExistence(timeout: 5))
        shot(app, "plan-coverage-improve")
        improve.tap()
        XCTAssertTrue(app.navigationBars["Improve my plan"].waitForExistence(timeout: 5))
        let add = app.buttons["improve.add.newRoutine"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        shot(app, "improve-plan-sheet")
        add.tap()
        XCTAssertTrue(app.staticTexts["Added"].waitForExistence(timeout: 3))
        app.navigationBars["Improve my plan"].buttons["Done"].tap()
        // The new routine is in the list and on the week.
        let core = app.staticTexts["Core"].firstMatch
        for _ in 0..<16 where !core.exists { app.swipeDown(velocity: .slow) }
        XCTAssertTrue(core.waitForExistence(timeout: 5), "the core routine was added")
        shot(app, "plan-after-improve")
    }

    func testCooldownSuggestionAddsStretches() {
        let app = launch(["-GFStarter", "full-body", "-GFRoutine", "0"])
        XCTAssertTrue(app.navigationBars["Full Body A"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.descendants(matching: .any)["routine.stats"].waitForExistence(timeout: 3), "time and difficulty under the name")
        let stretchRows = { app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'stretch' OR label CONTAINS[c] 'pose'")).count }
        let rowsBefore = stretchRows()
        let apply = app.buttons["insight.apply.cooldown"]
        reveal(apply, in: app)
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        shot(app, "editor-cooldown-suggestion")
        apply.tap()
        XCTAssertFalse(apply.waitForExistence(timeout: 2), "the suggestion goes once taken")
        XCTAssertGreaterThanOrEqual(stretchRows(), rowsBefore + 2, "two or more stretches were added")
        shot(app, "editor-cooldown-added")
    }

    func testAHeavyRoutineOffersAFixThatCanBeDismissed() {
        // The starter push day puts more than 10 sets on the chest in one session.
        let app = launch(["-GFStarter", "ppl", "-GFRoutine", "0"])
        XCTAssertTrue(app.navigationBars["Push Day"].waitForExistence(timeout: 6))
        let drop = app.buttons["insight.apply.dropSet"]
        reveal(drop, in: app)
        XCTAssertTrue(drop.waitForExistence(timeout: 5))
        shot(app, "editor-too-much")
        app.buttons["insight.dismiss.tooMuch"].tap()
        XCTAssertFalse(drop.waitForExistence(timeout: 2), "dismissed for this routine")
    }
}
