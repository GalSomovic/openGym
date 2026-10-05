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
        for _ in 0..<5 where !setup.waitForExistence(timeout: 1.5) { app.swipeUp() }
        XCTAssertTrue(setup.waitForExistence(timeout: 5))
        setup.tap()
        let ok = app.buttons["healthNotice.ok"]
        XCTAssertTrue(ok.waitForExistence(timeout: 5))
        ok.tap()
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
        let enterLabel = app.buttons["food.enterLabel"]
        XCTAssertTrue(enterLabel.waitForExistence(timeout: 5))
        enterLabel.tap()
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

    /// Add food → search the bundled USDA list → pick → a portion sets the grams → edit → Add.
    func testSearchFoodDatabaseAndLog() {
        let app = XCUIApplication()
        app.launchArguments = ["-GFReset", "YES", "-GFStarter", "full-body", "-GFTab", "settings"]
        app.launch()
        let setup = app.buttons["nutrition.setup"]
        for _ in 0..<5 where !setup.waitForExistence(timeout: 1.5) { app.swipeUp() }
        XCTAssertTrue(setup.waitForExistence(timeout: 5))
        setup.tap()
        // The one-time health notice comes first on a fresh install.
        let ok = app.buttons["healthNotice.ok"]
        if ok.waitForExistence(timeout: 3) { ok.tap() }
        let save = app.buttons["nutrition.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        app.tabBars.buttons["Today"].tap()
        let card = app.staticTexts["Food today"]
        for _ in 0..<4 where !card.exists { app.swipeUp() }
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        app.buttons["food.add"].tap()
        let search = app.textFields["food.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("rice")
        let first = app.buttons.matching(identifier: "food.result").firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        // Everyday foods come first: plain cooked white rice, 130 kcal per 100 g (USDA SR Legacy)
        XCTAssertTrue(first.label.contains("Rice, white, long-grain, regular, enriched, cooked"), first.label)
        XCTAssertTrue(first.label.contains("130 kcal"), first.label)
        shot(app, "food-search")
        first.tap()

        // Values filled in from the database; a portion sets the grams: 1 cup = 158 g → 205 kcal
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "USDA average, per 100 g")).firstMatch.waitForExistence(timeout: 3))
        let cup = app.buttons.matching(identifier: "food.portion").firstMatch
        XCTAssertTrue(cup.waitForExistence(timeout: 3))
        XCTAssertTrue(cup.label.contains("1 cup = 158 g"), cup.label)
        cup.tap()
        let kcal = { (text: String) in app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch }
        XCTAssertTrue(kcal("205 kcal").waitForExistence(timeout: 3))
        shot(app, "food-picked")

        // Still editable: 200 g → 260 kcal
        let grams = app.textFields["food.grams"]
        grams.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        grams.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + "200")
        XCTAssertTrue(kcal("260 kcal").waitForExistence(timeout: 3))
        app.buttons["food.confirm"].tap()

        XCTAssertTrue(app.staticTexts["Rice, white, long-grain, regular, enriched, cooked"].waitForExistence(timeout: 3))
        XCTAssertTrue(kcal("260 kcal").exists)
        shot(app, "food-log-usda")

        // Picked again, it is a saved food now (shown first), not a copy.
        app.buttons["food.add"].tap()
        XCTAssertTrue(app.buttons.matching(identifier: "food.saved").firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "food.saved").count, 1)
    }
}
