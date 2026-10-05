import XCTest

final class NutritionFlowTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name; a.lifetime = .keepAlways
        add(a)
    }

    func testSetUpTargetsThenLogAFood() {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body", "-GFTab", "settings"]
        app.launch()
        let setup = app.buttons["nutrition.setup"]
        if !setup.waitForExistence(timeout: 5) { app.swipeUp() }
        XCTAssertTrue(setup.waitForExistence(timeout: 5))
        setup.tap()
        let save = app.buttons["nutrition.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        shot(app, "setup-top")
        app.swipeUp(); app.swipeUp(); app.swipeUp()
        shot(app, "setup-bottom")
        save.tap()

        app.tabBars.buttons["Today"].tap()
        let card = app.staticTexts["Food today"]
        for _ in 0..<4 where !card.exists { app.swipeUp() }
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        app.buttons["food.add"].tap()
        let name = app.textFields["food.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Rice")
        let protein = app.textFields["food.protein"]; protein.tap(); protein.typeText("20")
        let fat = app.textFields["food.fat"]; fat.tap(); fat.typeText("10")
        let carbs = app.textFields["food.carbs"]; carbs.tap(); carbs.typeText("30")
        let grams = app.textFields["food.grams"]; grams.tap(); grams.typeText("1000")
        // 1 kg at 20 / 10 / 30 g per 100 g: 2,900 kcal
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "900 kcal", "900 kcal")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["food.confirm"].tap()
        XCTAssertTrue(app.staticTexts["Rice"].waitForExistence(timeout: 3))
        shot(app, "food-log")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "900 kcal", "900 kcal")).firstMatch.exists)
    }
}
