import OpenGymCore
import SwiftUI

// Optional calories and food (GymFree addition): targets from apple/core/targets.js
// (NUTRITION.md §12), the food log from apple/core/nutrition.js. Off until the user sets it up
// in Settings; nothing here is in the way of training.

struct NutritionTargets: Decodable, Equatable {
    struct Gate: Decodable, Equatable { var level: String; var reason: String? }
    var gate: Gate
    var bmi: Double?
    var ree: Int?
    var tee: Int?
    var category: String?
    var goal: String?
    var rate: Double?
    var kgPerWeek: Double?
    var kcal: Int?
    var protein: Int?
    var fat: Int?
    var carbs: Int?
    var fibre: Int?
    var proteinInfo: Int?
    var notes: [String]?
}

struct FoodAmount: Decodable, Hashable { var kcal: Double; var p: Double; var f: Double; var c: Double }
struct FoodEntry: Decodable, Identifiable, Hashable { var id: String; var name: String; var grams: Double; var amount: FoodAmount }
struct FoodDay: Decodable { var iso: String; var entries: [FoodEntry]; var total: FoodAmount }
struct Per100: Decodable, Hashable { var kcal: Double; var p: Double; var f: Double; var c: Double }
struct SavedFood: Decodable, Identifiable, Hashable { var id: String; var name: String; var per100: Per100 }

extension GymStore {
    var nutritionTargets: NutritionTargets? { query("targets", "currentTargets", as: NutritionTargets?.self) ?? nil }
    var nutritionProfile: [String: JSONValue]? { query("targets", "profile", as: [String: JSONValue]?.self) ?? nil }
    func foodDay(_ iso: String) -> FoodDay? { query("nutrition", "dayFood", [iso], as: FoodDay.self) }
}

/* ------------------------------ setup ------------------------------ */

/// The questions behind the targets. Safety first: some answers mean no targets at all.
struct NutritionSetupView: View {
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var age = 30
    @State private var sex = "female"
    @State private var height = 170.0
    @State private var weight = 70.0
    @State private var job = "sitting"
    @State private var moderateMin = 90
    @State private var vigorousMin = 0
    @State private var steps = ""
    @State private var goal = "maintain"
    @State private var rate = 0.5
    @State private var experience = "novice"
    @State private var fatShare = 0.30
    @State private var pregnant = false
    @State private var breastfeeding = false
    @State private var eatingDisorder = false
    @State private var condition = false
    @State private var diabetesMeds = false
    @State private var kidney = false
    @State private var clinicianOk = false
    @State private var loaded = false

    private var lb: Bool { store.pick("unit", as: String.self) == "lb" }

    private var answers: [String: Any] {
        var a: [String: Any] = ["age": age, "sex": sex, "height": height, "weight": lb ? weight * 0.45359237 : weight,
                                "job": job, "moderateMin": moderateMin, "vigorousMin": vigorousMin, "goal": goal, "rate": rate,
                                "experience": experience, "fatShare": fatShare, "pregnant": pregnant, "breastfeeding": breastfeeding,
                                "eatingDisorder": eatingDisorder, "chronic": condition, "diabetesMeds": diabetesMeds,
                                "kidney": kidney, "clinicianOk": clinicianOk]
        if let s = Int(steps), s > 0 { a["steps"] = s }
        return a
    }

    private var preview: NutritionTargets? { store.query("targets", "computeTargets", [answers], as: NutritionTargets.self) }

