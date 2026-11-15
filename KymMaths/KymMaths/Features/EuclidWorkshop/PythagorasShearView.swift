import SwiftUI

/// I.47's proof as Euclid's shear: each small square slides, turns and slides again until it is
/// a rectangle of the big square. A scrubber and play controls let her run it at her own pace.
struct PythagorasShearView: View {
    @Environment(\.standardTheme) private var theme
    var shear: PythagorasShear = .book
    @State private var t: Double = 0
    @State private var isPlaying = false

    /// Seconds for the whole run, two per move.
    private static let duration = 12.0

    var body: some View {
        VStack(alignment: .leading, spacing: StandardSpacing.sm) {
            Kicker("Watch the squares move")
            Canvas { context, size in draw(in: &context, size) }
                .frame(height: 360)
                .background(MathsFigureColor.paper)
                .clipShape(RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MathsFigureRadius.frame, style: .continuous)
                        .strokeBorder(MathsFigureColor.ink.opacity(0.12), lineWidth: 1)
                )
                .accessibilityElement()
                .accessibilityLabel("The squares on the two short sides sliding and turning into the square on the longest side")
                .accessibilityValue(shear.caption(at: t))
            Text(shear.caption(at: t))
                .patternedType(.readingDefault)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44, alignment: .topLeading)
            controls
        }
        .task(id: isPlaying) { await play() }
        .onAppear {
            #if DEBUG
            if let start = UserDefaults.standard.string(forKey: "EuclidShearT").flatMap(Double.init) { t = start }
            #endif
        }
    }

    private var controls: some View {
        HStack(spacing: StandardSpacing.xs) {
            Button {
                step(by: -1)
            } label: {
                Label("Back one move", systemImage: "backward.end.fill").labelStyle(.iconOnly)
            }
            .buttonStyle(OutlineButtonStyle())
            .disabled(t <= 0)

            Button {
                if t >= 1 { t = 0 }
                isPlaying.toggle()
            } label: {
                Label(isPlaying ? "Pause" : (t >= 1 ? "Play again" : "Play"),
                      systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(OutlineButtonStyle())

            Button {
                step(by: 1)
            } label: {
                Label("Forward one move", systemImage: "forward.end.fill").labelStyle(.iconOnly)
            }
            .buttonStyle(OutlineButtonStyle())
            .disabled(t >= 1)

            Slider(value: Binding(get: { t }, set: { isPlaying = false; t = $0 }), in: 0...1)
                .tint(theme.brass)
                .accessibilityLabel("How far the squares have moved")
        }
    }

    /// Jumps to the previous or next still.
    private func step(by direction: Int) {
        isPlaying = false
        let moves = Double(shear.motions.count)
        let here = t * moves
        let target = direction > 0 ? (here + 1e-6).rounded(.down) + 1 : (here - 1e-6).rounded(.up) - 1
        t = min(max(target / moves, 0), 1)
    }

    private func play() async {
        guard isPlaying else { return }
        var last = Date()
        while isPlaying, !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            let now = Date()
            t = min(1, t + now.timeIntervalSince(last) / Self.duration)
            last = now
            if t >= 1 { isPlaying = false }
        }
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, _ size: CGSize) {
        let xs = shear.allPoints.map(\.x), ys = shear.allPoints.map(\.y)
        let extent = BoardExtent(min: Vec2(x: xs.min()!, y: ys.min()!), max: Vec2(x: xs.max()!, y: ys.max()!))
        let viewport = BoardViewport(fitting: extent, in: size, margin: 20)
        let outline = MathsFigureColor.ink.opacity(0.28)

        // The three squares stay pencilled in, so she can see where each piece came from and goes.
        for square in [[shear.a, shear.b, shear.f, shear.g], [shear.a, shear.c, shear.k, shear.h],
                       [shear.b, shear.d, shear.e, shear.c]] {
            context.stroke(BoardPaths.polygon(square.map(viewport.toView)), with: .color(outline),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        context.stroke(BoardPaths.line(viewport.toView(shear.m), viewport.toView(shear.l)), with: .color(outline),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

        for piece in shear.interpolate(t: t) {
            let path = BoardPaths.polygon(piece.corners.map(viewport.toView))
            context.fill(path, with: .color(piece.role.figureColor.opacity(0.82)))
            context.stroke(path, with: .color(MathsFigureColor.ink.opacity(0.55)), lineWidth: 0.8)
        }

        let triangle = BoardPaths.polygon([shear.a, shear.b, shear.c].map(viewport.toView))
        context.stroke(triangle, with: .color(MathsFigureColor.ink), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
    }
}
