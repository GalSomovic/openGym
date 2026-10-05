import SwiftUI

/// Settings → About → Health & safety: the health notice, eating-disorder support (the
/// helpline for the phone's region first, every other one below) and the privacy policy.
/// The calories & food setup and the plan builder link here too.
struct HealthSafetyView: View {
    /// Region of the phone (Settings → General → Language & Region), e.g. "GB".
    var region: String? = Locale.current.region?.identifier

    var body: some View {
        let (local, others) = Helpline.split(for: region)
        List {
            Section {
                ForEach(HealthNotice.points.indices, id: \.self) { i in
                    Label { Text(HealthNotice.points[i]) } icon: {
                        Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(.secondary)
                    }
                    .labelStyle(BulletLabelStyle())
                    .font(.subheadline)
                }
            } header: {
                Text("Health notice")
            } footer: {
                Text("Calorie and energy numbers are estimates: for most people the starting figure is within about 10–15%, and it improves as you log. The plan builder's health check only makes a plan gentler; it is not a medical screening.")
            }

            Section {
                Text("If food, eating or your body is worrying you, you don't have to deal with it alone. These free, confidential services are run by eating-disorder charities and health services, for you or for someone you care about.")
                    .font(.subheadline)
                ForEach(local) { HelplineRow(line: $0) }
                    .accessibilityIdentifier("helpline.local")
            } header: {
                Text("Eating-disorder support")
            } footer: {
                Text("If you or someone else is in immediate danger, call your local emergency number.")
            }

            Section {
                ForEach(others) { HelplineRow(line: $0) }
            } header: {
                Text("Other countries")
            } footer: {
                Text("Opening hours change from time to time; the website has the current ones. Freephone numbers usually work only from inside their country.")
            }

            Section {
                NavigationLink { PrivacyPolicyView() } label: {
                    Label("Privacy policy", systemImage: "hand.raised")
                }
                .accessibilityIdentifier("healthSafety.privacy")
                Link(destination: LegalLinks.privacyPolicy) {
                    Label("Privacy policy on the web", systemImage: "safari")
                }
            } header: {
                Text("Privacy")
            } footer: {
                Text("GymFree collects no data. Everything you enter stays on this device; Apple Health and location are optional and never shared.")
            }
        }
        .navigationTitle("Health & safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelplineRow: View {
    let line: Helpline

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(line.country).font(.caption).foregroundStyle(.secondary)
            Text(line.name).font(.headline)
            if let note = line.note { Text(note).font(.footnote).foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 6) {
                if let phone = line.phone, let tel = URL(string: "tel:\(line.dial ?? phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: tel) { Label(phone, systemImage: "phone") }
                        .accessibilityLabel("Call \(line.name), \(phone)")
                }
                Link(destination: line.url) { Label(line.url.host() ?? line.url.absoluteString, systemImage: "safari") }
                    .lineLimit(1)
            }
            .font(.subheadline)
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}
