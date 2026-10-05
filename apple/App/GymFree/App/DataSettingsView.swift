import OpenGymCore
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Data (openGym's Data section): back up and restore the whole profile as an
/// openGym backup, bring in another app's history, or start over. Everything stays on the
/// device; the files go where you put them.
struct DataSettingsView: View {
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session

    private enum Picking { case backup, otherApp }

    @State private var exportDoc: BackupDocument?
    @State private var picking = false
    @State private var pickKind = Picking.backup
    @State private var backupAsk: (json: String, info: BackupInfo)?
    @State private var preview: ImportPreview?
    @State private var resetAsk = false
    @State private var resetSure = false
    @State private var reading = false
    @State private var message: String?

    var body: some View {
        List {
            Section {
                Button { importFromAnotherApp() } label: {
                    Label("Import from another app", systemImage: "arrow.left.arrow.right")
                }
            } footer: {
                Text("FitNotes, Strong, Hevy or any CSV with a date, exercise, weight and reps — or body weight from Apple Health (unzip export.zip in Files and pick export.xml). Days you already logged are left alone.")
            }
            Section {
                Button { exportBackup() } label: {
                    Label("Export backup", systemImage: "square.and.arrow.up")
                }
                Button { importBackup() } label: {
                    Label("Import backup", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("A backup is one JSON file with your plan, workouts, body weight and settings. openGym reads it too, and GymFree reads openGym’s.")
            }
            Section {
                Button(role: .destructive) { resetAsk = true } label: {
                    Label("Reset everything", systemImage: "trash").foregroundStyle(.red)
                }
            }
        }
        .overlay { if reading { ProgressView("Reading…").padding().background(.regularMaterial, in: .rect(cornerRadius: 14)) } }
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(isPresented: Binding(get: { exportDoc != nil }, set: { if !$0 { exportDoc = nil } }),
                      document: exportDoc, contentType: .json, defaultFilename: Self.backupName) { result in
            if case .success = result { message = String(localized: "Backup exported") }
        }
        .fileImporter(isPresented: $picking,
                      allowedContentTypes: pickKind == .backup ? [.json] : [.commaSeparatedText, .xml, .plainText, .text]) { result in
            guard case .success(let url) = result else { return }
            if pickKind == .backup { readBackup(url) } else { readOtherApp(url) }
        }
        .confirmationDialog("Import backup?", isPresented: Binding(get: { backupAsk != nil }, set: { if !$0 { backupAsk = nil } }),
                            titleVisibility: .visible, presenting: backupAsk) { ask in
            Button("Import", role: .destructive) { restore(ask.json) }
            Button("Cancel", role: .cancel) {}
        } message: { ask in
            Text("This replaces all current data with the backup file: \(ask.info.workouts ?? 0) workouts and \(ask.info.routines ?? 0) routines.")
        }
        .confirmationDialog("Reset everything?", isPresented: $resetAsk, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { resetSure = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deletes your plan, workouts and body weight on this device. This cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $resetSure) {
            Button("Delete everything", role: .destructive) { reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Everything in GymFree goes back to how it was on the first launch. Export a backup first if you might want it back.")
        }
        .sheet(item: $preview, onDismiss: { store.cancelImport() }) { p in
            ImportSummaryView(preview: p) {
                let result = store.applyImport()
                preview = nil
                if let result {
                    message = result.kind == "bodyweight"
                        ? String(localized: "\(result.added) weigh-ins imported")
                        : String(localized: "\(result.added) workouts imported")
                }
            } cancel: { preview = nil }
        }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }

    private static var backupName: String { "gymfree-backup-\(Fmt.todayISO())" }

    /* ------------------------------ backups ------------------------------ */

    private func exportBackup() {
        guard let json = try? store.exportJSON() else { message = String(localized: "Something went wrong"); return }
        if let url = DebugLaunch.backupFile {
            try? Data(json.utf8).write(to: url)
            message = String(localized: "Backup exported")
            return
        }
        exportDoc = BackupDocument(text: json)
    }

    private func importBackup() {
        if let url = DebugLaunch.backupFile { readBackup(url); return }
        pickKind = .backup
        picking = true
    }

    private func readBackup(_ url: URL) {
        guard let data = Self.read(url), let json = String(data: data, encoding: .utf8) else {
            message = String(localized: "Could not read that file")
            return
        }
        let info = store.backupInfo(json: json)
        guard info.ok else { message = String(localized: "That is not a GymFree or openGym backup."); return }
        backupAsk = (json, info)
    }

    private func restore(_ json: String) {
        session.ended()
        do {
            try store.importBackup(json: json)
            message = String(localized: "Backup imported")
        } catch {
            message = String(localized: "That is not a GymFree or openGym backup.")
        }
        settled()
    }

    private func reset() {
        session.ended()
        store.resetEverything()
        settled()
        message = String(localized: "All data reset")
    }

    /// After the profile was replaced: device-side settings and the Lock Screen follow it.
    private func settled() {
        Fmt.sync(store)
        session.syncSettings()
        session.resumeIfActive()
    }

    /* ------------------------------ another app ------------------------------ */

    private func importFromAnotherApp() {
        if let text = DebugLaunch.importText { show(store.previewImport(text: text)); return }
        pickKind = .otherApp
        picking = true
    }

    private func readOtherApp(_ url: URL) {
        reading = true
        Task {
            let text = await Task.detached { Self.importText(url) }.value
            reading = false
            guard let text else { message = String(localized: "Could not read that file"); return }
            // An Apple Health export with no weigh-ins in it has nothing to import.
            if text.isEmpty { message = String(localized: "Nothing to import from that file"); return }
            show(store.previewImport(text: text))
        }
    }

    private func show(_ p: ImportPreview?) {
        guard let p else { message = String(localized: "Could not read that file"); return }
        switch p.error {
        case nil: preview = p
        case "empty": message = String(localized: "That file is empty")
        case "nothing": message = String(localized: "Nothing to import from that file")
        case "unrecognised": message = String(localized: "That file’s columns aren’t recognised. GymFree reads exports from FitNotes, Strong and Hevy, and any CSV with a date, exercise, weight and reps.")
        default: message = String(localized: "Could not read that file")
        }
    }

    /// A picked file, inside its security scope.
    nonisolated private static func read(_ url: URL) -> Data? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try? Data(contentsOf: url)
    }

    /// The text to hand the importer. Apple Health's export.xml is often hundreds of megabytes,
    /// nearly all of it steps and heart rate, so only its body-mass records are kept (each one's
    /// tag is on a line of its own); openGym's parser scans exactly those tags.
    nonisolated private static func importText(_ url: URL) -> String? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let head = try? handle.read(upToCount: 1 << 16) else { return nil }
        guard String(decoding: head, as: UTF8.self).drop(while: { $0.isWhitespace || $0 == "\u{FEFF}" }).first == "<" else {
            guard let rest = try? handle.readToEnd() else { return decode(head) }
            return decode(head + rest)
        }
        let marker = Data("HKQuantityTypeIdentifierBodyMass".utf8)
        var kept = [Data]()
        var carry = head
        while true {
            var lines = carry.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: false)
            guard let chunk = try? handle.read(upToCount: 4 << 20), !chunk.isEmpty else {
                kept += lines.filter { $0.range(of: marker) != nil }.map { Data($0) }
                break
            }
            carry = Data(lines.removeLast()) + chunk
            kept += lines.filter { $0.range(of: marker) != nil }.map { Data($0) }
        }
        return kept.isEmpty ? "" : kept.map { String(decoding: $0, as: UTF8.self) }.joined(separator: "\n")
    }

    /// UTF-8, or Windows Latin for an older Excel-saved CSV.
    nonisolated private static func decode(_ data: Data) -> String? {
        String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252)
    }
}

/// What another app's export would bring in, before anything is written (sheets.jsx
/// ImportSummary): it is someone's whole training history, so the numbers, the unit and the
/// exercises that were not recognised are on screen before the button.
struct ImportSummaryView: View {
    let preview: ImportPreview
    let confirm: () -> Void
    let cancel: () -> Void

    private var p: ImportPreview { preview }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if p.isBodyweight {
                        LabeledContent("Weigh-ins", value: "\(p.count ?? 0)")
                    } else {
                        LabeledContent("Workouts", value: "\(p.count ?? 0)")
                        LabeledContent("Sets", value: "\(p.sets ?? 0)")
                        LabeledContent("Exercises matched", value: "\(p.matched ?? 0)")
                        LabeledContent("Added as your own", value: "\(p.created ?? 0)")
                    }
                    LabeledContent("New", value: "\(p.fresh ?? 0)")
                } header: {
                    Text(range)
                } footer: {
                    VStack(alignment: .leading, spacing: 6) { ForEach(notes, id: \.self) { Text($0) } }
                }
                if !p.isBodyweight, let names = p.unmatchedNames, !names.isEmpty {
                    Section {
                        ForEach(names.prefix(12), id: \.self) { Text($0.capitalizedWords) }
                        if names.count > 12 { Text("and \(names.count - 12) more").foregroundStyle(.secondary) }
                    } header: {
                        Text("Not in the library — added as your own exercises")
                    }
                }
                Section {
                    Button(action: confirm) {
                        Text((p.fresh ?? 0) > 0 ? "Import" : "Nothing new to import")
                            .font(.headline).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled((p.fresh ?? 0) == 0)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle(p.source.map { String(localized: "Import from \($0)") } ?? String(localized: "Import history"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
            }
        }
    }

    private var range: String {
        let day = { (iso: String?) -> String in
            let ymd = (iso ?? "").split(separator: "-").compactMap { Int($0) }
            guard ymd.count == 3, let d = Calendar.current.date(from: DateComponents(year: ymd[0], month: ymd[1], day: ymd[2]))
            else { return iso ?? "" }
            return d.formatted(date: .abbreviated, time: .omitted)
        }
        return p.from == p.to ? day(p.from) : "\(day(p.from)) – \(day(p.to))"
    }

    private var notes: [String] {
        var out = [String]()
        let unit = p.unit ?? "kg"
        if p.mixedUnits == true {
            out.append(String(localized: "The file mixes kg and lb — each set is converted to \(unit)."))
        } else if p.converted == true {
            out.append(String(localized: "The file is in \(p.fileUnit ?? "") and your profile is in \(unit) — weights will be converted."))
        } else if !p.isBodyweight, p.fileUnit == nil {
            out.append(String(localized: "The file does not say which unit it uses — numbers are imported as they are."))
        }
        if let have = p.have, have > 0 {
            out.append(String(localized: "\(have) days already have data here and will be left alone."))
        }
        if !p.isBodyweight, let n = p.effortSets, n > 0 {
            let kind = p.effortKind ?? "RPE"
            out.append(p.effortOn == true
                       ? String(localized: "\(n) sets bring an \(kind) with them.")
                       : String(localized: "\(n) sets bring an \(kind) with them — switch on Effort per set in Settings to see it."))
        }
        return out
    }
}

/// The backup as a file for the system's Save sheet.
struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
