import OpenGymCore
import SwiftUI

/// The running session. (Phase 3 replaces this with the full logger.)
struct WorkoutView: View {
    @Environment(GymStore.self) private var store

    var body: some View {
        List {
            if let a = store.active {
                ForEach(Array(a.entries.enumerated()), id: \.offset) { i, e in
                    Text(e.id)
                }
            }
            Button("Discard", role: .destructive) { store.discardWorkout() }
        }
        .navigationTitle(store.active?.name ?? "")
    }
}
