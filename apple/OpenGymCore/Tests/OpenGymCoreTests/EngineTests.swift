import Testing
@testable import OpenGymCore

/// Proves the bridge: these are openGym's own functions, called from Swift.
struct EngineTests {
    @Test func engineLoads() {
        #expect(Engine.shared.isLoaded)
    }

    @Test func estimatedOneRepMax() throws {
        // Epley: 100 kg × 5 reps ≈ 116.7 kg; openGym's default formula.
        let e1rm: Double = try Engine.shared.call("onerm", "estimate1RM", [100, 5])
        #expect(e1rm > 110 && e1rm < 120)
    }

    @Test func catalogueIsAvailable() throws {
        let parts: [String] = try Engine.shared.value("exercises", "BODYPARTS")
        #expect(parts.contains("chest"))
        let count: Int = try Engine.shared.call("exercises", "allExercises", [["customEx": [Any]()]], as: [Exercise].self).count
        #expect(count > 1000)
    }

    @Test func plateMath() throws {
        let sizes: [String: [Double]] = try Engine.shared.value("plates", "PLATE_SIZES")
        #expect(sizes["kg"]?.contains(20) == true)
    }
}

struct Exercise: Decodable { let id: String; let n: String }
