import OpenGymCore
import SwiftUI

enum AppTab: Hashable {
    case today, plan, stats, exercises, settings
}

struct RootView: View {
    @State private var tab: AppTab = DebugLaunch.tab ?? .today
    @Environment(GymStore.self) private var store

    /// Settings → Appearance; GymFree follows the system unless told otherwise.
    private var scheme: ColorScheme? {
        switch store.pick("gfTheme", as: String.self) {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "figure.strengthtraining.traditional", value: .today) {
                TodayView(tab: $tab)
            }
            Tab("Plan", systemImage: "calendar", value: .plan) {
                PlanView()
            }
            Tab("Stats", systemImage: "chart.xyaxis.line", value: .stats) {
                StatsView(tab: $tab)
            }
            Tab("Exercises", systemImage: "dumbbell", value: .exercises) {
                LibraryView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .preferredColorScheme(scheme)
        // Scrolling any list puts the keyboard away (number pads have no return key).
        .scrollDismissesKeyboard(.interactively)
    }
}
