import SwiftUI

// MARK: - Settings: her book first, then the grown-up's panel

struct MathsSettingsSheet: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.standardTheme) private var theme
    @AppStorage(StandardThemeStore.subjectAppStorageKey) private var themeID: String = StandardTheme.systemID

    private let paperStyles = ["grid", "dots", "lined", "blank", "cornell"]
    private let goalOptions = [15, 25, 40, 60]
    @State private var geminiKeyInput: String = ""
    @State private var anthropicKeyInput: String = ""
    @State private var openAIKeyInput: String = ""
    @State private var elevenLabsKeyInput: String = ""
    @AppStorage("kymmaths.britishVoicePresetID") private var britishVoicePresetID: String = KymLiveBritishVoiceCatalog.defaultPreset.id
    @State private var keySaveBanner: String?
    @State private var keyRevision = 0
    @State private var showMoreThemes = false
    @State private var showEngines = false
    @State private var showPromptSegments = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StandardSpacing.lg) {
                PaperSheetHeader(title: "Settings") { dismiss() }
                yourBook
                grownUpPanel
                footer
            }
            .padding(StandardSpacing.xl)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(theme.surface)
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 760, minHeight: 640, idealHeight: 820)
        #endif
    }

    // MARK: Your book

    private var yourBook: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Text("Your book")
                    .standardType(.headlineSm)
                    .foregroundStyle(theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Make it yours. Change these any time.")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.lg) {
                    themePicker.frame(minWidth: 330)
                    nameAndMinutes.frame(minWidth: 240)
                }
                VStack(alignment: .leading, spacing: StandardSpacing.md) {
                    themePicker
                    nameAndMinutes
                }
            }

            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Scratchpad paper")
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(paperStyles, id: \.self) { style in
                        PatternedChip(style.capitalized, isSelected: store.defaultScratchpadPaperStyle == style) {
                            store.defaultScratchpadPaperStyle = style
                        }
                    }
                }
            }

            plainToggle(
                "Show the picture before the formula",
                detail: "A drawing or a model comes first, then the symbols that say the same thing.",
                isOn: $store.showIntuitionBeforeFormula
            )
            plainToggle(
                "Start practice with bar models",
                detail: "Bar models, area tiles and 1,000-people squares are ready when you practise.",
                isOn: $store.showSingaporeBarModelsByDefault
            )
        }
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel("Theme")
            HStack(spacing: StandardSpacing.sm) {
                themeCard(id: StandardTheme.systemID, title: "Follow iPad", preview: .system)
                themeCard(id: StandardTheme.parchment.id, title: "Paper", preview: .theme(.parchment))
                themeCard(id: StandardTheme.darkGraphite.id, title: "Night", preview: .theme(.darkGraphite))
            }
            Text("Follow iPad is paper by day and night after dark.")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
            DisclosureGroup(isExpanded: $showMoreThemes) {
                StandardThemeGallery()
                    .padding(.top, StandardSpacing.xs)
            } label: {
                Text("More themes")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.brass)
            }
            .tint(theme.brass)
        }
    }

    private enum ThemePreview {
        case system
        case theme(StandardTheme)
    }

    private func themeCard(id: String, title: String, preview: ThemePreview) -> some View {
        let isSelected = StandardTheme.normalizedPersistedID(themeID) == id
        return Button {
            themeID = id
        } label: {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                themeSwatch(preview)
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous))
                HStack {
                    Text(title)
                        .standardType(.uiBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .imageScale(.small)
                            .foregroundStyle(theme.ink)
                    }
                }
            }
            .padding(StandardSpacing.xs)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StandardRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? theme.ink : theme.hairline(), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func themeSwatch(_ preview: ThemePreview) -> some View {
        switch preview {
        case .system:
            HStack(spacing: 0) {
                swatchPage(.parchment)
                swatchPage(.darkGraphite)
            }
        case .theme(let option):
            swatchPage(option)
        }
    }

    /// A tiny page in a theme: Byrne's three marks over two lines of text.
    private func swatchPage(_ option: StandardTheme) -> some View {
        let palette = option.patterned
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: "triangle.fill").foregroundStyle(palette.color(.moves))
                Image(systemName: "square.fill").foregroundStyle(palette.color(.stays))
                Image(systemName: "circle.fill").foregroundStyle(palette.color(.given))
            }
            .imageScale(.small).standardType(.uiMicro)
            Capsule().fill(option.ink.opacity(0.22)).frame(height: 3)
            Capsule().fill(option.ink.opacity(0.22)).frame(width: 30, height: 3)
        }
        .padding(StandardSpacing.xs)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(option.bg)
        .accessibilityHidden(true)
    }

    private var nameAndMinutes: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Your name")
                HStack {
                    TextField("Name", text: $store.learnerDisplayName)
                        .textFieldStyle(.plain)
                    Image(systemName: "pencil")
                        .foregroundStyle(theme.mute(theme.ink))
                        .accessibilityHidden(true)
                }
                .paperField()
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                PaperFieldLabel("Minutes a day")
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(goalOptions, id: \.self) { minutes in
                        PatternedChip("\(minutes) min", isSelected: store.dailyPracticeGoalMinutes == minutes) {
                            store.dailyPracticeGoalMinutes = minutes
                        }
                    }
                }
            }
        }
    }

    // MARK: For the grown-up

    private var grownUpPanel: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            HStack(alignment: .top, spacing: StandardSpacing.sm) {
                Image(systemName: "slider.vertical.3")
                    .standardType(.uiTitle)
                    .foregroundStyle(theme.ink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    Text("For the grown-up")
                        .standardType(.headlineSm)
                        .foregroundStyle(theme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("These shape what \(store.learnerDisplayName) sees and how the coach works. \(store.learnerDisplayName) can read them too.")
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            twoUp {
                labelled("Curriculum lens") {
                    menuRow(store.selectedCurriculumLens.title, options: MathsCurriculumLens.allCases, label: \.title) {
                        store.selectedCurriculumLens = $0
                    }
                    Text(store.selectedCurriculumLens.subtitle)
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } trailing: {
                labelled("Workbook tier") {
                    FlowLayout(spacing: StandardSpacing.xs) {
                        ForEach(CompanionWorkbookTierFilter.allCases) { tier in
                            PatternedChip(Self.tierLabel(tier), isSelected: store.defaultWorkbookTier == tier) {
                                store.defaultWorkbookTier = tier
                            }
                        }
                    }
                    Text("The school gives a student book but no workbook, so the app writes three tiers of questions for every chapter.")
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            twoUp {
                labelled("AI coach") {
                    menuRow(Self.providerLabel(store.defaultAIProvider), options: AIProvider.allCases, label: Self.providerLabel) {
                        store.defaultAIProvider = $0
                    }
                }
            } trailing: {
                labelled("Routing") {
                    menuRow(Self.policyLabel(store.aiFeaturePolicy), options: AIFeaturePolicy.allCases, label: Self.policyLabel) {
                        store.aiFeaturePolicy = $0
                    }
                }
            }

            apiKeys

            Rectangle().fill(theme.hairline()).frame(height: 1)

            plainToggle(
                "Upload \(store.learnerDisplayName)'s work to the cloud",
                detail: "Off by default. Textbook photos and handwriting stay on this device unless you turn it on.",
                isOn: $store.allowRemoteCameraAIAnalysis
            )
            plainToggle(
                "Open the horizon chapters",
                detail: "Adds Ch 0 (sets and logic), Ch 12 (the unit circle), Ch 15 (Bayes' rule), Ch 17–18 (calculus) and Ch 20 (2×2 matrices).",
                isOn: $store.enableAdvancedHorizonModules
            )

            coachPreferences

            HStack(spacing: StandardSpacing.sm) {
                Image(systemName: "lock")
                    .foregroundStyle(theme.ink)
                Text("Child safety and learner agency cannot be turned off.")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
            }
            .padding(StandardSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.surface))
            .accessibilityElement(children: .combine)

            DisclosureGroup(isExpanded: $showEngines) {
                engineGlossary.padding(.top, StandardSpacing.sm)
            } label: {
                Text("What runs underneath")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
            }
            .tint(theme.brass)

            DisclosureGroup(isExpanded: $showPromptSegments) {
                promptSegments.padding(.top, StandardSpacing.sm)
            } label: {
                Text("What the coach is told")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
            }
            .tint(theme.brass)
        }
        .padding(StandardSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StandardRadius.xl, style: .continuous)
                .fill(theme.patterned.sunkColor)
        )
    }

    private var apiKeys: some View {
        let keyStore = KeychainFrontierKeyStore()
        return VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            HStack(spacing: StandardSpacing.xs) {
                Image(systemName: "lock").imageScale(.small)
                #if os(macOS)
                Text("API keys, kept in this Mac's Keychain and never uploaded")
                #else
                Text("API keys, kept in this iPad's Keychain and never uploaded")
                #endif
            }
            .standardType(.uiBody)
            .foregroundStyle(theme.mute(theme.ink))

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: StandardSpacing.sm) { keyCards(keyStore) }
                VStack(alignment: .leading, spacing: StandardSpacing.sm) { keyCards(keyStore) }
            }
            .id(keyRevision)
            if let banner = keySaveBanner {
                Text(banner)
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.patterned.provenColor)
            }
        }
    }

    @ViewBuilder
    private func keyCards(_ keyStore: KeychainFrontierKeyStore) -> some View {
        keyCard("Anthropic", provider: .anthropic, text: $anthropicKeyInput, keyStore: keyStore)
        keyCard("Gemini", provider: .gemini, text: $geminiKeyInput, keyStore: keyStore)
        keyCard("OpenAI", provider: .openAI, text: $openAIKeyInput, keyStore: keyStore)
        elevenLabsKeyCard
    }

    private var elevenLabsKeyCard: some View {
        let familyKeychain = KymLiveFamilyKeychain()
        let hasKey = familyKeychain.loadElevenLabsAPIKey() != nil
        return VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Kicker("ElevenLabs (British en-GB)", muted: true)
            SecureField(hasKey ? "Saved · type to replace" : "Not set", text: $elevenLabsKeyInput)
                .textFieldStyle(.plain)
                .standardType(.uiHeadline)
                .foregroundStyle(theme.ink)
                .frame(minHeight: 28)
                .onSubmit { saveElevenLabsKey() }
            if !elevenLabsKeyInput.isEmpty {
                Button("Save ElevenLabs key") {
                    saveElevenLabsKey()
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .padding(StandardSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private func saveElevenLabsKey() {
        let value = elevenLabsKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        let familyKeychain = KymLiveFamilyKeychain()
        try? familyKeychain.saveElevenLabsAPIKey(value)
        elevenLabsKeyInput = ""
        keySaveBanner = "Saved the ElevenLabs British voice key to the shared family Keychain."
        keyRevision += 1
    }

    private func keyCard(_ name: String, provider: AIProvider, text: Binding<String>, keyStore: KeychainFrontierKeyStore) -> some View {
        let familyKeychain = KymLiveFamilyKeychain()
        let hasKey = keyStore.hasKey(for: provider) || (provider == .gemini && familyKeychain.loadGeminiAPIKey() != nil)
        return VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
            Kicker(name, muted: true)
            SecureField(hasKey ? "Saved · type to replace" : "Not set", text: text)
                .textFieldStyle(.plain)
                .standardType(.uiHeadline)
                .foregroundStyle(theme.ink)
                .frame(minHeight: 28)
                .onSubmit { saveKey(name, provider: provider, text: text, keyStore: keyStore) }
            if !text.wrappedValue.isEmpty {
                Button("Save \(name) key") {
                    saveKey(name, provider: provider, text: text, keyStore: keyStore)
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .padding(StandardSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: StandardRadius.md, style: .continuous).strokeBorder(theme.hairline(), lineWidth: 1))
    }

    private func saveKey(_ name: String, provider: AIProvider, text: Binding<String>, keyStore: KeychainFrontierKeyStore) {
        let value = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        keyStore.saveKey(value, for: provider)
        if provider == .gemini {
            let familyKeychain = KymLiveFamilyKeychain()
            try? familyKeychain.saveAPIKey(value, provider: "gemini")
        }
        text.wrappedValue = ""
        keySaveBanner = "Saved the \(name) key to the Keychain."
        keyRevision += 1
    }

    private var coachPreferences: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                Text("How the coach talks")
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                Text("Your choices shape its manner. They cannot override safety or the truth.")
                    .standardType(.uiCaption)
                    .foregroundStyle(theme.mute(theme.ink))
                Text("\(store.activeSoul.displayName) teaches by: \(store.activeSoul.teachingStyle.primaryMethod)")
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                PaperFieldLabel("British English voice preset (en-GB)")
                FlowLayout(spacing: StandardSpacing.xs) {
                    ForEach(KymLiveBritishVoiceCatalog.presets) { preset in
                        PatternedChip(preset.displayName, isSelected: britishVoicePresetID == preset.id) {
                            britishVoicePresetID = preset.id
                        }
                    }
                }
            }
            ForEach(AgentSoulOverrideKey.allCases) { key in
                VStack(alignment: .leading, spacing: StandardSpacing.xxs) {
                    PaperFieldLabel(key.title)
                    FlowLayout(spacing: StandardSpacing.xs) {
                        ForEach(key.allowedValues, id: \.self) { value in
                            PatternedChip(value, isSelected: store.soulParentOverrides[key.rawValue] == value) {
                                store.setSoulOverride(key: key, value: value)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Each engine the app runs on, said once, in a plain sentence. This is the only place
    /// these names appear.
    private var engineGlossary: some View {
        let hash = String(TutorConstitution.policyHash.prefix(12))
        let entries: [(String, String)] = [
            ("FSRS", "The review timer. It decides when a card comes back, so it returns just before it would be forgotten."),
            ("BKT", "A running estimate, from her answers, of how likely she is to know each skill. It only picks what to practise next; it never lights a lamp."),
            ("CPA", "Concrete, pictorial, abstract: something to move first, then a drawing, then the symbols."),
            ("Wolfram", "A maths engine used to double-check the answers to some practice questions."),
            ("Gemini", "Google's AI model, one of the cloud coaches. It is used only when its key is saved above and the routing allows the cloud."),
            ("OpenAI", "Another cloud AI provider, used the same way and only with its key."),
            ("Constitution", "The coach's rule book, version \(TutorConstitution.version). It puts her safety and her own thinking ahead of every setting on this page."),
            ("SHA-256", "A fingerprint of that rule book. If one word of the rules changes, the fingerprint changes. Today it starts \(hash)."),
            ("KORA", "A set of child-safety test conversations. The coach is run against them and must pass every one."),
            ("Council", "Four automatic reviewers that read each coach answer after it is given and flag any that should be said better.")
        ]
        return VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            ForEach(entries, id: \.0) { name, sentence in
                HStack(alignment: .firstTextBaseline, spacing: StandardSpacing.sm) {
                    Text(name)
                        .standardType(.uiBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.ink)
                        .frame(width: 104, alignment: .leading)
                    Text(sentence)
                        .standardType(.uiBody)
                        .foregroundStyle(theme.mute(theme.ink))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var promptSegments: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.md) {
            Text("The coach's instructions, in parts. The rule book sits above all of them and cannot be switched off.")
                .standardType(.uiCaption)
                .foregroundStyle(theme.mute(theme.ink))
            ForEach(PromptSegmentComposer.catalog) { segment in
                let isEnabled = store.promptSegmentSwitches[segment.id] ?? segment.defaultEnabled
                VStack(alignment: .leading, spacing: StandardSpacing.xs) {
                    Toggle(isOn: Binding(
                        get: { isEnabled },
                        set: { store.setPromptSegmentEnabled(id: segment.id, enabled: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(segment.title)
                                .standardType(.uiBody)
                                .fontWeight(.semibold)
                                .foregroundStyle(theme.ink)
                            Text(segment.subtitle)
                                .standardType(.uiCaption)
                                .foregroundStyle(theme.mute(theme.ink))
                        }
                    }
                    .tint(theme.ink)
                    Text(segment.markdownBody)
                        .standardType(.uiCaption)
                        .foregroundStyle(theme.mute(theme.ink))
                        .padding(StandardSpacing.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: StandardRadius.sm).fill(theme.surface))
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Button("Reset to recommended defaults") {
                store.resetCustomisationDefaults()
            }
            .buttonStyle(TextLinkButtonStyle(arrow: false))
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(InkButtonStyle())
                .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: Pieces

    private func plainToggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .standardType(.uiHeadline)
                    .foregroundStyle(theme.ink)
                Text(detail)
                    .standardType(.uiBody)
                    .foregroundStyle(theme.mute(theme.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(theme.ink)
    }

    private func labelled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: StandardSpacing.xs) {
            PaperFieldLabel(label)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func twoUp<Leading: View, Trailing: View>(
        @ViewBuilder _ leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        let lead = leading()
        let trail = trailing()
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: StandardSpacing.md) {
                lead.frame(minWidth: 240)
                trail.frame(minWidth: 240)
            }
            VStack(alignment: .leading, spacing: StandardSpacing.md) {
                lead
                trail
            }
        }
    }

    private func menuRow<Option: Hashable>(
        _ current: String,
        options: [Option],
        label: @escaping (Option) -> String,
        select: @escaping (Option) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(label(option)) { select(option) }
            }
        } label: {
            HStack {
                Text(current)
                    .lineLimit(1)
                Spacer(minLength: StandardSpacing.xs)
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundStyle(theme.mute(theme.ink))
            }
            .paperField()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    static func tierLabel(_ tier: CompanionWorkbookTierFilter) -> String {
        switch tier {
        case .allTiers: "All 3"
        case .focus: "Focus"
        case .practice: "Practice"
        case .challenge: "Challenge"
        }
    }

    static func providerLabel(_ provider: AIProvider) -> String {
        switch provider {
        case .auto: "Choose for me"
        case .local: "On this device"
        case .gemini: "Google · Gemini"
        case .anthropic: "Anthropic · Claude"
        case .openAI: "OpenAI"
        }
    }

    static func policyLabel(_ policy: AIFeaturePolicy) -> String {
        switch policy {
        case .localOnly: "Only on this device"
        case .localPreferred: "On this device first, cloud if needed"
        case .frontierPreferred: "Cloud first, this device when offline"
        case .frontierOnly: "Cloud only"
        }
    }
}
