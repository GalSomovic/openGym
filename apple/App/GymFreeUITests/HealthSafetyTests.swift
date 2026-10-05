import XCTest

/// Settings → About → Health & safety: the health notice, helplines and privacy policy.
final class HealthSafetyTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func openHealthSafety(region: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFTab", "settings", "-AppleLocale", region]
        app.launch()
        let about = app.buttons["settings.about"]
        for _ in 0..<4 where !about.exists { app.swipeUp() }
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        about.tap()
        let health = app.buttons["about.healthSafety"]
        XCTAssertTrue(health.waitForExistence(timeout: 5))
        health.tap()
        return app
    }

    func testHealthAndSafetyShowsTheLocalHelplineFirst() {
        let app = openHealthSafety(region: "en_GB")
        XCTAssertTrue(app.staticTexts["Beat"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Call Beat, 0808 801 0677"].exists)
        // The UK line comes before every other country's.
        let beat = app.staticTexts["Beat"].frame.minY
        let other = app.staticTexts["ANAD Helpline"]
        if other.exists { XCTAssertLessThan(beat, other.frame.minY) }

        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "health-safety"; a.lifetime = .keepAlways; add(a)
    }

    func testOtherRegionsAndThePrivacyPolicy() {
        let app = openHealthSafety(region: "en_US")
        XCTAssertTrue(app.staticTexts["ANAD Helpline"].waitForExistence(timeout: 5))
        let privacy = app.buttons["healthSafety.privacy"]
        for _ in 0..<12 where !(privacy.exists && privacy.isHittable) { app.swipeUp() }
        privacy.tap()
        XCTAssertTrue(app.staticTexts["GymFree Privacy Policy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The short version"].exists)
    }

    func testCaloriesSetupLinksToSupport() {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFTab", "settings", "-AppleLocale", "en_GB"]
        app.launch()
        let setup = app.buttons["nutrition.setup"]
        for _ in 0..<3 where !setup.exists { app.swipeUp() }
        setup.tap()
        // The one-time health notice comes first.
        let ok = app.buttons["healthNotice.ok"]
        XCTAssertTrue(ok.waitForExistence(timeout: 5))
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "health-notice"; a.lifetime = .keepAlways; add(a)
        ok.tap()

        let ed = app.switches["I have, or have had, an eating disorder"]
        for _ in 0..<6 where !(ed.exists && ed.isHittable) { app.swipeUp() }
        ed.switches.firstMatch.tap()
        let support = app.buttons["nutrition.edSupport"]
        for _ in 0..<4 where !(support.exists && support.isHittable) { app.swipeUp() }
        let b = XCTAttachment(screenshot: app.screenshot()); b.name = "ed-stop"; b.lifetime = .keepAlways; add(b)
        support.tap()
        XCTAssertTrue(app.staticTexts["Beat"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        let footer = app.buttons["nutrition.support"]
        for _ in 0..<4 where !(footer.exists && footer.isHittable) { app.swipeDown() }
        footer.tap()
        XCTAssertTrue(app.staticTexts["Beat"].waitForExistence(timeout: 5))
    }
}
