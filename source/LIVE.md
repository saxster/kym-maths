# KymMaths Live Interactive Widget & `@saxster/atlas` Specification

## Dual Interactive Stage Architecture
1. **Vendored `@saxster/atlas` 3D/2D Figures (`PatternedWorldBook/atlas/`):**
   - `maths/unit-circle` (8 pages: unit circle, sine shadow, cosine shadow, $\sin^2\theta+\cos^2\theta=1$ folding squares, radians, sine wave, tangent, quadrant signs)
   - `maths/calculus` (6 pages: secant to tangent, derivative function, stationary points, Riemann rectangles, Fundamental Theorem of Calculus, signed area)
   - `maths/linear-algebra` (6 pages: basis columns, shear & rotation, determinant area, singular collapse, eigenvectors, matrix composition $RS \neq SR$)
   - `maths/matrix-sandbox` (interactive $2\times 2$ matrix sandbox with draggable 3D $A\hat{\imath}$ and $A\hat{\jmath}$)
   - `maths/differential-equations` (6 pages: slope fields, exponential decay, logistic curve, phase plane, spiral sink, hyperbolic saddle)
   - `maths/fourier` (6 pages: epicycles, square wave, sawtooth, orthogonality, Parseval spectrum, Gibbs ears)
   - `maths/multivariable` (6 pages: surfaces & slices, tangent plane, contour & gradient $\nabla f$, directional derivative, divergence, curl)
   - `statistics/galton` (500-ball binomial pegboard & Central Limit Theorem explorer)
   - `statistics/bayes` (1,000-person unit square & posterior $P(D\mid +)$ explorer)
   - `statistics/error` (repeated readings & $\sigma/\sqrt{n}$ standard error explorer)
   - `statistics/hypothesis` ($p$-values, power & 95% confidence intervals explorer)
   - `economics/compound` (₹1,000/month at 8% 20-year compounding machine)
2. **Inline Interactive Intuition-to-Formula Widgets (`PatternedWorldBook/index.html`):**
   - Synchronised sliders + interactive SVG/Canvas geometry + colour-locked live symbolic formula evaluation + 1-tap `Stamp Challenge` bridge back to Swift (`window.webkit.messageHandlers.kymmathsBridge.postMessage`).
