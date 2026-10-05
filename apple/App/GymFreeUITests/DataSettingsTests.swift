import XCTest

/// Settings → Data and the openGym settings, on a fresh profile with a starter plan loaded.
final class DataSettingsTests: XCTestCase {
    private func launch(_ extra: [String] = [], env: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body", "-GFTab", "settings"] + extra
        app.launchEnvironment = env
        app.launch()
        return app
    }

    private func openData(_ app: XCUIApplication) {
        // The list is lazy: Data is further down than the first screen.
        let data = app.buttons["Data"]
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        for _ in 0..<6 where !(data.exists && data.isHittable) { app.swipeUp() }
        data.tap()
        XCTAssertTrue(app.navigationBars["Data"].waitForExistence(timeout: 3))
    }

    private func ok(_ app: XCUIApplication, _ title: String) {
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "shows “\(title)”")
        app.buttons["OK"].tap()
    }

    func testExportResetImportRoundTrip() {
        let app = launch(["-GFBackupFile", "YES"])
        openData(app)
        app.buttons["Export backup"].tap()
        ok(app, "Backup exported")

        // Reset asks twice.
        app.buttons["Reset everything"].tap()
        app.buttons["Delete everything"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Are you sure?"].waitForExistence(timeout: 3))
        app.alerts.buttons["Delete everything"].tap()
        ok(app, "All data reset")

        app.tabBars.buttons["Plan"].tap()
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Full Body A'")).firstMatch.waitForExistence(timeout: 2),
                       "the plan is gone after a reset")

        app.tabBars.buttons["Settings"].tap()
        app.buttons["Import backup"].tap()
        XCTAssertTrue(app.staticTexts["Import backup?"].waitForExistence(timeout: 3))
        app.buttons["Import"].firstMatch.tap()
        ok(app, "Backup imported")

        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Full Body A'")).firstMatch.waitForExistence(timeout: 3)
                      || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Full Body A'")).firstMatch.exists,
                      "the backup brings the plan back")
    }

    func testImportFromAnotherAppShowsASummaryFirst() {
        let csv = """
        Date,Exercise,Category,Weight (kg),Reps
        2026-03-02,Flat Barbell Bench Press,Chest,60,5
        2026-03-02,Zorb Roller,Abs,10,12
        2026-03-05,Barbell Squat,Legs,80,5
        """
        let app = launch(env: ["GFImportText": csv])
        openData(app)
        app.buttons["Import from another app"].tap()
        XCTAssertTrue(app.navigationBars["Import from FitNotes"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Zorb Roller"].exists, "unknown exercises are listed")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "import-summary"; shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Import"].tap()
        ok(app, "2 workouts imported")
    }

    func testSwitchingTheUnitOffersToConvert() {
        let app = launch()
        let unit = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Weight unit'")).firstMatch
        XCTAssertTrue(unit.waitForExistence(timeout: 5))
        unit.tap()
        app.buttons["lb"].firstMatch.tap()
        let convert = app.buttons["Convert the numbers"]
        XCTAssertTrue(convert.waitForExistence(timeout: 3))
        convert.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'lb'")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'mph'")).firstMatch.exists,
                      "speed follows the weight unit until chosen")
    }
}
