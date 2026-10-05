import XCTest

/// GPS walks on a scripted route (-GFFakeRoute: no GPS, no location prompt) with Apple Health
/// kept out of it (-GFNoHealth: its permission sheet cannot be driven by a test).
@MainActor
final class MotionFlowTests: XCTestCase {
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFTab", "today", "-GFFakeRoute", "YES", "-GFNoHealth", "YES"] + extra
        app.launch()
        return app
    }

    private func tapWhenReady(_ element: XCUIElement, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(element) missing", file: file, line: line)
        for _ in 0..<20 where !element.isHittable { usleep(150_000) }
        element.tap()
    }

    /// The distance on the live screen, in km.
    private func distance(_ app: XCUIApplication) -> Double {
        Double(app.staticTexts["activity.distance"].label.replacingOccurrences(of: ",", with: ".")) ?? -1
    }

    func testWalkIsTrackedSavedAndShownInHistoryWithItsRoute() {
        let app = launch()
        let entry = app.buttons["today.activity"]
        for _ in 0..<6 where !(entry.exists && entry.isHittable) { app.swipeUp() }
        tapWhenReady(entry)

        // The last kind is remembered; this one is a walk.
        tapWhenReady(app.buttons["Walk"].firstMatch)
        tapWhenReady(app.buttons["activity.start"])
        XCTAssertTrue(app.staticTexts["activity.distance"].waitForExistence(timeout: 3))
        // The scripted route walks about 16 m every real second (five scripted seconds per half second).
        for _ in 0..<20 where distance(app) < 0.03 { sleep(1) }
        XCTAssertGreaterThanOrEqual(distance(app), 0.03, "the distance grows")

        // Paused, the distance stands still.
        tapWhenReady(app.buttons["activity.pause"])
        let paused = distance(app)
        sleep(2)
        XCTAssertEqual(distance(app), paused, accuracy: 0.001)
        tapWhenReady(app.buttons["activity.resume"])
        sleep(1)

        tapWhenReady(app.buttons["activity.finish"])
        tapWhenReady(app.buttons["activity.save"].firstMatch)
        XCTAssertTrue(app.staticTexts["activity.saved"].waitForExistence(timeout: 5), "the summary shows")
        XCTAssertTrue(app.descendants(matching: .any)["route.map"].exists, "with the route")
        tapWhenReady(app.buttons["activity.done"])

        tapWhenReady(app.buttons["today.history"])
        tapWhenReady(app.staticTexts["Walk"].firstMatch)
        XCTAssertTrue(app.descendants(matching: .any)["route.map"].waitForExistence(timeout: 5), "the detail draws the route")
        XCTAssertTrue(app.descendants(matching: .any)["detail.distance"].exists)
        XCTAssertFalse(app.buttons["Edit workout"].exists, "a measured activity is not edited like sets")
    }

    func testClosingKeepsTrackingAndDiscardSavesNothing() {
        let app = launch(["-GFActivity", "run", "-GFActivityGo", "YES"])
        XCTAssertTrue(app.buttons["activity.pause"].waitForExistence(timeout: 5))
        tapWhenReady(app.buttons["activity.close"])
        let banner = app.buttons["today.activityInProgress"]
        XCTAssertTrue(banner.waitForExistence(timeout: 3), "Today shows the run in progress")
        banner.tap()
        tapWhenReady(app.buttons["activity.discard"])
        tapWhenReady(app.buttons["Discard"].firstMatch)
        XCTAssertTrue(app.buttons["today.history"].waitForExistence(timeout: 3))
        XCTAssertFalse(banner.exists)
        XCTAssertTrue(app.staticTexts["0 workouts"].exists, "nothing was saved")
    }

    func testAppleHealthIsOffUntilTurnedOn() {
        let app = XCUIApplication()
        app.launchArguments = ["-GFTab", "settings", "-GFNoHealth", "YES"]
        app.launch()
        let row = app.buttons["settings.health"]
        for _ in 0..<6 where !(row.exists && row.isHittable) { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
        let toggle = app.switches["health.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "0", "nothing is asked of Health until the user turns it on")
    }
}
