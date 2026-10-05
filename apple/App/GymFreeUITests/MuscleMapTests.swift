import XCTest

/// The body maps: Stats' muscle balance, fatigue and strength maps, the routine editor's
/// coverage map and the Exercises tab's browse by muscle.
final class MuscleMapTests: XCTestCase {
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body"] + extra
        app.launch()
        return app
    }

    /// Scrolls until `element` can be tapped.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 where !(element.exists && element.isHittable) { app.swipeUp(velocity: .slow) }
    }

    private func tapWhenReady(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) appears", file: file, line: line)
        element.tap()
    }

    func testStatsMapSwitchesModesAndAMuscleShowsItsExercises() {
        // The last 30 days, which hold the seeded workouts whatever weekday the test runs on.
        let app = launch(["-GFSeed", "6", "-GFTab", "stats", "-gf.muscleWindow", "30"])
        let views = app.segmentedControls["muscles.view"]
        XCTAssertTrue(views.waitForExistence(timeout: 6))
        reveal(views, in: app)
        tapWhenReady(views.buttons.element(boundBy: 0))
        let chest = app.buttons["muscle.chest"].firstMatch
        XCTAssertTrue(chest.waitForExistence(timeout: 3), "the balance map shows")
        reveal(chest, in: app)
        chest.tap()
        XCTAssertTrue(app.descendants(matching: .any)["muscles.selected"].waitForExistence(timeout: 3), "a tapped muscle shows its sets")

        views.buttons.element(boundBy: 1).tap()   // Fatigue
        XCTAssertTrue(app.staticTexts["Ready"].waitForExistence(timeout: 3) || app.staticTexts["Fatigued"].exists,
                      "the fatigue legend shows")

        views.buttons.element(boundBy: 2).tap()   // Strength
        let chest2 = app.buttons["muscle.chest"].firstMatch
        reveal(chest2, in: app)
        chest2.tap()
        let exercise = app.descendants(matching: .any)["muscles.exercise"].firstMatch
        XCTAssertTrue(exercise.waitForExistence(timeout: 3), "the strength map lists the muscle's exercises")
        XCTAssertTrue(exercise.label.contains("Est. 1RM"), exercise.label)
    }

    func testRoutineEditorShowsTheMap() {
        let app = launch(["-GFTab", "plan", "-GFRoutine", "0"])
        let map = app.descendants(matching: .any)["bodymap"].firstMatch
        XCTAssertTrue(app.navigationBars["Full Body A"].waitForExistence(timeout: 6))
        reveal(map, in: app)
        XCTAssertTrue(map.exists, "What this session hits is a body map")
        XCTAssertTrue(map.value as? String != "No muscles worked", "\(map.value ?? "")")
    }

    func testExercisesBrowseByMuscle() {
        let app = launch(["-GFTab", "exercises"])
        let mode = app.segmentedControls["library.mode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 6))
        tapWhenReady(mode.buttons["By muscle"])
        let chest = app.buttons["muscle.chest"].firstMatch
        XCTAssertTrue(chest.waitForExistence(timeout: 3), "the explorer's body map shows")
        chest.tap()
        let header = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Exercises for Chest'")).firstMatch
        reveal(header, in: app)
        XCTAssertTrue(header.waitForExistence(timeout: 3), "the chest's exercises are listed")
        reveal(app.staticTexts["Barbell Bench Press"].firstMatch, in: app)
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].firstMatch.exists)
    }
}