    var body: some View {
        Form {
            Section {
                Text("Optional. A daily calorie target and a protein, fat and carb split from your answers, based on independent research. No meal plans, and you can turn it off any time.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section {
                Stepper("Age: \(age)", value: $age, in: 12...100)
                Picker("Equation", selection: $sex) {
                    Text("Female").tag("female")
                    Text("Male").tag("male")
                }
                LabeledContent("Height (cm)") { TextField("cm", value: $height, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                LabeledContent(lb ? "Weight (lb)" : "Weight (kg)") { TextField("", value: $weight, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
            } header: { Text("You") } footer: {
                Text("The energy equations were built separately for female and male bodies; pick the one that fits best. Weight updates from your weigh-ins.")
            }
            Section("Activity") {
                Picker("Work", selection: $job) {
                    Text("Mostly sitting").tag("sitting")
                    Text("On my feet most of the day").tag("feet")
                    Text("Heavy manual work").tag("manual")
                }
                Stepper("Moderate exercise: \(moderateMin) min/week", value: $moderateMin, in: 0...1200, step: 30)
                Stepper("Hard exercise: \(vigorousMin) min/week", value: $vigorousMin, in: 0...900, step: 30)
                TextField("Daily steps, if you know (optional)", text: $steps).keyboardType(.numberPad)
            }
            Section {
                Picker("Goal", selection: $goal) {
                    Text("Lose weight").tag("lose")
                    Text("Keep my weight").tag("maintain")
                    Text("Build muscle").tag("gain")
                }
                if goal == "lose" {
                    Picker("Pace", selection: $rate) {
                        Text("Gentle · 0.25% a week").tag(0.25)
                        Text("Steady · 0.5% a week").tag(0.5)
                        Text("Faster · 0.75% a week").tag(0.75)
                        Text("Fastest · 1% a week").tag(1.0)
                    }
                }
                if goal == "gain" {
                    Picker("Lifting experience", selection: $experience) {
                        Text("Under a year").tag("novice")
                        Text("1–3 years").tag("intermediate")
                        Text("More than 3 years").tag("advanced")
                    }
                }
                Picker("Split", selection: $fatShare) {
                    Text("Balanced").tag(0.30)
                    Text("Lower fat").tag(0.225)
                    Text("Lower carb").tag(0.40)
                }
            } header: { Text("Goal") } footer: {
                Text("Low-carb and low-fat work the same for weight when calories and protein match, so the split is your preference.")
            }
            Section {
                Toggle("Pregnant", isOn: $pregnant)
                Toggle("Breastfeeding", isOn: $breastfeeding)
                Toggle("I have, or have had, an eating disorder", isOn: $eatingDisorder)
                Toggle("Diabetes treated with insulin or sulfonylureas", isOn: $diabetesMeds)
                Toggle("Kidney disease", isOn: $kidney)
                Toggle("Another long-term condition, or a diet from my doctor", isOn: $condition)
                if breastfeeding || diabetesMeds || kidney || condition {
                    Toggle("My doctor is happy for me to follow a calorie target", isOn: $clinicianOk)
                }
            } header: { Text("Health check") } footer: {
                Text("Answers stay on this phone. This is general information, not medical advice.")
            }
            Section("Your targets") { TargetsSummary(targets: preview) }
        }
        .navigationTitle("Calories & food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.perform("targets", "saveProfile", [answers], as: NutritionTargets?.self)
                    dismiss()
                }
                .disabled(preview?.gate.level == "stop")
                .accessibilityIdentifier("nutrition.save")
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let w = store.query("targets", "latestWeightKg", as: Double?.self) ?? nil { weight = lb ? (w / 0.45359237).rounded() : w }
        guard let p = store.nutritionProfile else { return }
        age = Int(p["age"]?.number ?? Double(age)); sex = p["sex"]?.string ?? sex
        height = p["height"]?.number ?? height; job = p["job"]?.string ?? job
        moderateMin = Int(p["moderateMin"]?.number ?? Double(moderateMin)); vigorousMin = Int(p["vigorousMin"]?.number ?? 0)
        goal = p["goal"]?.string ?? goal; rate = p["rate"]?.number ?? rate; experience = p["experience"]?.string ?? experience
        fatShare = p["fatShare"]?.number ?? fatShare
        for (key, binding) in [("pregnant", $pregnant), ("breastfeeding", $breastfeeding), ("eatingDisorder", $eatingDisorder),
                               ("diabetesMeds", $diabetesMeds), ("kidney", $kidney), ("chronic", $condition), ("clinicianOk", $clinicianOk)] {
            binding.wrappedValue = p[key]?.bool ?? false
        }
        if let s = p["steps"]?.number { steps = String(Int(s)) }
    }
}

/// The target, or why there is none.
struct TargetsSummary: View {
    let targets: NutritionTargets?

    var body: some View {
        if let t = targets {
            if t.gate.level == "stop" {
                Text(Self.stopText(t.gate.reason)).font(.subheadline)
            } else if let kcal = t.kcal {
                LabeledContent("Calories", value: "\(kcal.formatted()) kcal a day")
                if let p = t.protein { LabeledContent("Protein", value: "\(p) g") }
                if let info = t.proteinInfo { LabeledContent("Protein (for information)", value: "about \(info) g") }
                LabeledContent("Fat", value: "\(t.fat ?? 0) g")
                LabeledContent("Carbs", value: "\(t.carbs ?? 0) g")
                LabeledContent("Fibre, at least", value: "\(t.fibre ?? 25) g")
                if let kg = t.kgPerWeek, kg > 0 {
                    Text(t.goal == "lose"
                         ? "About \(kg.formatted(.number.precision(.fractionLength(0...2)))) kg a week. A realistic aim is 5–10% of your weight over six months."
                         : "About \(kg.formatted(.number.precision(.fractionLength(0...2)))) kg a week; strength rises faster than size.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(t.notes ?? [], id: \.self) { n in
                    if let text = Self.noteText(n) { Text(text).font(.footnote).foregroundStyle(.secondary) }
                }
            }
        }
    }

    static func stopText(_ reason: String?) -> String {
        switch reason {
        case "age": String(localized: "Calorie targets aren't designed for under-18s. Training, sleep and regular meals matter most at your age. A doctor can help if you're worried about your weight.")
        case "pregnant": String(localized: "During pregnancy, energy needs change in ways a calculator can't follow. Your midwife or doctor can advise you; training features stay available.")
        case "ed": String(localized: "Calorie targets and food logging can make an eating disorder harder, so GymFree doesn't show them. If you'd like support, your doctor or a local eating-disorder helpline can help.")
        case "underweight": String(localized: "Your weight is already in the underweight range, so GymFree won't set a weight-loss target. A doctor can help if you're unsure what's right for you.")
        default: String(localized: "No targets for these answers.")
        }
    }

    static func noteText(_ n: String) -> String? {
        switch n {
        case "clinician": String(localized: "Showing maintenance only until your doctor is happy for you to follow a target.")
        case "floor": String(localized: "This is the lowest target GymFree sets; a slower pace is the safe option here.")
        case "rateCapped": String(localized: "The pace is limited to keep it safe for your body size and age.")
        case "recomp": String(localized: "Tip: at your body size, training while eating around maintenance can build muscle and lose fat at once.")
        case "kidneyProtein": String(localized: "With kidney disease, protein is best set with your doctor.")
        default: nil
        }
    }
}

/* ------------------------------ the food log ------------------------------ */

/// One day of food against the target. Weekly averages matter more than any single day.
struct FoodLogView: View {
    @Environment(GymStore.self) private var store
    @State private var iso = Self.todayISO
    @State private var adding = false
    @State private var weekly: String?

    static var todayISO: String { ISO8601DateFormatter.day.string(from: Date()) }

    var body: some View {
        let day = store.foodDay(iso)
        let t = store.nutritionTargets
        List {
            Section {
                HStack {
                    Button { shift(-1) } label: { Image(systemName: "chevron.backward") }.buttonStyle(.borderless)
                    Spacer()
                    Text(iso == Self.todayISO ? String(localized: "Today") : Self.label(iso)).font(.headline)
                    Spacer()
                    Button { shift(1) } label: { Image(systemName: "chevron.forward") }.buttonStyle(.borderless)
                        .disabled(iso >= Self.todayISO)
                }
                MacroBar(label: "Calories", value: day?.total.kcal ?? 0, target: Double(t?.kcal ?? 0), unit: "kcal")
                if let p = t?.protein { MacroBar(label: "Protein", value: day?.total.p ?? 0, target: Double(p), unit: "g") }
                MacroBar(label: "Fat", value: day?.total.f ?? 0, target: Double(t?.fat ?? 0), unit: "g")
                MacroBar(label: "Carbs", value: day?.total.c ?? 0, target: Double(t?.carbs ?? 0), unit: "g")
            }
            if let weekly { Section { Text(weekly).font(.footnote).foregroundStyle(.secondary) } }
            Section {
                ForEach(day?.entries ?? []) { e in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.name)
                            Text("\(Int(e.grams)) g · \(Int(e.amount.p)) g protein").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(e.amount.kcal.rounded())) kcal").foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            store.perform("nutrition", "removeEntry", [iso, e.id], as: FoodDay.self)
                        }
                    }
                }
                Button { adding = true } label: { Label("Add food", systemImage: "plus") }
                    .accessibilityIdentifier("food.add")
            }
            Section {
                Toggle("I've logged everything today", isOn: Binding(
                    get: { store.pick("gfFoodDone", as: [String: Bool].self)?[iso] == true },
                    set: { store.perform("targets", "setDayComplete", [iso, $0], as: Bool.self) }))
            } footer: {
                Text("Complete days let GymFree tune your target to your real weight trend each week.")
            }
        }
        .navigationTitle("Food")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink { NutritionSetupView() } label: { Image(systemName: "slider.horizontal.3") }
                    .accessibilityLabel(Text("Targets"))
            }
        }
        .sheet(isPresented: $adding) { AddFoodSheet(iso: iso) }
        .onAppear(perform: runWeekly)
    }

