import SwiftUI

// MARK: - Tests and deadlines (the planner sheet)

struct CalendarHomeView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme

    @State private var newTitle: String = ""
    @State private var newUnits: Set<Int> = [1, 2, 6, 7]
    @State private var newDueAt: Date = Date().addingTimeInterval(7 * 86_400)
    @State private var newKind: String = "unit_test"
    @State private var newNotes: String = ""

    private static let kinds: [(code: String, label: String)] = [
        ("unit_test", "Test"),
        ("checkpoint_review", "Checkpoint review"),
        ("companion_workbook", "Workbook hand-in")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                PaperSheetHeader(
                    kicker: "Planner",
                    title: "Tests and deadlines",
                    subtitle: "Tell the book when a test is coming. Today shows the next one, and each chapter it covers shows how far you have got."
                ) { dismiss() }

                if let next = store.nextSchoolDeadline {
                    nextUpCard(next)
                } else {
                    Text("No tests yet. Add the next one below.")
                        .patternedType(.readingDefault)
                        .foregroundStyle(theme.mute(theme.ink))
                        .paperCard()
                }

                ForEach(laterDeadlines) { deadline in
                    deadlineRow(deadline)
                }

                Rectangle().fill(theme.hairline()).frame(height: 1)

                addForm
            }
            .padding(StandardSpacing.xl)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(theme.surface)
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 760, minHeight: 600, idealHeight: 820)
        #endif
    }

    private var laterDeadlines: [SchoolDeadlineRecord] {
        let nextID = store.nextSchoolDeadline?.id
        return store.deadlines
            .filter { $0.id != nextID }
            .sorted { $0.dueAt < $1.dueAt }
    }

    // MARK: The next test

    private func nextUpCard(_ deadline: SchoolDeadlineRecord) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                Text(deadline.title)
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Self.whenText(deadline.dueAt))
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                Spacer(minLength: StandardSpacing.sm)
                Kicker("Next up")
            }

            coversRow(deadline)

            DeadlineRunway(due: deadline.dueAt, kindLabel: Self.kindLabel(deadline.kind).lowercased())

            if !deadline.notes.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.xs) {
                    Image(systemName: "sparkles")
                        .imageScale(.small)
                        .foregroundStyle(theme.brass)
                    Text(deadline.notes)
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            removeButton(deadline)
        }
        .padding(StandardSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private func coversRow(_ deadline: SchoolDeadlineRecord) -> some View {
        HStack(alignment: .top, spacing: StandardSpacing.sm) {
            Text("Covers")
                .standardType(.uiBody)
                .foregroundStyle(theme.mute(theme.ink))
                .frame(minHeight: 34)
            FlowLayout(spacing: StandardSpacing.xs) {
                ForEach(Self.units(in: deadline.unitNumbersCSV), id: \.self) { number in
                    HStack(spacing: StandardSpacing.xs) {
                        Text("Ch \(number)")
                            .standardType(.uiHeadline)
                            .foregroundStyle(theme.ink)
                        StatusTag(status(forUnit: number))
                    }
                    .padding(.horizontal, StandardSpacing.sm)
                    .frame(minHeight: 34)
                    .background(Capsule().fill(theme.bg))
                    .overlay(Capsule().strokeBorder(theme.hairline(), lineWidth: 1))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: Later deadlines

    private func deadlineRow(_ deadline: SchoolDeadlineRecord) -> some View {
        HStack(alignment: .center, spacing: StandardSpacing.md) {
            Image(systemName: "calendar")
                .foregroundStyle(theme.mute(theme.ink))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.title)
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                Text(rowDetail(deadline))
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: StandardSpacing.sm)
            VStack(alignment: .trailing, spacing: StandardSpacing.xxs) {
                StatusTag(overallStatus(deadline))
                removeButton(deadline)
            }
        }
        .padding(StandardSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).fill(theme.bg))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private func rowDetail(_ deadline: SchoolDeadlineRecord) -> String {
        var parts = [Self.whenText(deadline.dueAt), Self.kindLabel(deadline.kind)]
        let chapters = Self.units(in: deadline.unitNumbersCSV)
        if !chapters.isEmpty {
            parts.append("Ch " + chapters.map(String.init).joined(separator: ", "))
        }
        if !deadline.notes.isEmpty { parts.append(deadline.notes) }
        return parts.joined(separator: " · ")
    }

    private func removeButton(_ deadline: SchoolDeadlineRecord) -> some View {
        Button("Remove") {
            store.deleteDeadline(id: deadline.id)
        }
        .buttonStyle(TextLinkButtonStyle(arrow: false))
        .accessibilityLabel("Remove \(deadline.title)")
    }

    // MARK: Adding one

    private var addForm: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Kicker("Add a test or deadline", muted: true)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: StandardSpacing.md) {
                    titleField.frame(minWidth: 280)
                    dateField.frame(width: 220)
                }
                VStack(alignment: .leading, spacing: StandardSpacing.md) {
                    titleField
                    dateField
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("What kind")
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(Self.kinds, id: \.code) { kind in
                        PatternedChip(kind.label, isSelected: newKind == kind.code) {
                            newKind = kind.code
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Chapters")
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(store.seedPack.schoolTextbook.units.map(\.unitNumber), id: \.self) { number in
                        PatternedChip("\(number)", isSelected: newUnits.contains(number), round: true) {
                            if newUnits.contains(number) { newUnits.remove(number) } else { newUnits.insert(number) }
                        }
                        .accessibilityLabel("Chapter \(number)")
                    }
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Notes")
                TextField("Anything your teacher said to revise (optional)", text: $newNotes)
                    .textFieldStyle(.plain)
                    .paperField()
            }

            HStack(alignment: .center, spacing: StandardSpacing.md) {
                Text(addHint)
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: StandardSpacing.sm)
                Button {
                    addDeadline()
                } label: {
                    Label("Add test", systemImage: "arrow.right")
                        .labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(InkButtonStyle())
                .disabled(trimmedTitle.isEmpty || newUnits.isEmpty)
            }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel("Title")
            TextField("Mock: Geometry and sequences", text: $newTitle)
                .textFieldStyle(.plain)
                .paperField(emphasis: true)
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel("Date")
            DatePicker("Date", selection: $newDueAt, displayedComponents: .date)
                .labelsHidden()
                .tint(theme.brass)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paperField(emphasis: true)
        }
    }

    private var trimmedTitle: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var addHint: String {
        if trimmedTitle.isEmpty { return "Give it a title and pick its chapters." }
        let chapters = newUnits.sorted().map(String.init).joined(separator: ", ")
        return "\(Self.kindLabel(newKind)) on \(newDueAt.formatted(Self.dayFormat)), chapters \(chapters)."
    }

    private func addDeadline() {
        guard !trimmedTitle.isEmpty, !newUnits.isEmpty else { return }
        store.addDeadline(
            title: trimmedTitle,
            unitNumbersCSV: newUnits.sorted().map(String.init).joined(separator: ","),
            dueAt: newDueAt,
            kind: newKind,
            notes: newNotes
        )
        newTitle = ""
        newNotes = ""
    }

    // MARK: Where she stands

    /// A chapter's state from its questions: every one proven, some proven, only with help, or none.
    private func status(forUnit number: Int) -> LearningStatus {
        guard let unit = store.seedPack.schoolTextbook.units.first(where: { $0.unitNumber == number }) else {
            return .notStarted
        }
        return Self.status(for: store.readiness(for: unit))
    }

    static func status(for snapshot: UnitReadinessSnapshot) -> LearningStatus {
        let proven = snapshot.questionsProvenCount + snapshot.questionsSecureCount
        if snapshot.questionsTotal > 0, snapshot.questionsSecureCount == snapshot.questionsTotal { return .secure }
        if snapshot.questionsTotal > 0, proven == snapshot.questionsTotal { return .proven }
        if proven > 0 { return .working }
        if snapshot.questionsAssistedCount > 0 { return .withHelp }
        return .notStarted
    }

    /// The weakest state among a deadline's chapters, so a row never sounds readier than it is.
    private func overallStatus(_ deadline: SchoolDeadlineRecord) -> LearningStatus {
        let order: [LearningStatus] = [.notStarted, .withHelp, .working, .proven, .secure]
        let states = Self.units(in: deadline.unitNumbersCSV).map(status(forUnit:))
        return states.min { (order.firstIndex(of: $0) ?? 0) < (order.firstIndex(of: $1) ?? 0) } ?? .notStarted
    }

    // MARK: Words and dates

    static let dayFormat = Date.FormatStyle().weekday(.abbreviated).day().month(.abbreviated)

    static func whenText(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        let relative: String
        switch days {
        case 0: relative = "today"
        case 1: relative = "tomorrow"
        case 2...: relative = "in \(days) days"
        case -1: relative = "yesterday"
        default: relative = "\(-days) days ago"
        }
        return "\(date.formatted(dayFormat)) · \(relative)"
    }

    static func kindLabel(_ code: String) -> String {
        kinds.first(where: { $0.code == code })?.label
            ?? code.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func units(in csv: String) -> [Int] {
        csv.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}

// MARK: - The runway from today to the test

/// A line from today to the day of the test, one tick per day, so the gap is something she can
/// see rather than a number. It draws days, not practice sessions: the book does not plan those yet.
private struct DeadlineRunway: View {
    @Environment(\.standardTheme) private var theme
    let due: Date
    let kindLabel: String

    private var days: Int {
        let calendar = Calendar.current
        return max(calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: due)).day ?? 0, 0)
    }

    var body: some View {
        VStack(spacing: StandardSpacing.xs) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let ticks = min(days, 60)
                ZStack(alignment: .leading) {
                    Rectangle().fill(theme.hairline()).frame(height: 1.5)
                    if ticks > 1 {
                        ForEach(1..<ticks, id: \.self) { index in
                            Rectangle()
                                .fill(theme.hairline())
                                .frame(width: 1, height: 8)
                                .offset(x: width * CGFloat(index) / CGFloat(ticks))
                        }
                    }
                    Circle()
                        .strokeBorder(theme.ink, lineWidth: 2)
                        .background(Circle().fill(theme.surface))
                        .frame(width: 18, height: 18)
                    RoundedRectangle(cornerRadius: StandardRadius.sm)
                        .fill(theme.ink)
                        .frame(width: 16, height: 16)
                        .offset(x: width - 16)
                }
                .frame(height: 20)
            }
            .frame(height: 20)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today").standardType(.uiHeadline).foregroundStyle(theme.ink)
                    Text(Date().formatted(CalendarHomeView.dayFormat))
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                }
                Spacer()
                Text(days == 1 ? "1 day to go" : "\(days) days to go")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(due.formatted(CalendarHomeView.dayFormat)).standardType(.uiHeadline).foregroundStyle(theme.ink)
                    Text(kindLabel)
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) days from today to the \(kindLabel)")
    }
}
