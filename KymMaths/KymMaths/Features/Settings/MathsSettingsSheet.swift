import SwiftUI

// MARK: - Settings & Customisation Sheet

struct MathsSettingsSheet: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeTokens) private var tokens

    private let paperStyles = ["grid", "dots", "lined", "blank", "cornell"]
    private let goalOptions = [15, 25, 40, 60]
    @State private var geminiKeyInput: String = ""
    @State private var anthropicKeyInput: String = ""
    @State private var openAIKeyInput: String = ""
    @State private var keySaveBanner: String?

    var body: some View {
        NavigationStack {
            JournalPage {
                // 1. Visual Theme & Palette
                JournalSection(
                    title: "Journal Colour Palette",
                    eyebrow: "9 WCAG-Audited Light Themes · Default: Apple Journal Lavender"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Choose the paper and ink palette for KymMaths. Every palette is audited for WCAG AAA body-copy legibility.")
                                .font(Typography.callout)
                                .foregroundStyle(tokens.secondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: Spacing.sm)], spacing: Spacing.sm) {
                                ForEach(CuratedColorScheme.allCases) { scheme in
                                    let schemeTokens = ThemeTokens.tokens(for: scheme)
                                    let isSelected = store.colorScheme == scheme
                                    Button {
                                        store.setTheme(scheme)
                                    } label: {
                                        HStack(spacing: Spacing.sm) {
                                            Circle()
                                                .fill(schemeTokens.accent)
                                                .frame(width: 22, height: 22)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(schemeTokens.primary.opacity(0.2), lineWidth: 1)
                                                )
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(scheme.displayName)
                                                    .font(Typography.subheadline.weight(.semibold))
                                                    .foregroundStyle(tokens.primary)
                                                Text(scheme.moodSubtitle)
                                                    .font(Typography.caption)
                                                    .foregroundStyle(tokens.secondary)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(tokens.accent)
                                            }
                                        }
                                        .padding(Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                                .fill(isSelected ? tokens.accentSubtle : tokens.surfaceElevated)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                                .strokeBorder(isSelected ? tokens.accent : tokens.borderSubtle, lineWidth: isSelected ? 1.5 : 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // 2. Curriculum & Missing School Workbook Customisation
                JournalSection(
                    title: "School Syllabus & 3-Tier Companion Workbook",
                    eyebrow: "Deborah Barton OUP Complete Mathematics 8 (2nd Ed.)"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Curriculum Lens")
                                .font(Typography.headline)
                                .foregroundStyle(tokens.primary)

                            ForEach(MathsCurriculumLens.allCases) { lens in
                                let isSelected = store.selectedCurriculumLens == lens
                                Button {
                                    store.selectedCurriculumLens = lens
                                } label: {
                                    HStack(alignment: .top, spacing: Spacing.sm) {
                                        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(isSelected ? tokens.accent : tokens.secondary)
                                            .padding(.top, 2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(lens.title)
                                                .font(Typography.subheadline.weight(.semibold))
                                                .foregroundStyle(tokens.primary)
                                            Text(lens.subtitle)
                                                .font(Typography.caption)
                                                .foregroundStyle(tokens.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: Spacing.radiusMD, style: .continuous)
                                            .fill(isSelected ? tokens.accentSubtle : tokens.surfaceElevated)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            Divider()

                            Text("Default Companion Workbook Tier")
                                .font(Typography.headline)
                                .foregroundStyle(tokens.primary)
                            Text("Because the school only provides the OUP Student Book without a separate Workbook, KymMaths generates a 3-Tier Singapore & Checkpoint Companion Workbook for every chapter.")
                                .font(Typography.caption)
                                .foregroundStyle(tokens.secondary)

                            AdaptiveOptionPicker(
                                options: CompanionWorkbookTierFilter.allCases,
                                selection: $store.defaultWorkbookTier,
                                label: { $0.title }
                            )
                        }
                    }
                }

                // 3. Visual Intuition -> Formula & Horizon Modules
                JournalSection(
                    title: "Visual Intuition → Formula & Horizon Modules",
                    eyebrow: "Pedagogical Engine & Singapore CPA"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Toggle(isOn: $store.showIntuitionBeforeFormula) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Always Show Visual Intuition → \"Aha!\" Bridge Before Symbolic Formula")
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(tokens.primary)
                                    Text("Displays the Concrete Manipulation, Structural Invariant, and Colour-Locked Term Mapping above every symbolic equation.")
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.secondary)
                                }
                            }
                            .tint(tokens.accent)

                            Divider()

                            Toggle(isOn: $store.showSingaporeBarModelsByDefault) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show Singapore CPA Bar-Model & Area Scaffolds by Default")
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(tokens.primary)
                                    Text("Pre-loads Singapore comparison bars, area tiles, and natural-frequency grids in problem practice.")
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.secondary)
                                }
                            }
                            .tint(tokens.accent)

                            Divider()

                            Toggle(isOn: $store.enableAdvancedHorizonModules) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enable Horizon Modules (Set Theory & Logic, Bayes, Trigonometry, Calculus & Linear Algebra)")
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(tokens.primary)
                                    Text("Unlocks Ch 0 (Set Theory & Logic), Ch 12 (Unit Circle & Trig), Ch 15 (Bayes' Theorem), Ch 17–18 (Calculus), and Ch 20 (2×2 Matrices & Eigenvectors).")
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.secondary)
                                }
                            }
                            .tint(tokens.accent)
                        }
                    }
                }

                // 3B. AI Mentor Constitution, Multi-Provider Routing & Bounded Soul Preferences (Ported from ../kym_tutor)
                JournalSection(
                    title: "AI Mentor Constitution, Routing & Bounded Preferences",
                    eyebrow: "Tutor Constitution \(TutorConstitution.version) · SHA-256 \(String(TutorConstitution.policyHash.prefix(12)))…"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("AI Routing Policy")
                                .font(Typography.headline)
                                .foregroundStyle(tokens.primary)
                            AdaptiveOptionPicker(
                                options: AIFeaturePolicy.allCases,
                                selection: $store.aiFeaturePolicy,
                                label: { $0.displayName }
                            )

                            Divider()

                            Text("Default AI Provider")
                                .font(Typography.headline)
                                .foregroundStyle(tokens.primary)
                            AdaptiveOptionPicker(
                                options: AIProvider.allCases,
                                selection: $store.defaultAIProvider,
                                label: { $0.displayName }
                            )

                            Divider()

                            Toggle(isOn: $store.allowRemoteCameraAIAnalysis) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Allow Remote Cloud Upload for Camera / Handwriting Images")
                                        .font(Typography.subheadline.weight(.semibold))
                                        .foregroundStyle(tokens.primary)
                                    Text("Off by default (strict privacy consent gate). When off, textbook scans and PencilKit working stay strictly on-device.")
                                        .font(Typography.caption)
                                        .foregroundStyle(tokens.secondary)
                                }
                            }
                            .tint(tokens.accent)

                            Divider()

                            Text("Allowlisted Parent Soul Preferences (Cannot Override Safety or Truth)")
                                .font(Typography.headline)
                                .foregroundStyle(tokens.primary)
                            ForEach(AgentSoulOverrideKey.allCases) { key in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(key.title)
                                        .font(Typography.caption.weight(.semibold))
                                        .foregroundStyle(tokens.secondary)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Spacing.xs) {
                                            ForEach(key.allowedValues, id: \.self) { val in
                                                JournalChip(
                                                    title: val,
                                                    systemImage: "slider.horizontal.3",
                                                    isSelected: store.soulParentOverrides[key.rawValue] == val
                                                ) {
                                                    store.setSoulOverride(key: key, value: val)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()

                            Text("Frontier API Keys (Stored Safely in macOS / iPadOS Keychain)")
                                .font(Typography.headline)
                                .foregroundStyle(tokens.primary)
                            HStack(spacing: Spacing.sm) {
                                SecureField("Gemini API Key", text: $geminiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                Button("Save Gemini") {
                                    KeychainFrontierKeyStore().saveKey(geminiKeyInput, for: .gemini)
                                    geminiKeyInput = ""
                                    keySaveBanner = "Saved Gemini API key to Keychain."
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                            HStack(spacing: Spacing.sm) {
                                SecureField("Anthropic API Key", text: $anthropicKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                Button("Save Claude") {
                                    KeychainFrontierKeyStore().saveKey(anthropicKeyInput, for: .anthropic)
                                    anthropicKeyInput = ""
                                    keySaveBanner = "Saved Anthropic API key to Keychain."
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                            HStack(spacing: Spacing.sm) {
                                SecureField("OpenAI API Key", text: $openAIKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                Button("Save OpenAI") {
                                    KeychainFrontierKeyStore().saveKey(openAIKeyInput, for: .openAI)
                                    openAIKeyInput = ""
                                    keySaveBanner = "Saved OpenAI API key to Keychain."
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())
                            }
                            if let banner = keySaveBanner {
                                Text(banner)
                                    .font(Typography.caption)
                                    .foregroundStyle(tokens.positive)
                            }
                        }
                    }
                }

                // 4. Scratchpad & Daily Goal
                JournalSection(
                    title: "Scratchpad & Daily Cadence",
                    eyebrow: "Personalisation"
                ) {
                    JournalCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("Learner Name")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                                Spacer()
                                TextField("Name", text: $store.learnerDisplayName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 220)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Default PencilKit Scratchpad Paper")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                                AdaptiveOptionPicker(
                                    options: paperStyles,
                                    selection: $store.defaultScratchpadPaperStyle,
                                    label: { $0.capitalized }
                                )
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Daily Practice Target (minutes)")
                                    .font(Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(tokens.primary)
                                AdaptiveOptionPicker(
                                    options: goalOptions,
                                    selection: $store.dailyPracticeGoalMinutes,
                                    label: { "\($0) min / day" }
                                )
                            }

                            Divider()

                            HStack {
                                Button("Reset to Recommended Defaults") {
                                    store.resetCustomisationDefaults()
                                }
                                .buttonStyle(JournalSecondaryButtonStyle())

                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings & Customisation")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.subheadline.weight(.semibold))
                }
            }
        }
    }
}
