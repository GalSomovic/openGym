import XCTest

/// Settings → About → Licences & credits, Open-source licences and the full licence texts.
final class LicencesTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func openAbout() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFTab", "settings", "-AppleLocale", "en_US"]
        app.launch()
        let about = app.buttons["settings.about"]
        for _ in 0..<4 where !about.exists { app.swipeUp() }
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        about.tap()
        return app
    }

    /// Scrolls down until the element is on screen.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, swipes: Int = 20) -> XCUIElement {
        for _ in 0..<swipes where !(element.exists && element.isHittable) { app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout: 3), "\(element) not found")
        return element
    }

    func testLicencesAndCreditsListsEverySourceAndOpensTheAGPL() {
        let app = openAbout()
        let licences = reveal(app.buttons["about.licences"], in: app, swipes: 4)
        licences.tap()

        // DVIDS: public domain, with the no-endorsement disclaimer it requires, word for word.
        XCTAssertTrue(app.staticTexts["licences.dvids.licence"].waitForExistence(timeout: 5))
        let quote = reveal(app.staticTexts["licences.dvids.quote"], in: app)
        XCTAssertTrue(quote.label.contains("does not imply or constitute DoW endorsement"))
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "licences"; a.lifetime = .keepAlways; add(a)

        // wger items say they were modified (CC BY-SA asks for changes to be indicated).
        reveal(app.buttons["licences.wger.items"], in: app).tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'modified'")).firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        // ExerciseDB: non-commercial terms with credit.
        let exercisedb = reveal(app.staticTexts["licences.exercisedb.licence"], in: app)
        XCTAssertTrue(exercisedb.label.contains("non-commercial"))

        // GymFree itself: the AGPL, with its full text in the app.
        let agpl = reveal(app.staticTexts["licences.gymfree.licence"], in: app)
        XCTAssertTrue(agpl.label.contains("Affero"))
        reveal(app.buttons["licences.gymfree.text"], in: app).tap()
        let text = app.staticTexts["licence.text"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertTrue(text.label.contains("GNU AFFERO GENERAL PUBLIC LICENSE"))
    }

    func testOpenSourceLicencesShowTheAGPLNoticeAndFullTexts() {
        let app = openAbout()
        reveal(app.buttons["about.openSource"], in: app, swipes: 4).tap()
        let notice = app.staticTexts["openSource.agplNotice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertTrue(notice.label.contains("WITHOUT ANY WARRANTY"))
        app.buttons["openSource.agpl"].tap()
        let text = app.staticTexts["licence.text"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertTrue(text.label.contains("Version 3, 19 November 2007"))
        app.navigationBars.buttons.firstMatch.tap()

        // Lottie's Apache licence.
        let lottie = reveal(app.staticTexts["Copyright 2018 Airbnb, Inc."].firstMatch, in: app)
        XCTAssertTrue(lottie.exists)
    }
}
