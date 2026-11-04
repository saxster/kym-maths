import SwiftUI

// MARK: - iPadOS 27 & macOS System Surface Widget Cards (Backed by group.com.kymaia.science)

public struct KymMathsDeadlineSmallWidgetCard: View {
    let snapshot: KymMathsSystemSnapshot

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(Color.kymaiaPrimary)
                Text("NEXT TARGET")
                    .font(Typography.eyebrow)
                    .foregroundStyle(Color.kymaiaPrimary)
                Spacer()
            }

            Text(snapshot.nextDeadlineTitle)
                .font(Typography.subheadline.weight(.bold))
                .foregroundStyle(Color.kymaiaInk)
                .lineLimit(2)

            if let dueDate = snapshot.nextDeadlineDate {
                Text(dueDate, style: .relative)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.kymaiaWarning)
            }

            Spacer(minLength: 4)

            HStack {
                Label("\(snapshot.independentProofsCount)/\(snapshot.totalQuestionsCount)", systemImage: "checkmark.seal.fill")
                    .font(Typography.caption.monospacedDigit())
                    .foregroundStyle(Color.kymaiaSuccess)
                Spacer()
                Text("\(snapshot.dueCardsCount) due")
                    .font(Typography.caption.monospacedDigit())
                    .foregroundStyle(Color.kymaiaMutedInk)
            }
        }
        .padding(Spacing.md)
        .frame(width: 175, height: 155, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.kymaiaElevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
        )
    }
}

public struct KymMathsTodayPlanMediumWidgetCard: View {
    let snapshot: KymMathsSystemSnapshot

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label("KYMMATHS · TODAY'S 3-STEP PLAN", systemImage: "function")
                    .font(Typography.eyebrow)
                    .foregroundStyle(Color.kymaiaPrimary)
                Spacer()
                Text(snapshot.learnerName)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.kymaiaMutedInk)
            }

            Text(snapshot.activeUnitTitle)
                .font(Typography.subheadline.weight(.bold))
                .foregroundStyle(Color.kymaiaInk)
                .lineLimit(1)

            Text("Due Card: \(snapshot.dueCardHeadline)")
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaMutedInk)
                .lineLimit(2)

            Spacer(minLength: 4)

            HStack(spacing: Spacing.xs) {
                JournalBadge(
                    text: "\(snapshot.dueCardsCount) FSRS Due",
                    symbol: "clock.arrow.circlepath",
                    tone: .accent
                )
                JournalBadge(
                    text: "\(snapshot.independentProofsCount) Proven",
                    symbol: "checkmark.seal.fill",
                    tone: .positive
                )
                JournalBadge(
                    text: "\(snapshot.secureProofsCount) Secure",
                    symbol: "lock.shield.fill",
                    tone: .info
                )
            }
        }
        .padding(Spacing.md)
        .frame(width: 340, height: 155, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.kymaiaElevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
        )
    }
}

public struct KymMathsLockScreenGaugeView: View {
    let snapshot: KymMathsSystemSnapshot

    private var masteryFraction: Double {
        guard snapshot.totalQuestionsCount > 0 else { return 0 }
        return min(1.0, Double(snapshot.independentProofsCount) / Double(snapshot.totalQuestionsCount))
    }

    public var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(Color.kymaiaHairline, lineWidth: 7)
                    .frame(width: 74, height: 74)
                Circle()
                    .trim(from: 0, to: masteryFraction)
                    .stroke(Color.kymaiaPrimary, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 74, height: 74)
                Text("\(Int(masteryFraction * 100))%")
                    .font(Typography.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.kymaiaInk)
            }
            Text("Lock Screen Gauge")
                .font(Typography.caption)
                .foregroundStyle(Color.kymaiaMutedInk)
        }
        .padding(Spacing.md)
        .frame(width: 150, height: 155)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.kymaiaElevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.kymaiaHairline, lineWidth: 1)
        )
    }
}

public struct KymMathsWidgetPreviewGallery: View {
    let store: AppStore

    private var currentSnapshot: KymMathsSystemSnapshot {
        SystemSurfaceSnapshotStore.readSnapshot() ?? KymMathsSystemSnapshot(
            generatedAt: Date(),
            learnerName: store.learnerDisplayName,
            dueCardsCount: store.dueFSRSCards.count,
            dueCardHeadline: store.dueFSRSCards.first?.frontPrompt ?? "All cards reviewed!",
            activeUnitTitle: "Ch \(store.selectedUnit.unitNumber) · \(store.selectedUnit.title)",
            independentProofsCount: store.overallIndependentProofCount,
            secureProofsCount: store.overallSecureCount,
            totalQuestionsCount: store.seedPack.schoolQuestions.count,
            nextDeadlineTitle: store.nextSchoolDeadline?.title ?? "Cambridge Checkpoint Prep",
            nextDeadlineDate: store.nextSchoolDeadline?.dueAt,
            deepLinkURLString: "kymmaths://today"
        )
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                KymMathsDeadlineSmallWidgetCard(snapshot: currentSnapshot)
                KymMathsTodayPlanMediumWidgetCard(snapshot: currentSnapshot)
                KymMathsLockScreenGaugeView(snapshot: currentSnapshot)
            }
            .padding(.vertical, 4)
        }
    }
}
