import SwiftUI

// MARK: - Attach a page from the Student Book to a topic

struct TextbookPageScannerSheet: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    @State private var topic: SchoolMathsTopic
    @State private var bookType: String = "learners_book"
    @State private var pageNumber: Int = 7
    @State private var ocrText: String = ""

    init(topic: SchoolMathsTopic, store: AppStore) {
        self.store = store
        _topic = State(initialValue: topic)
    }

    /// The chapter this topic belongs to, for the kicker and the topic menu.
    private var unit: SchoolMathsUnit? {
        store.seedPack.schoolTextbook.units.first { $0.topics.contains { $0.code == topic.code } }
    }

    private var canSave: Bool {
        !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                header
                pagePreview
                pageAndTopic
                pageText
                actions
            }
            .padding(StandardSpacing.xl)
        }
        .background(theme.surface)
        .fittedFormSheet()
        .onAppear {
            pageNumber = topic.learnersBookPage
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("School book · Chapter \(unit?.unitNumber ?? 0)")
                Text("Attach a page from your Student Book")
                    .standardType(.headlineMd)
                    .foregroundStyle(theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Copy out an exercise, a teacher's note or a worked problem from the page. It stays next to the topic, so the book and the app are on the same page.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: StandardSpacing.md)
            SheetCloseButton { dismiss() }
                .offset(x: StandardSpacing.sm, y: -StandardSpacing.sm)
        }
    }

    /// A drawn page in the camera's place. There is no camera yet, so the pill says how the page
    /// gets in: by typing it below.
    private var pagePreview: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .fill(theme.isDark ? theme.patterned.sunkColor : theme.ink)
            PageSketch(paper: theme.isDark ? theme.ink.opacity(0.85) : theme.surface,
                       line: theme.isDark ? theme.bg.opacity(0.25) : theme.ink.opacity(0.14),
                       corner: theme.brass)
                .frame(width: 200, height: 200)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: StandardSpacing.xs) {
                Circle().fill(theme.brass).frame(width: 7, height: 7)
                Text("No camera yet · type the page below")
                    .standardType(.uiHeadline)
            }
            .foregroundStyle(theme.ink)
            .padding(.horizontal, StandardSpacing.md)
            .padding(.vertical, StandardSpacing.xs)
            .background(Capsule().fill(theme.surface))
            .padding(StandardSpacing.md)
        }
        .frame(height: 240)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("No camera yet. Type what the page says below.")
    }

    private var pageAndTopic: some View {
        HStack(alignment: .top, spacing: StandardSpacing.xl) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Page", muted: true)
                pageStepper
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                Kicker("Goes with topic", muted: true)
                HStack(spacing: StandardSpacing.xs) {
                    PatternedChip("\(topic.code) \(topic.title)", isSelected: true) {}
                        .allowsHitTesting(false)
                    if let unit, unit.topics.count > 1 {
                        Menu {
                            ForEach(unit.topics) { choice in
                                Button("\(choice.code) \(choice.title)") {
                                    topic = choice
                                    pageNumber = choice.learnersBookPage
                                }
                            }
                        } label: {
                            Text("Change")
                        }
                        .buttonStyle(OutlineButtonStyle())
                        .accessibilityLabel("Change topic")
                    }
                }
            }
        }
    }

    private var pageStepper: some View {
        HStack(spacing: 0) {
            stepButton("minus", label: "Previous page") { pageNumber = max(1, pageNumber - 1) }
            Rectangle().fill(theme.hairline()).frame(width: 1)
            Text("p. \(pageNumber)")
                .standardType(.uiHeadline)
                .monospacedDigit()
                .foregroundStyle(theme.ink)
                .frame(minWidth: 64)
            Rectangle().fill(theme.hairline()).frame(width: 1)
            stepButton("plus", label: "Next page") { pageNumber = min(265, pageNumber + 1) }
        }
        .frame(height: StandardAccessibility.touchTarget)
        .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.bg))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Page \(pageNumber)")
    }

    private func stepButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .standardType(.uiBody).fontWeight(.semibold)
                .foregroundStyle(theme.ink)
                .frame(width: StandardAccessibility.touchTarget, height: StandardAccessibility.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var pageText: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Kicker("What the page says", muted: true)
                Spacer()
                Button("Start from the topic summary") {
                    ocrText = "Student Book p. \(topic.learnersBookPage) — \(topic.code) \(topic.title):\n\(topic.summary)\nCareful: \(topic.cambridgeWatchouts.joined(separator: " | "))"
                }
                .buttonStyle(TextLinkButtonStyle(arrow: false))
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $ocrText)
                    .learnerTextInput(.retrieval)
                    .scrollContentBackground(.hidden)
                    .patternedType(.readingDefault)
                    .foregroundStyle(theme.ink)
                    .frame(minHeight: 120)
                    .padding(StandardSpacing.sm)
                if ocrText.isEmpty {
                    Text("Type the exercise or note here, a line at a time.")
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.faint(theme.ink))
                        .padding(.horizontal, StandardSpacing.sm + 5)
                        .padding(.vertical, StandardSpacing.sm + 8)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .background(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).fill(theme.bg))
            .overlay(RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
            .accessibilityLabel("What the page says")
        }
    }

    private var actions: some View {
        HStack(spacing: StandardSpacing.sm) {
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(OutlineButtonStyle())
            Button {
                guard canSave else { return }
                store.saveCapturedTextbookPage(
                    topicId: topic.code,
                    bookType: bookType,
                    pageNumber: pageNumber,
                    ocrText: ocrText
                )
                dismiss()
            } label: {
                HStack(spacing: StandardSpacing.xs) {
                    Text("Save page")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(!canSave)
        }
    }
}

/// A page with ruled lines and brass corner marks, tilted a little as if it lay on a desk.
private struct PageSketch: View {
    let paper: Color
    let line: Color
    let corner: Color

    var body: some View {
        Canvas { context, size in
            let page = CGRect(x: 18, y: 18, width: size.width - 36, height: size.height - 36)
            var tilted = context
            tilted.translateBy(x: size.width / 2, y: size.height / 2)
            tilted.rotate(by: .degrees(-2))
            tilted.translateBy(x: -size.width / 2, y: -size.height / 2)
            tilted.fill(Path(page), with: .color(paper))
            for index in 0..<9 {
                let y = page.minY + 22 + CGFloat(index) * 19
                let short = index % 3 == 1
                let rule = CGRect(x: page.minX + 16, y: y, width: (page.width - 32) * (short ? 0.6 : 1), height: 3)
                tilted.fill(Path(roundedRect: rule, cornerRadius: rule.height / 2), with: .color(line))
            }
            let arm: CGFloat = 16
            var marks = Path()
            for (x, y, dx, dy) in [(page.minX - 8, page.minY - 8, 1.0, 1.0), (page.maxX + 8, page.minY - 8, -1.0, 1.0),
                                   (page.minX - 8, page.maxY + 8, 1.0, -1.0), (page.maxX + 8, page.maxY + 8, -1.0, -1.0)] {
                marks.move(to: CGPoint(x: x + dx * arm, y: y))
                marks.addLine(to: CGPoint(x: x, y: y))
                marks.addLine(to: CGPoint(x: x, y: y + dy * arm))
            }
            context.stroke(marks, with: .color(corner), lineWidth: 3)
        }
        .accessibilityHidden(true)
    }
}
