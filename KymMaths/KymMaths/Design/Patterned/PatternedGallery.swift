#if DEBUG
import SwiftUI

/// Every Patterned component on one page, so a change to a piece is checked once here rather than
/// in every room. Opens with `-KymDeepLink gallery`.
struct PatternedGallery: View {
    @Environment(\.standardTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                EditorialHeader(
                    eyebrow: "Euclid's Workshop · Book I",
                    title: "From one triangle to Pythagoras",
                    subtitle: "Every proposition stands on the ones above it."
                )
                WonderQuestion("Why should {red:a negative} times {red:a negative} be {blue:positive}?")
                ReadingSpread {
                    VStack(alignment: .leading, spacing: StandardSpacing.md) {
                        ByrneText("Put {blue:an arrow} on the number line from 0 to 3. Multiplying by −1 {red:turns the arrow around}, and {yellow:its length stays the same}.")
                            .patternedType(.reading)
                            .foregroundStyle(theme.ink)
                        Text("Figure 1.3. Each × (−1) is a half-turn about zero.")
                            .patternedType(.readingSmall)
                            .foregroundStyle(theme.mute(theme.ink))
                        LockedNote("What stays the same opens after you predict.")
                    }
                } margin: {
                    MarginNote(.history("AD 628 · Brahmagupta"), "Brahmagupta wrote the first rules for fortunes and debts.")
                    MarginNote(.sidenote(1), "Mathematicians call this a rotation by 180°.")
                    MarginNote(.hand, "turning around twice = facing forward!!")
                    ChainCard(
                        standsOn: [ChainLink(code: "1.1", title: "Negative numbers on the line")],
                        unlocks: [ChainLink(code: "1.5", title: "The index laws"), ChainLink(code: "Ch 12", title: "Turning by any angle")]
                    )
                }
                HStack(spacing: StandardSpacing.md) {
                    Button("Continue") {}.buttonStyle(InkButtonStyle())
                    Button("Continue") {}.buttonStyle(BrassButtonStyle())
                    Button("Continue") {}.buttonStyle(OutlineButtonStyle())
                    Button("Read the chapter") {}.buttonStyle(TextLinkButtonStyle())
                }
                HStack(spacing: StandardSpacing.md) {
                    ForEach(LearningStatus.allCases, id: \.self) { StatusTag($0) }
                }
                HStack(spacing: StandardSpacing.lg) {
                    ForEach(0...4, id: \.self) { SkillLamps(lit: $0) }
                }
                VStack(spacing: 0) {
                    PathStepRow(number: 1, title: "Remember", detail: "4 cards come back from last week", minutes: 3, state: .done)
                    Divider()
                    PathStepRow(number: 2, title: "Discover", detail: "Why a negative times a negative is positive", minutes: 4, state: .current)
                    Divider()
                    PathStepRow(number: 3, title: "Spot the trap", detail: "A tempting wrong answer to catch", minutes: 4, state: .upcoming)
                }
                .paperCard()
                VStack(alignment: .leading, spacing: StandardSpacing.sm) {
                    Kicker("Next test")
                    Text("4").patternedType(.numeral)
                    ProgressRule(0.6)
                    Text("a^m × a^n = a^(m+n)").patternedType(.mathDisplay)
                }
                .paperCard()
            }
            .padding(StandardSpacing.xl2)
        }
        .background(theme.bg)
    }
}
#endif
