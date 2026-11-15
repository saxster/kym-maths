import SwiftUI

extension View {
    /// Reports the width this view is given, so a page can choose columns or a stack by the room it
    /// really has. `ViewThatFits` measures ideal widths, and a paragraph's ideal width is one long
    /// line, so it always picks the stack.
    ///
    /// The width comes back in whole points. A layout built from the width can come out a fraction of a
    /// point wider than it, which widens the view, which reports a new width: on iPhone at large text the
    /// Euclid map did that forever and froze the app. Whole points stop that loop.
    func readWidth(_ width: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.width.rounded(.down) } action: { width.wrappedValue = $0 }
    }

    /// Reports the height this view is given, in whole points, for the same reason as `readWidth`.
    func readHeight(_ height: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height.rounded(.down) } action: { height.wrappedValue = $0 }
    }
}

extension View {
    /// Asks for a page-sized sheet where the system supports it, so a two-column sheet has room.
    @ViewBuilder
    func pageSizedSheet() -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            presentationSizing(.page)
        } else {
            self
        }
    }

    /// Asks for a form sheet as tall as its content, where the system supports it.
    @ViewBuilder
    func fittedFormSheet() -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            presentationSizing(.form.fitted(horizontal: false, vertical: true))
        } else {
            self
        }
    }
}
