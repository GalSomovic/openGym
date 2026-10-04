import AlarmKit
import SwiftUI

/// Opt-in: the end of a rest rings as an alarm, through silent mode and Focus (AlarmKit).
/// Off by default; the in-app chime and a notification cover the usual case.
@MainActor
final class RestAlarm {
    private var current: UUID?

    var authorized: Bool { AlarmManager.shared.authorizationState == .authorized }

    func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        return (try? await manager.requestAuthorization()) == .authorized
    }

    func schedule(seconds: Double) {
        cancel()
        guard seconds >= 1 else { return }
        let id = UUID()
        current = id
        let title: LocalizedStringResource = "Rest over"
        let alert: AlarmPresentation.Alert = if #available(iOS 26.1, *) {
            AlarmPresentation.Alert(title: title)
        } else {
            AlarmPresentation.Alert(title: title, stopButton: .init(text: "Stop", textColor: .white, systemImageName: "stop.fill"))
        }
        let attributes = AlarmAttributes<RestAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert, countdown: .init(title: "Resting")),
            metadata: RestAlarmMetadata(),
            tintColor: Color(red: 0.19, green: 0.82, blue: 0.35))
        let config = AlarmManager.AlarmConfiguration<RestAlarmMetadata>(
            countdownDuration: .init(preAlert: seconds, postAlert: nil),
            schedule: nil,
            attributes: attributes)
        Task {
            let manager = AlarmManager.shared
            if manager.authorizationState == .notDetermined { _ = await requestAuthorization() }
            guard authorized, current == id else { return }
            _ = try? await manager.schedule(id: id, configuration: config)
        }
    }

    func cancel() {
        if let id = current { try? AlarmManager.shared.cancel(id: id) }
        current = nil
    }
}
