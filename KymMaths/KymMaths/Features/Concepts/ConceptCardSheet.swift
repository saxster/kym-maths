import SwiftUI

/// A concept a link or a deep link asked to show.
struct ConceptRequest: Identifiable, Hashable, Sendable {
    let id: String
}

extension View {
    /// Opens a concept card when a `kymconcept://` link below is tapped; other links open as before.
    /// Apply it inside each sheet too, since a sheet cannot present over the one already showing.
    func conceptLinks() -> some View {
        modifier(ConceptLinksModifier())
    }
}

private struct ConceptLinksModifier: ViewModifier {
    @Environment(\.conceptLibrary) private var library
    @State private var shown: ConceptRequest?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard let id = ConceptLibrary.concept(in: url) else { return .systemAction }
                if library.card(id) != nil { shown = ConceptRequest(id: id) }
                return .handled
            })
            .sheet(item: $shown) { request in
                ConceptCardSheet(start: request.id)
            }
    }
}

/// One concept card. A link inside it opens the next card in the same sheet, with a way back.
struct ConceptCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme
    @Environment(\.conceptLibrary) private var library
    @State private var trail: [String]

    init(start: String) {
        _trail = State(initialValue: [start])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if trail.count > 1, let back = library.card(trail[trail.count - 2]) {
                    Button {
                        trail.removeLast()
                    } label: {
                        Label("Back to \(back.name.lowercased())", systemImage: "arrow.left")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(TextLinkButtonStyle(arrow: false))
                }
                Spacer()
                SheetCloseButton { dismiss() }
            }
            .padding(.horizontal, StandardSpacing.lg)
            .padding(.top, StandardSpacing.sm)

            if let id = trail.last, let card = library.card(id) {
                ConceptCardPage(card: card)
                    .id(card.id)
            }
        }
        .background(theme.bg)
        .environment(\.openURL, OpenURLAction { url in
            guard let id = ConceptLibrary.concept(in: url) else { return .systemAction }
            if library.card(id) != nil, id != trail.last { trail.append(id) }
            return .handled
        })
    }
}

private struct ConceptCardPage: View {
    @Environment(\.standardTheme) private var theme
    @Environment(\.conceptLibrary) private var library
    let card: ConceptCard

    @State private var typed = ""
    @State private var marking: AnswerMarking?
    @FocusState private var typing: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.xl) {
                header
                part("In one sentence") { prose(card.oneSentence) }
                part("Picture it") { prose(card.picture) }
                part("How to work it out") { numberedSteps }
                if let bigNumbers = card.bigNumbers {
                    part("With big numbers") { prose(bigNumbers) }
                }
                part("Worked example") { prose(card.workedExample) }
                checkYourself
                part("Don't mix it up with") { mixUp }
                part("Stands on") { standsOn }
                if !card.usedIn.isEmpty {
                    part("You will use it in") { usedIn }
                }
            }
            .padding(.horizontal, StandardSpacing.xl)
            .padding(.vertical, StandardSpacing.lg)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            Kicker("Concept card")
            Text(card.name)
                .patternedType(.question)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let also = [card.short, card.symbol].compactMap({ $0 }).joined(separator: "  ·  ").nonEmpty {
                Text(also)
                    .patternedType(.mathInline)
                    .foregroundStyle(theme.mute(theme.ink))
            }
        }
    }

    private func part<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker(title, muted: true)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prose(_ text: String) -> some View {
        ConceptText(text, exclude: card.id)
            .patternedType(.readingDefault)
            .foregroundStyle(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var numberedSteps: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            ForEach(Array(card.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                    Text("\(index + 1).")
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.mute(theme.ink))
                        .monospacedDigit()
                    prose(step)
                }
            }
        }
    }

    private var checkYourself: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Check yourself")
            ConceptText(card.check.prompt, exclude: card.id)
                .patternedType(.question)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            AnswerCheckRow(typed: $typed, typing: $typing) {
                marking = card.check.answerKey.mark(typed)
            }
            .onChange(of: typed) { marking = nil }
            if let marking {
                Text(marking.isCorrect ? "Right." : "The answer is \(card.check.answer).")
                    .patternedType(.readingDefault)
                    .foregroundStyle(marking.isCorrect ? theme.patterned.provenColor : theme.patterned.assistedColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .paperCard()
    }

    @ViewBuilder
    private var mixUp: some View {
        if let other = card.mixUp.with.flatMap(library.card) {
            nameLinks([other])
                .patternedType(.readingDefault)
        } else if let name = card.mixUp.name {
            Text(name)
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
        }
        prose(card.mixUp.how)
    }

    @ViewBuilder
    private var standsOn: some View {
        let cards = card.standsOn.compactMap(library.card)
        if cards.isEmpty {
            Text("Only what you already know.")
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
        } else {
            nameLinks(cards)
                .patternedType(.readingDefault)
        }
    }

    private var usedIn: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            ForEach(Array(card.usedIn.enumerated()), id: \.offset) { _, use in
                switch use {
                case let .concept(id, label) where library.card(id) != nil:
                    Text(Self.link(label, to: id, ink: theme.ink, underline: theme.brass))
                        .patternedType(.readingDefault)
                        .tint(theme.ink)
                default:
                    Text(use.label)
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.ink)
                }
            }
        }
    }

    /// Card names as links, joined with commas.
    private func nameLinks(_ cards: [ConceptCard]) -> some View {
        var text = AttributedString()
        for (index, other) in cards.enumerated() {
            if index > 0 { text += AttributedString(", ") }
            text += Self.link(other.name, to: other.id, ink: theme.ink, underline: theme.brass)
        }
        return Text(text)
            .foregroundStyle(theme.ink)
            .tint(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private static func link(_ name: String, to id: String, ink: Color, underline: Color) -> AttributedString {
        var piece = AttributedString(name)
        piece.link = ConceptLibrary.url(for: id)
        piece.foregroundColor = ink
        piece.swiftUI.underlineStyle = Text.LineStyle(pattern: .solid, color: underline)
        return piece
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
