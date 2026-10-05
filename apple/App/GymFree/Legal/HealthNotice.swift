import SwiftUI

/// The health notice (App Review 1.4.1: "remind users to check with a doctor"). Shown once, the
/// first time someone opens a feature that gives health-related recommendations: the plan
/// builder (it asks health questions and suggests training) or calories & food. Logging and
/// building routines never show it, so the basic flow stays uninterrupted; the same text is
/// always in Settings → About → Health & safety.
enum HealthNotice {
    static let seenKey = "gf.healthNoticeSeen"

    static let points: [LocalizedStringResource] = [
        "GymFree gives general fitness and nutrition information. It is not medical advice and does not diagnose or treat any condition.",
        "Check with a doctor before you start exercising or change how you eat, especially if you have a health condition, take medicine, are pregnant or have recently given birth, or have had an eating disorder.",
        "Stop and get help if you feel chest pain or pressure, faintness or dizziness, unusual breathlessness, a racing or irregular heartbeat, or sharp pain.",
        "It doesn't replace a doctor, physiotherapist, dietitian or other professional who knows you.",
    ]
}

private struct HealthNoticeModifier: ViewModifier {
    @AppStorage(HealthNotice.seenKey) private var seen = false

    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(get: { !seen }, set: { if !$0 { seen = true } })) {
            HealthNoticeSheet { seen = true }
                .presentationDetents([.large])
        }
    }
}

extension View {
    /// Shows the health notice once per install, the first time this view appears.
    func healthNoticeOnce() -> some View { modifier(HealthNoticeModifier()) }
}

private struct HealthNoticeSheet: View {
    var done: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "stethoscope")
                        .font(.largeTitle).foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("A quick health note").font(.title2.weight(.bold))
                    ForEach(HealthNotice.points.indices, id: \.self) { i in
                        Label { Text(HealthNotice.points[i]) } icon: {
                            Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(.secondary)
                        }
                        .labelStyle(BulletLabelStyle())
                    }
                    Text("You can read this again any time in Settings → About → Health & safety.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: done) {
                    Text("OK").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .accessibilityIdentifier("healthNotice.ok")
            }
        }
    }
}

/// A bullet aligned with the first line of a wrapped paragraph.
struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon.frame(width: 8)
            configuration.title.fixedSize(horizontal: false, vertical: true)
        }
    }
}