    private func shift(_ d: Int) {
        guard let date = ISO8601DateFormatter.day.date(from: iso),
              let next = Calendar.current.date(byAdding: .day, value: d, to: date) else { return }
        iso = min(ISO8601DateFormatter.day.string(from: next), Self.todayISO)
    }

    private func runWeekly() {
        struct R: Decodable { var ok: Bool; var reason: String?; var tee: Int? }
        guard let r = store.perform("targets", "weeklyCheck", [Self.todayISO], as: R?.self) ?? nil else { return }
        if r.ok, let tee = r.tee {
            weekly = String(localized: "Weekly check: from your weigh-ins and logs, your daily energy use looks like about \(tee.formatted()) kcal; your target has been adjusted.")
        } else if r.reason == "implausible" {
            weekly = String(localized: "Weekly check skipped: the numbers don't add up yet. Weighing at the same time each day and logging whole days helps.")
        }
    }

    static func label(_ iso: String) -> String {
        guard let d = ISO8601DateFormatter.day.date(from: iso) else { return iso }
        return d.formatted(.dateTime.weekday(.wide).day().month())
    }
}

private struct MacroBar: View {
    let label: LocalizedStringKey
    let value: Double
    let target: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(target > 0 ? "\(Int(value.rounded())) / \(Int(target)) \(unit)" : "\(Int(value.rounded())) \(unit)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            if target > 0 { ProgressView(value: min(value, target), total: target) }
        }
    }
}

