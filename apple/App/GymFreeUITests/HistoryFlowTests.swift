import XCTest

/// History, past workouts and body weight on a fresh profile with a starter plan loaded.
final class HistoryFlowTests: XCTestCase {
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body"] + extra
        app.launch()
        return app
    }

    /// Scrolls the Today list until `element` can be tapped.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 where !(element.exists && element.isHittable) { app.swipeUp() }
    }

    func testLoggedWeightShowsOnToday() {
        let app = launch(["-GFTab", "today"])
        let log = app.buttons["weight.log"]
        XCTAssertTrue(app.navigationBars["Start workout"].waitForExistence(timeout: 5))
        reveal(log, in: app)
        log.tap()
        let plus = app.buttons["+1"]
        XCTAssertTrue(plus.waitForExistence(timeout: 3))
        plus.tap()
        app.navigationBars.buttons["Save"].tap()
        let latest = app.descendants(matching: .any)["weight.latest"]
        XCTAssertTrue(latest.waitForExistence(timeout: 3), "the card shows the weigh-in")
        XCTAssertTrue(latest.label.contains("71"), latest.label)
    }

    func testFinishedWorkoutIsInHistoryAndItsDetailOpens() {
        let app = launch(["-GFTab", "today", "-GFStart", "0"])
        let tick = app.buttons["Mark set done"].firstMatch
        XCTAssertTrue(tick.waitForExistence(timeout: 5))
        tick.tap()
        if app.buttons["Skip rest"].waitForExistence(timeout: 2) { app.buttons["Skip rest"].tap() }
        let finish = app.buttons["Finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 3))
        finish.tap()
        let confirm = app.buttons["Finish workout"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 6))
        tapWhenReady(app.buttons["Done"])

        let history = app.buttons["today.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 3))
        history.tap()
        let row = app.staticTexts["Full Body A"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3), "the workout is in history")
        row.tap()
        let edit = app.buttons["Edit workout"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3), "the detail opens")
        XCTAssertTrue(app.staticTexts["Barbell Full Squat"].exists || app.staticTexts.count > 3)

        // The editor is the workout screen; saving goes back to the history.
        edit.tap()
        let save = app.navigationBars.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
    }

    func testLogAPastWorkout() {
        let app = launch(["-GFTab", "today"])
        let history = app.buttons["today.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 5))
        history.tap()
        tapWhenReady(app.buttons["Log a past workout"])
        let routine = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Routine'")).firstMatch
        XCTAssertTrue(routine.waitForExistence(timeout: 3))
        routine.tap()
        tapWhenReady(app.buttons["Full Body A"].firstMatch)
        tapWhenReady(app.navigationBars.buttons["Continue"])

        let more = app.navigationBars.buttons["More"].firstMatch
        XCTAssertTrue(more.waitForExistence(timeout: 5), "the workout screen opens on the past day")
        XCTAssertFalse(app.buttons["Guided mode"].exists, "a past workout has no timers")
        more.tap()
        tapWhenReady(app.buttons["Mark all sets done"])
        let finish = app.alerts.buttons["Finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 3))
        finish.tap()
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 6))
        tapWhenReady(app.buttons["Done"])

        XCTAssertTrue(history.waitForExistence(timeout: 5))
        history.tap()
        XCTAssertTrue(app.staticTexts["Full Body A"].firstMatch.waitForExistence(timeout: 3), "it is filed in history")
    }

    /// Waits for a control after a screen change before tapping it, so slow transitions don't fail the run.
    private func tapWhenReady(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) appears", file: file, line: line)
        element.tap()
    }
}
