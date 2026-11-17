import SwiftUI

/// The book's spine: its name under Byrne's three shapes, the rooms, what is up next, and the
/// two grown-up places (Deadlines, Settings) at the foot.
struct PatternedSidebar: View {
    @Bindable var store: AppStore
    var onHideSidebar: (() -> Void)? = nil
    @Environment(\.standardTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            masthead
                .padding(.bottom, StandardSpacing.lg)
            ScrollView {
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    ForEach(AppRoom.allCases) { room in
                        SidebarRow(
                            title: room.title,
                            systemImage: room.systemImage,
                            isActive: store.activeRoom == room
                        ) {
                            store.activeRoom = room
                        }
                    }
                }
                upNext
                    .padding(.top, StandardSpacing.xl)
            }
            .scrollIndicators(.hidden)
            Spacer(minLength: StandardSpacing.md)
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                SidebarRow(title: "Deadlines", systemImage: "calendar", isActive: false) {
                    store.showCalendarSheet = true
                }
                SidebarRow(title: "Settings", systemImage: "slider.horizontal.3", isActive: false) {
                    store.showSettingsSheet = true
                }
            }
        }
        .padding(.horizontal, StandardSpacing.md)
        .padding(.top, StandardSpacing.lg)
        .padding(.bottom, StandardSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.patterned.marginColor.ignoresSafeArea())
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack(spacing: StandardSpacing.xs) {
                Text("VOL. I · MATH")
                    .standardType(.uiMicro)
                    .fontWeight(.bold)
                    .tracking(1.4)
                    .foregroundStyle(theme.bg)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: StandardRadius.sm, style: .continuous)
                            .fill(theme.patterned.color(.moves))
                    )
                ByrneMark()
                Spacer(minLength: 0)
                if let onHideSidebar {
                    Button(action: onHideSidebar) {
                        Image(systemName: "sidebar.left")
                            .foregroundStyle(theme.mute(theme.ink))
                            .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("\\", modifiers: [.command])
                    .accessibilityLabel("Hide left spine for maximum work area")
                }
            }
            .padding(.bottom, 2)
            Text("The Patterned World")
                .standardType(.headlineSm)
                .foregroundStyle(theme.ink)
            Text("Kym's mathematics · Curious Atelier")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
            Rectangle()
                .fill(theme.brass.opacity(0.45))
                .frame(height: 1)
                .padding(.top, 4)
        }
        .padding(.horizontal, StandardSpacing.xs)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var upNext: some View {
        if let next = store.euclidUpNext {
            Button {
                store.openEuclid(.board(next.id))
            } label: {
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    Kicker("Up next")
                    Text("\(next.id.raw) · \(next.title)")
                        .standardType(.uiHeadline)
                        .foregroundStyle(theme.ink)
                    Text(standsOnLine(next))
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                .paperCard(padding: StandardSpacing.sm)
            }
            .buttonStyle(.plain)
        }
    }

    private func standsOnLine(_ proposition: EuclidProposition) -> String {
        let built = proposition.uses.filter {
            if case .built? = EuclidSpine.proposition($0)?.kind { true } else { false }
        }
        guard !built.isEmpty else { return "Stands on nothing you have to build first." }
        return "Stands on " + built.map(\.raw).joined(separator: ", ") + ", which you have built."
    }
}

/// Byrne's red triangle, yellow square and blue circle: the book's mark.
struct ByrneMark: View {
    @Environment(\.standardTheme) private var theme
    var size: CGFloat = 12

    var body: some View {
        let palette = theme.patterned
        HStack(spacing: size * 0.4) {
            Triangle().fill(palette.color(.moves)).frame(width: size, height: size * 0.9)
            Rectangle().fill(palette.color(.stays)).frame(width: size, height: size)
            Circle().fill(palette.color(.given)).frame(width: size, height: size)
        }
        .accessibilityHidden(true)
    }

    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.closeSubpath()
            }
        }
    }
}

private struct SidebarRow: View {
    @Environment(\.standardTheme) private var theme
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: StandardSpacing.sm) {
                Image(systemName: systemImage)
                    .frame(width: 22)
                    .foregroundStyle(isActive ? theme.brass : theme.mute(theme.ink))
                Text(title)
                    .standardType(.uiBody)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(theme.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, StandardSpacing.sm)
            .frame(minHeight: StandardAccessibility.touchTarget - 4)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .fill(isActive ? theme.surface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous)
                    .strokeBorder(isActive ? theme.hairline() : Color.clear, lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                if isActive {
                    Capsule()
                        .fill(theme.patterned.color(.moves))
                        .frame(width: 3.5, height: 20)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