/// Adds what was eaten: a saved food, a food from the bundled USDA database, or a label typed
/// once (per 100 g), and the grams eaten. All the math is apple/core/nutrition.js.
struct AddFoodSheet: View {
    let iso: String
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [USDAFood] = []
    @State private var usda: USDAFood?          // the database food the values came from
    @State private var labelMode = false        // typing a label (or editing a database food)
    @State private var name = ""
    @State private var kcal: Double?
    @State private var protein: Double?
    @State private var fat: Double?
    @State private var carbs: Double?
    @State private var fiber: Double?
    @State private var grams: Double?
    @State private var save = true
    @State private var picked: SavedFood?
    @FocusState private var searchFocused: Bool

    private var editing: Bool { labelMode || usda != nil }

    private var per100: [String: Any] {
        var d: [String: Any] = ["p": protein ?? 0, "f": fat ?? 0, "c": carbs ?? 0]
        if let kcal { d["kcal"] = kcal }
        if let fiber { d["fiber"] = fiber }
        return d
    }
    /// The database food, unless its values were edited (then it is the user's own label).
    private var source: String? {
        guard let u = usda, kcal == u.kcal, protein == u.p, fat == u.f, carbs == u.c, (fiber ?? 0) == u.fiber else { return nil }
        return u.source
    }
    private var amount: FoodAmount? {
        guard let g = grams, g > 0 else { return nil }
        return store.query("nutrition", "nutrientsFor", [picked.map { ["kcal": $0.per100.kcal, "p": $0.per100.p, "f": $0.per100.f, "c": $0.per100.c] } ?? per100, g], as: FoodAmount.self)
    }

