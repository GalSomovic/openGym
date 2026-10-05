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

    func testDemoArrowsSwitchVersionsAndOpenFullScreen() {
        let app = launch(["-GFTab", "exercises", "-GFDetail", "0662"])
        let label = app.staticTexts["media.label"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        let first = label.label
        app.buttons["media.next"].tap()
        XCTAssertNotEqual(label.label, first)
        app.buttons["media.previous"].tap()
        XCTAssertEqual(label.label, first)
        app.buttons["media.fullscreen"].tap()
        let close = app.buttons["media.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        app.buttons["media.next"].firstMatch.tap()
        sleep(1)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "fullscreen-landscape"; shot.lifetime = .keepAlways
        add(shot)
        close.tap()
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertNotEqual(label.label, first, "a version picked full screen is kept")
        app.buttons["media.previous"].tap()
    }

    func testMakeMeAPlanAddsRoutines() {
        // The starter plan is loaded, so the builder is in the More menu.
        let app = launch(["-GFTab", "plan"])
        let more = app.buttons["More"].firstMatch
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        more.tap()
        app.buttons["Make me a plan"].firstMatch.tap()
        let show = app.buttons["planBuilder.show"]
        XCTAssertTrue(show.waitForExistence(timeout: 5))
        show.tap()
        let add = app.buttons["planPreview.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Why this plan"].exists || app.staticTexts["WHY THIS PLAN"].exists)
        add.tap()
        // Monday, Wednesday and Friday already have the starter routines: confirm replacing them.
        let confirm = app.buttons["Add plan"]
        if confirm.waitForExistence(timeout: 3) { confirm.tap() }
        XCTAssertTrue(app.staticTexts["Full Body 3× · A"].firstMatch.waitForExistence(timeout: 5))
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

    func testGuidedModeTicksASetAndRests() {
        let app = launch(["-GFTab", "today", "-GFStart", "0"])
        let guided = app.buttons["Guided mode"]
        XCTAssertTrue(guided.waitForExistence(timeout: 5))
        guided.tap()
        let done = app.buttons["Set done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        let skip = app.buttons["Skip rest"]
        XCTAssertTrue(skip.waitForExistence(timeout: 3), "guided mode rests after a set")
        XCTAssertTrue(app.staticTexts["UP NEXT"].exists || app.staticTexts["Up next"].exists)
        skip.tap()
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Set 2 of 3"].exists || app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Set 2 of'")).firstMatch.exists)
        app.buttons["Show the whole workout"].tap()
        XCTAssertTrue(app.buttons["Guided mode"].waitForExistence(timeout: 3))
    }

    func testAssigningARoutineToADayShowsAtOnce() {
        let app = launch(["-GFTab", "plan"])
        // Full Body loads Monday, Wednesday and Friday; Tuesday is a rest day.
        let tuesday = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Tuesday'")).firstMatch
        XCTAssertTrue(tuesday.waitForExistence(timeout: 5))
        tuesday.tap()
        let pick = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Full Body A'")).firstMatch
        XCTAssertTrue(pick.waitForExistence(timeout: 3))
        pick.tap()
        XCTAssertTrue(app.buttons["Remove Full Body A from Tuesday"].waitForExistence(timeout: 3),
                      "the week updates without a restart")
    }

    func testRoutineEditorReorderIsExplicit() {
        let app = launch(["-GFTab", "plan", "-GFRoutine", "0"])
        let reorder = app.buttons["Reorder"]
        XCTAssertTrue(reorder.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Edit"].exists, "no unexplained Edit button")
        reorder.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Changes save automatically"].exists)
    }
}
