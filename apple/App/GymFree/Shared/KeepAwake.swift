import SwiftUI

/// openGym's "Keep screen awake": no auto-lock while a workout is on screen, so the phone does
/// not have to be unlocked between sets. Auto-lock comes back as soon as the workout goes.
private struct KeepAwake: ViewModifier {
    let on: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { UIApplication.shared.isIdleTimerDisabled = on }
            .onChange(of: on) { _, new in UIApplication.shared.isIdleTimerDisabled = new }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

extension View {
    func keepsScreenAwake(_ on: Bool) -> some View { modifier(KeepAwake(on: on)) }
}