    var body: some View {
        NavigationStack {
            Form {
                let saved = store.query("nutrition", "savedFoods", as: [SavedFood].self) ?? []
                if picked == nil && !editing {
                    searchSection(saved: saved)
                } else if let food = picked {
                    Section("Saved food") {
                        LabeledContent(food.name, value: "\(Int(food.per100.kcal.rounded())) kcal / 100 g")
                        Button("Choose another food") { picked = nil; grams = nil }
                    }
                } else if usda != nil {
                    // A database pick: how much first (portions), then the values, still editable.
                    amountSection
                    labelSection
                } else {
                    labelSection
                }
                if picked != nil || labelMode {
                    amountSection
                }
            }
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled((grams ?? 0) <= 0 || (picked == nil && name.trimmingCharacters(in: .whitespaces).isEmpty))
                        .accessibilityIdentifier("food.confirm")
                }
            }
            .task(id: query) {
                let q = query
                let found = await Task.detached(priority: .userInitiated) { FoodDatabase.shared.search(q) }.value
                if !Task.isCancelled { results = found }
            }
        }
    }

    /* --------------------------- search and pick --------------------------- */

    @ViewBuilder private func searchSection(saved: [SavedFood]) -> some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search foods", text: $query)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused($searchFocused)
                    .accessibilityIdentifier("food.search")
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text("Clear"))
                }
            }
        }
        let q = query.trimmingCharacters(in: .whitespaces)
        let savedMatches = q.isEmpty ? saved : saved.filter { FoodDatabase.fold($0.name).contains(FoodDatabase.fold(q)) }
        if !savedMatches.isEmpty {
            Section("Saved foods") {
                ForEach(savedMatches) { food in
                    Button { picked = food; searchFocused = false } label: {
                        FoodResultRow(name: food.name, kcal: food.per100.kcal, protein: food.per100.p)
                    }
                    .accessibilityIdentifier("food.saved")
                }
            }
        }
        if !q.isEmpty {
            Section {
                if results.isEmpty {
                    Text("No matches in the food list.").foregroundStyle(.secondary)
                }
                ForEach(results) { food in
                    Button { pick(food) } label: {
                        FoodResultRow(name: food.name, kcal: food.kcal, protein: food.p)
                    }
                    .accessibilityIdentifier("food.result")
                }
            } header: { Text("Foods") } footer: {
                Text("Average values per 100 g from USDA FoodData Central. A product's own label may differ.")
            }
        }
        Section {
            Button { startLabel() } label: { Label("Enter a label instead", systemImage: "square.and.pencil") }
                .accessibilityIdentifier("food.enterLabel")
        }
    }

    private func pick(_ food: USDAFood) {
        usda = food
        name = food.name
        kcal = food.kcal; protein = food.p; fat = food.f; carbs = food.c; fiber = food.fiber
        grams = food.portions.first?.grams ?? 100
        searchFocused = false
    }

    private func startLabel() {
        usda = nil
        name = query.trimmingCharacters(in: .whitespaces)
        kcal = nil; protein = nil; fat = nil; carbs = nil; fiber = nil
        labelMode = true
        searchFocused = false
    }

    private func backToSearch() {
        usda = nil; labelMode = false; grams = nil
    }

    /* ------------------------------ values ------------------------------ */

    @ViewBuilder private var labelSection: some View {
        Section {
            TextField("Name", text: $name).accessibilityIdentifier("food.name")
            field("Calories (optional)", $kcal, "kcal", id: "kcal")
            field("Protein", $protein, "g", id: "protein")
            field("Fat", $fat, "g", id: "fat")
            field("Carbs", $carbs, "g", id: "carbs")
            field("Fibre (optional)", $fiber, "g", id: "fiber")
            Toggle("Save this food", isOn: $save)
            Button(usda != nil ? "Search for another food" : "Search foods instead") { backToSearch() }
        } header: {
            Text(usda != nil ? "USDA average, per 100 g" : "From the label, per 100 g")
        } footer: {
            if usda != nil {
                Text("Values from USDA FoodData Central are averages; your food's label may differ, so edit any number. Weigh it the way it's described (raw or cooked). Carbs don't include fibre, as on EU labels; US labels count fibre in carbs.")
            } else {
                Text("Leave calories empty to work them out from protein, fat and carbs. Labels can be off by about 20%, so round numbers are fine. On US labels, take fibre away from total carbs.")
            }
        }
    }

    @ViewBuilder private var amountSection: some View {
        Section {
            if let portions = usda?.portions, !portions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(portions, id: \.self) { p in
                            Button { grams = p.grams } label: {
                                Text("\(p.label) = \(fmt(p.grams)) g")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .foregroundStyle(grams == p.grams ? Color.black : Color.primary)
                                    .background(grams == p.grams ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary.opacity(0.7)), in: .capsule)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("food.portion")
                        }
                    }
                }
                .scrollClipDisabled()
            }
            field("Amount eaten", $grams, "g", id: "grams")
            if let a = amount {
                LabeledContent("That's", value: "\(Int(a.kcal.rounded())) kcal")
                LabeledContent("Protein · fat · carbs", value: "\(fmt(a.p)) · \(fmt(a.f)) · \(fmt(a.c)) g")
            }
        }
    }

    private func field(_ title: LocalizedStringKey, _ value: Binding<Double?>, _ unit: String, id: String) -> some View {
        LabeledContent(title) {
            HStack(spacing: 4) {
                TextField("0", value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("food.\(id)")
                Text(unit).foregroundStyle(.secondary)
            }
        }
    }

    private func fmt(_ x: Double) -> String { x.formatted(.number.precision(.fractionLength(0...1))) }

    private func add() {
        var spec: [String: Any] = picked.map { ["foodId": $0.id, "grams": grams ?? 0] }
            ?? ["name": name, "per100": per100, "grams": grams ?? 0, "save": save]
        if picked == nil, let source { spec["src"] = source }
        store.perform("nutrition", "logFood", [iso, spec], as: FoodDay.self)
        dismiss()
    }
}

