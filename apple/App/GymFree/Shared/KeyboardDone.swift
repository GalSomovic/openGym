import SwiftUI
import UIKit

/// A "Done" button above the keyboard. Number pads have no return key, so without it a typed
/// number can't be put away. Apply once per screen that has number fields.
struct KeyboardDone: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

extension View {
    func keyboardDoneButton() -> some View { modifier(KeyboardDone()) }
}
