import OpenGymCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// openGym's "Share your plan": send routines to a friend, print the week, or import a friend's.
struct PlanShareSheet: View {
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var preview: Preview?
    @State private var useSchedule = false
    @State private var error: String?

    struct Preview: Decodable, Identifiable {
        var name: String; var routineCount: Int; var exerciseCount: Int; var scheduledDays: Int; var dropped: Int
        var id: String { name + "\(routineCount)" }
    }

    private var hasRoutines: Bool { store.routines.contains { !$0.ex.isEmpty } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let exportURL {
                        ShareLink(item: exportURL) { Label("Send plan file", systemImage: "square.and.arrow.up") }
                    }
                    Button { printPlan() } label: { Label("Print or save as PDF", systemImage: "printer") }
                        .disabled(!hasRoutines)
                } header: { Text("Share your plan") } footer: {
                    Text(hasRoutines
                         ? "The file has your routines only, none of your workouts or weigh-ins. A friend imports it into GymFree or openGym."
                         : "Add an exercise to a routine first; an empty plan has nothing to share.")
                }
                Section {
                    Button { importing = true } label: { Label("Import a plan file", systemImage: "square.and.arrow.down") }
                } header: { Text("Got a plan from a friend?") } footer: {
                    Text("Its routines are added as new ones; nothing you already have changes.")
                }
                if let error { Section { Text(error).foregroundStyle(.red).font(.footnote) } }
            }
            .navigationTitle("Share plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear(perform: makeFile)
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                guard case .success(let url) = result else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { error = String(localized: "Couldn't read that file."); return }
                if let p = store.query("share", "previewPlan", [text], as: Preview.self) { preview = p; error = nil }
                else { error = String(localized: "That isn't a plan file.") }
            }
            .sheet(item: $preview) { p in importSheet(p) }
        }
    }

    private func importSheet(_ p: Preview) -> some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(p.routineCount) routines · \(p.exerciseCount) exercises")
                    if p.dropped > 0 {
                        Text("\(p.dropped) exercises in the file aren't in your library and were left out.").foregroundStyle(.orange)
                    }
                    if p.scheduledDays > 0 {
                        Toggle("Use its weekly schedule", isOn: $useSchedule)
                    }
                } footer: {
                    Text(p.scheduledDays > 0 && useSchedule ? "Replaces your current Monday–Sunday assignments." : "Added as new routines.")
                }
            }
            .navigationTitle(p.name.isEmpty ? String(localized: "Import this plan") : String(localized: "Import “\(p.name)”"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { preview = nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to my plan") {
                        store.perform("share", "importPlan", [useSchedule], as: Bool.self)
                        preview = nil
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func makeFile() {
        guard let json = store.query("share", "exportPlan", [""], as: String?.self) ?? nil else { return }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gymfree-plan-\(df.string(from: Date())).json")
        try? Data(json.utf8).write(to: url)
        exportURL = url
    }

    private func printPlan() {
        guard let html = store.query("share", "printHTML", [""], as: String.self) else { return }
        let info = UIPrintInfo.printInfo()
        info.jobName = String(localized: "Weekly training plan")
        info.outputType = .general
        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        controller.present(animated: true)
    }
}