/// Today's food at a glance, on the Today tab (only once calories & food are set up).
struct FoodTodayCard: View {
    @Environment(GymStore.self) private var store

    var body: some View {
        if let t = store.nutritionTargets, let kcal = t.kcal {
            let day = store.foodDay(FoodLogView.todayISO)
            NavigationLink { FoodLogView() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife").foregroundStyle(.tint).frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Food today")
                        Text("\(Int((day?.total.kcal ?? 0).rounded())) / \(kcal.formatted()) kcal" + (t.protein.map { " · \(Int((day?.total.p ?? 0).rounded())) / \($0) g protein" } ?? ""))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// Settings entry: set up, open the log, or turn the feature off.
struct NutritionSettingsRow: View {
    @Environment(GymStore.self) private var store

    var body: some View {
        if store.nutritionTargets != nil || store.nutritionProfile?["enabled"]?.bool == true {
            NavigationLink { FoodLogView() } label: { Label("Calories & food", systemImage: "fork.knife") }
            Button("Turn off calories & food", role: .destructive) {
                store.perform("targets", "disable", as: Bool.self)
            }
        } else {
            NavigationLink { NutritionSetupView() } label: { Label("Calories & food (optional)", systemImage: "fork.knife") }
                .accessibilityIdentifier("nutrition.setup")
        }
    }
}

extension ISO8601DateFormatter {
    /// yyyy-MM-dd in the current time zone, as openGym keys days.
    nonisolated(unsafe) static let day: ISO8601DateFormatter = {   // formatting is thread-safe
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        f.timeZone = .current
        return f
    }()
}
