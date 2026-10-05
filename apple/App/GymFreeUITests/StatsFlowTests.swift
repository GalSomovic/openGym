import XCTest

/// Stats: the tab after a finished workout, exercise progress curves, the heatmap, effort,
/// structural balance, the 1RM calculator and the curve in the workout's history sheet.
final class StatsFlowTests: XCTestCase {
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body"] + extra
        app.launch()
        return app
    }

    /// Scrolls until `element` can be tapped.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !(element.exists && element.isHittable) { app.swipeUp() }
    }

    private func tapWhenReady(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) appears", file: file, line: line)
        element.tap()
    }

    private var chart: (XCUIApplication) -> XCUIElement { { $0.descendants(matching: .any)["progress.chart"].firstMatch } }

    func testFinishedWorkoutShowsInStatsWithItsProgressCurve() {
        let app = launch(["-GFTab", "today", "-GFStart", "0"])
        tapWhenReady(app.buttons["Mark set done"].firstMatch)
        if app.buttons["Skip rest"].waitForExistence(timeout: 2) { app.buttons["Skip rest"].tap() }
        tapWhenReady(app.buttons["Finish"])
        tapWhenReady(app.buttons["Finish workout"])
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 6))
        tapWhenReady(app.buttons["Done"])

        tapWhenReady(app.tabBars.buttons["Stats"])
        let workouts = app.descendants(matching: .any)["stats.tile.workouts"]
        XCTAssertTrue(workouts.waitForExistence(timeout: 5), "the tiles show")
        XCTAssertTrue(workouts.label.contains("1"), workouts.label)

        let picker = app.buttons["stats.progressPicker"]
        reveal(picker, in: app)
        tapWhenReady(picker)
        XCTAssertTrue(app.navigationBars["Exercise progress"].waitForExistence(timeout: 3))
        tapWhenReady(app.collectionViews.cells.firstMatch)
        XCTAssertTrue(chart(app).waitForExistence(timeout: 5), "the progress chart shows")
    }

    func testSeededStatsShowHeatmapEffortAndBalance() {
        let app = launch(["-GFSeed", "6", "-GFTab", "stats"])
        XCTAssertTrue(app.descendants(matching: .any)["heatmap"].firstMatch.waitForExistence(timeout: 6), "the heatmap shows")
        tapWhenReady(app.buttons["Volume"])
        XCTAssertTrue(app.staticTexts["More volume"].waitForExistence(timeout: 3), "the heatmap reads volume")

        XCTAssertTrue(app.staticTexts["average effort"].firstMatch.exists || {
            reveal(app.staticTexts["average effort"].firstMatch, in: app)
            return app.staticTexts["average effort"].firstMatch.exists
        }(), "the effort card shows")

        let balance = app.buttons["stats.balance"]
        reveal(balance, in: app)
        tapWhenReady(balance)
        XCTAssertTrue(app.navigationBars["Structural balance"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Change exercise"].firstMatch.waitForExistence(timeout: 3))
    }

    func testExerciseDetailOpensProgressAndHasA1RMCalculator() {
        let app = launch(["-GFSeed", "4", "-GFTab", "exercises", "-GFDetail", "0031"])
        let estimate = app.descendants(matching: .any)["onerm.estimate"].firstMatch
        let progress = app.buttons["detail.progress"]
        reveal(progress, in: app)
        XCTAssertTrue(progress.waitForExistence(timeout: 3), "a logged exercise links to its progress")
        reveal(estimate, in: app)
        XCTAssertTrue(estimate.exists, "the 1RM calculator shows")
        XCTAssertTrue(estimate.label.contains("kg"), estimate.label)
        for _ in 0..<8 where !progress.isHittable { app.swipeDown() }
        progress.tap()
        XCTAssertTrue(chart(app).waitForExistence(timeout: 5), "the progress chart shows")
    }

    func testWorkoutHistorySheetHasTheCurve() {
        let app = launch(["-GFSeed", "3", "-GFTab", "today", "-GFStart", "0"])
        XCTAssertTrue(app.buttons["Mark set done"].firstMatch.waitForExistence(timeout: 6))
        // The exercise's own "More" menu, not the one in the navigation bar.
        let bar = app.navigationBars.buttons["More"].firstMatch
        let candidates = app.buttons.matching(identifier: "More").allElementsBoundByIndex
        let more = candidates.first { $0.isHittable && (!bar.exists || $0.frame != bar.frame) }
        XCTAssertNotNil(more, "the exercise's menu is there")
        more?.tap()
        tapWhenReady(app.buttons["History"])
        XCTAssertTrue(chart(app).waitForExistence(timeout: 5), "the history sheet draws the curve")
        XCTAssertTrue(app.buttons["Est. 1RM"].exists, "with the estimated 1RM to switch to")
    }
}
