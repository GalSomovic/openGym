import XCTest

/// Walks the main flows on a fresh profile with a starter plan loaded.
final class WorkoutFlowTests: XCTestCase {
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body"] + extra
        app.launch()
        return app
    }

    func testLogASetStartsTheRestTimerAndFinishShowsTheSummary() {
        let app = launch(["-GFTab", "today"])
        // Today may be a rest day: start the first of the other routines.
        let start = app.staticTexts["Start"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        let tick = app.buttons["Mark set done"].firstMatch
        XCTAssertTrue(tick.waitForExistence(timeout: 5))
        tick.tap()
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 3), "a rest starts after a set")
        app.buttons["Skip rest"].tap()

        app.buttons["Finish"].tap()
        let finishEarly = app.buttons["Finish workout"]
        XCTAssertTrue(finishEarly.waitForExistence(timeout: 3), "finishing early asks first")
        finishEarly.tap()
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Start workout"].waitForExistence(timeout: 3))
    }

    func testStepperChangesTheWeight() {
        let app = launch(["-GFTab", "today", "-GFStart", "0"])
        let plus = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Increase Weight'")).firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 5))
        plus.tap()
        let field = app.textFields.matching(NSPredicate(format: "label BEGINSWITH 'Weight'")).firstMatch
        XCTAssertNotEqual(field.value as? String, "0")
    }

    func testLibrarySearchOpensAnExercise() {
        let app = launch(["-GFTab", "exercises"])
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("bench press")
        let row = app.staticTexts["Barbell Bench Press"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["Instructions"].waitForExistence(timeout: 3) || app.staticTexts["INSTRUCTIONS"].exists)
    }

    func testBuildARoutine() {
        let app = launch(["-GFTab", "plan"])
        app.buttons["New"].firstMatch.tap()
        let add = app.buttons["Add exercise"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let quick = app.buttons["Add now"].firstMatch
        XCTAssertTrue(quick.waitForExistence(timeout: 5))
        quick.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["3/4 Sit-up"].waitForExistence(timeout: 3))
    }
}
