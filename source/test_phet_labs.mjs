import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readdirSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const require = createRequire(import.meta.url);
const labs = require('../KymMaths/KymMaths/Resources/PatternedWorldBook/phet_labs.js');

// 1. Ch 1: Number Line Distance vs Directed Change
{
  const st = labs.createCh01State();
  let ev = labs.evalCh01(st);
  assert.equal(ev.directed, 7);
  assert.equal(ev.distance, 7);
  assert.equal(ev.spansZero, true);
  assert.equal(ev.goalReached, false);

  st.a = 4;
  st.b = -3;
  ev = labs.evalCh01(st);
  assert.equal(ev.directed, -7);
  assert.equal(ev.distance, 7);
  assert.equal(ev.goalReached, true);

  st.a = -5;
  st.b = -5;
  ev = labs.evalCh01(st);
  assert.equal(ev.distance, 0);
  assert.equal(ev.spansZero, false);
}

// 2. Ch 2: Double Number Line Unit Rate & Scaling
{
  const st = labs.createCh02State();
  st.topUnit = 3;
  st.bottomUnit = 4;
  st.probeScale = 1;
  let ev = labs.evalCh02(st);
  assert.equal(ev.unitRatio, 0.75);
  assert.equal(ev.topAtProbe, 0.75);
  assert.equal(ev.goalReached, false);

  st.probeScale = 5;
  ev = labs.evalCh02(st);
  assert.equal(ev.topAtProbe, 3.75);
  assert.equal(ev.goalReached, true);
}

// 3. Ch 3: Two-Hand Ratio Tuner & Compare Blind
{
  const st = labs.createCh03State();
  let ev = labs.evalCh03(st);
  assert.equal(ev.inProportion, true);
  assert.equal(ev.goalReached, false);

  st.left = 4;
  st.right = 6;
  ev = labs.evalCh03(st);
  assert.equal(ev.inProportion, true);
  assert.equal(ev.goalReached, true);

  st.compareTargetLeft = 2;
  st.compareTargetRight = 3;
  st.compareUserLeft = 4;
  st.compareUserRight = 5;
  ev = labs.evalCh03(st);
  assert.equal(ev.actualSame, false);
}

// 4. Ch 4: Area Model Scale, Generic Negative & Factor It
{
  const st = labs.createCh04State();
  st.mode = 'area-generic';
  st.x = 5;
  st.p = -3;
  st.q = 2;
  let ev = labs.evalCh04(st);
  assert.equal(ev.x2, 25);
  assert.equal(ev.px, -15);
  assert.equal(ev.qx, 10);
  assert.equal(ev.pq, -6);
  assert.equal(ev.total, 14);
  assert.equal(ev.cancelsMiddle, false);

  // Difference of two squares cancellation: (x - 3)(x + 3)
  st.p = -3;
  st.q = 3;
  ev = labs.evalCh04(st);
  assert.equal(ev.linearSum, 0);
  assert.equal(ev.cancelsMiddle, true);

  // Reverse Factor-It check (puzzle 0 targets 2 and 5, in either order)
  st.mode = 'area-factor';
  st.factorPuzzleIdx = 0;
  st.guessP = 5;
  st.guessQ = 2;
  ev = labs.evalCh04(st);
  assert.equal(ev.factorSolved, true);
  assert.equal(ev.goalReached, true);
}

// 5. Ch 5: Equality Explorer (Symmetry Lock, Tilt, Zero Pairs, Isolate x)
{
  const st = labs.createCh05State(0); // 3x + 4 = x + 10 (hiddenX = 3)
  let ev = labs.evalCh05(st);
  assert.equal(ev.balanced, true);
  assert.equal(ev.isolated, false);
  assert.equal(ev.solvedValue, null);

  // Subtract x with symmetry lock ON -> 2x + 4 = 10
  assert.equal(labs.applyCh05Op(st, 'both', 'x', -1), true);
  assert.equal(st.leftX, 2);
  assert.equal(st.rightX, 0);
  assert.ok(st.zeroPairsCleared >= 1);
  assert.equal(labs.evalCh05(st).balanced, true);

  // Subtract 4 -> 2x = 6 (each subtract-1 on positive ones increments zeroPairsCleared)
  const beforeOnesZP = st.zeroPairsCleared;
  for (let i = 0; i < 4; i++) labs.applyCh05Op(st, 'both', 'ones', -1);
  assert.ok(st.zeroPairsCleared > beforeOnesZP);
  assert.equal(st.leftOnes, 0);
  assert.equal(st.rightOnes, 6);

  // Divide by 2 -> x = 3 (isolated!)
  assert.equal(labs.applyCh05Op(st, 'both', 'div', 2), true);
  ev = labs.evalCh05(st);
  assert.equal(ev.balanced, true);
  assert.equal(ev.isolated, true);
  assert.equal(ev.solvedValue, 3);
  assert.equal(ev.goalReached, true);

  // Turning off symmetry lock lets learner unbalance & undo cleanly
  st.symLock = false;
  labs.applyCh05Op(st, 'left', 'ones', 2);
  ev = labs.evalCh05(st);
  assert.equal(ev.balanced, false);
  assert.ok(Math.abs(ev.tiltRad) > 0.01);
  assert.equal(labs.undoCh05(st), true);
  assert.equal(labs.evalCh05(st).balanced, true);
}

// 6. Ch 7: Graphing Lines (Point Probe + Perpendicular Ghost) & Rule Machine Non-Commutativity
{
  const st = labs.createCh07State();
  let ev = labs.evalCh07(st);
  assert.equal(ev.m, 2);
  assert.equal(ev.c, 1);
  assert.equal(ev.probeOnLine, true);

  // Pin ghost m=2, set perpendicular line m=-0.5 through (0,1) and (2,0)
  st.ghost = { m: 2, c: 1 };
  st.p1 = { x: 0, y: 1 };
  st.p2 = { x: 2, y: 0 };
  st.probe = { x: 2, y: 0 };
  ev = labs.evalCh07(st);
  assert.equal(ev.isPerpGhost, true);
  assert.equal(ev.probeOnLine, true);
  assert.equal(ev.goalReached, true);

  // Rule Machine: (4 + 2) * 3 = 18 vs (4 * 3) + 2 = 14
  st.mode = 'function-machine';
  st.testInput = 4;
  st.op1 = 'add2';
  st.op2 = 'mul3';
  const outA = labs.evalCh07(st).outVal;
  st.op1 = 'mul3';
  st.op2 = 'add2';
  const outB = labs.evalCh07(st).outVal;
  assert.equal(outA, 18);
  assert.equal(outB, 14);
  assert.notEqual(outA, outB);
}

// 7. Ch 13: Live Sampler SE Scaling
{
  const sSmall = labs.createCh13State();
  sSmall.sampleN = 4;
  labs.drawSamplesCh13(sSmall, 15);
  const evSmall = labs.evalCh13(sSmall);
  assert.equal(evSmall.count, 15);
  assert.equal(evSmall.theoreticalSE, 6);

  const sBig = labs.createCh13State();
  sBig.sampleN = 16;
  labs.drawSamplesCh13(sBig, 15);
  const evBig = labs.evalCh13(sBig);
  assert.equal(evBig.theoreticalSE, 3);
  assert.ok(evBig.theoreticalSE < evSmall.theoreticalSE);
}

// 8. Ch 14: Mean Fulcrum, Median Robustness to Outliers & Best-Fit Residuals
{
  const st = labs.createCh14State();
  const baseEv = labs.evalCh14(st);
  const baseMean = baseEv.meanVal;
  const baseMed = baseEv.medianVal;

  // Push largest dot far right to 19 -> mean jumps, median stays identical!
  st.dots[st.dots.length - 1] = 19;
  const skewedEv = labs.evalCh14(st);
  assert.ok(skewedEv.meanVal > baseMean + 0.8);
  assert.equal(skewedEv.medianVal, baseMed);

  // Placing fulcrum at mean zeros torque
  st.fulcrumX = skewedEv.meanVal;
  const balEv = labs.evalCh14(st);
  assert.ok(Math.abs(balEv.torque) < 1e-6);
  assert.equal(balEv.fulcrumBalanced, true);

  // OLS best fit beats tilted My Line
  st.mode = 'best-fit';
  const fitEv = labs.evalCh14(st);
  assert.ok(fitEv.bestSSR < fitEv.mySSR);
  st.mySlope = fitEv.ols.m;
  st.myIntercept = fitEv.ols.c;
  assert.equal(labs.evalCh14(st).fitGoal, true);
}

// 9. Ch 17 & Ch 18: Calculus Grapher (Smooth, Cusp Jump & Signed Area)
{
  const smooth = labs.evalCalcFunction('smooth', 2.0);
  assert.ok(Math.abs(smooth.f - 2.0) < 1e-6);
  assert.ok(Math.abs(smooth.fp - 2.0) < 1e-6);

  const cuspLeft = labs.evalCalcFunction('cusp', 1.2);
  const cuspAt = labs.evalCalcFunction('cusp', 1.5);
  const cuspRight = labs.evalCalcFunction('cusp', 1.8);
  assert.equal(cuspLeft.fp, -1);
  assert.equal(cuspAt.definedDeriv, false);
  assert.equal(cuspRight.fp, 1);

  const st17 = labs.createCalcState(17);
  st17.predictRevealed = true;
  assert.equal(labs.evalCalcState(st17).goalReached, false, 'Revealing flat prediction before sketching must not auto-solve');
  st17.predictNodes.forEach(n => { n.y = n.x; });
  assert.equal(labs.evalCalcState(st17).goalReached, true);
}

// 10. Voicing 4-Part Structure Across All 21 Chapters
for (let ch = 0; ch <= 20; ch++) {
  const v = labs.buildVoicingForChapter(ch, { a: 2, b: 3, dots: [4, 6, 8], dotsLength: 3, samples: [50], curveKind: 'smooth', refX: 1, left: 2, right: 3, targetLeft: 2, targetRight: 3, p1: { x: 0, y: 1 }, p2: { x: 2, y: 5 }, probe: { x: 1, y: 3 }, leftX: 1, leftOnes: 0, rightX: 0, rightOnes: 3, hiddenX: 3 }, { a: 2, b: 3, c: 4 }, { val: { f: 0.5, fp: 1, F: 0.16, definedDeriv: true }, meanVal: 6, medianVal: 6, iqr: 2, count: 1, theoreticalSE: 4, meanOfMeans: 50, p: 2, q: 3, linearSum: 5, pq: 6, unitRatio: 0.5, topAtProbe: 1, directed: 1, distance: 1, balanced: true, isolated: true, solvedValue: 3, inProportion: true, probeOnLine: true }, 'Test readout');
  assert.ok(v.name && v.name.length > 0, `Ch ${ch} missing voicing name`);
  assert.ok(v.context && v.context.length > 0, `Ch ${ch} missing voicing context`);
}

// 11. All 21 Atlas 3D chapter.js sonify() calls work cleanly with a mock WebAudio AudioContext
let scheduledOscillators = 0;
function makeMockAudioContext() {
  return {
    state: 'running',
    currentTime: 0,
    sampleRate: 44100,
    destination: {},
    resume() { return Promise.resolve(); },
    createOscillator() {
      scheduledOscillators += 1;
      return {
        type: 'sine',
        frequency: { setValueAtTime() {}, exponentialRampToValueAtTime() {}, setTargetAtTime() {} },
        connect() {},
        start() {},
        stop() {}
      };
    },
    createGain() {
      return {
        gain: { setValueAtTime() {}, exponentialRampToValueAtTime() {}, setTargetAtTime() {} },
        connect() {}
      };
    },
    createBuffer(ch, len) { return { getChannelData() { return new Float32Array(len); } }; },
    createBufferSource() { return { buffer: null, connect() {}, start() {} }; },
    createBiquadFilter() { return { type: 'bandpass', frequency: { setValueAtTime() {} }, Q: { setValueAtTime() {} }, connect() {} }; },
    createStereoPanner() { return { pan: { setValueAtTime() {} }, connect() {} }; }
  };
}

const mathsDir = path.resolve('KymMaths/KymMaths/Resources/PatternedWorldBook/atlas/examples/maths');
const chapterDirs = readdirSync(mathsDir).filter(d => /^ch\d{2}-/.test(d)).sort();
assert.equal(chapterDirs.length, 21, 'Expected 21 maths chapters in Atlas');

for (const dir of chapterDirs) {
  const mod = await import(pathToFileURL(path.join(mathsDir, dir, 'chapter.js')).href);
  const chObj = mod.CHAPTER || mod.chapter;
  assert.ok(typeof chObj.sonify === 'function', `${dir} missing sonify`);
  const st = chObj.state(0.5, false);
  const ctx = makeMockAudioContext();
  const before = scheduledOscillators;
  for (let pIdx = 0; pIdx < Math.min(3, chObj.PAGES.length); pIdx++) {
    chObj.sonify(ctx, st, pIdx, chObj.defaultParams);
  }
  assert.ok(scheduledOscillators > before, `${dir} sonify did not schedule any audio tone`);
}

// 12. stripHtml <br> separator fix + Atelier SVG & Byrne Reactive Prose coverage
assert.equal(labs.stripHtml('In both: 7<br><b>In at least one: 26</b>'), 'In both: 7 · In at least one: 26');

const atelier = await import(pathToFileURL(path.resolve('KymMaths/KymMaths/Resources/PatternedWorldBook/atelier_stage.mjs')).href);

const ch00Eval = atelier.evalCh00FromParams({ a: 18, b: 15, c: 7 });
assert.equal(ch00Eval.union, 26);
assert.equal(ch00Eval.outside, 4);

const svgCases = [
  [0, {}, { a: 18, b: 15, c: 7 }, {}],
  [1, labs.createCh01State(), { a: 24, b: 36, c: 2 }, labs.evalCh01(labs.createCh01State())],
  [1, { ...labs.createCh01State(), mode: 'classic-turns' }, { a: 24, b: 36, c: 2 }, {}],
  [2, labs.createCh02State(), {}, labs.evalCh02(labs.createCh02State())],
  [2, { ...labs.createCh02State(), mode: 'recurring' }, { a: 36, b: 3, c: 4 }, {}],
  [3, labs.createCh03State(), {}, labs.evalCh03(labs.createCh03State())],
  [3, { ...labs.createCh03State(), mode: 'compare-blind' }, {}, labs.evalCh03({ ...labs.createCh03State(), mode: 'compare-blind' })],
  [3, { ...labs.createCh03State(), mode: 'compound-growth' }, { a: 3, b: 5, c: 8 }, {}],
  [4, labs.createCh04State(), {}, labs.evalCh04(labs.createCh04State())],
  [4, { ...labs.createCh04State(), mode: 'area-generic', p: -2, q: 3 }, {}, labs.evalCh04({ ...labs.createCh04State(), mode: 'area-generic', p: -2, q: 3 })],
  [4, { ...labs.createCh04State(), mode: 'area-factor' }, {}, labs.evalCh04({ ...labs.createCh04State(), mode: 'area-factor' })],
  [5, labs.createCh05State(0), {}, labs.evalCh05(labs.createCh05State(0))],
  [6, { mode: 'default' }, { a: 5, b: 1, c: 1 }, {}],
  [7, labs.createCh07State(), {}, labs.evalCh07(labs.createCh07State())],
  [7, { ...labs.createCh07State(), mode: 'function-machine' }, {}, labs.evalCh07({ ...labs.createCh07State(), mode: 'function-machine' })],
  [8, { mode: 'default' }, { a: 50, b: 60, c: 6 }, {}],
  [9, { mode: 'default' }, { a: 6, b: 4, c: 2 }, {}],
  [10, { mode: 'default' }, { a: 4, b: 12, c: 90 }, {}],
  [11, { mode: 'default' }, { a: 2, b: 0, c: 0 }, {}],
  [12, { mode: 'default' }, { a: 30, b: 2, c: 60 }, {}],
  [13, labs.createCh13State(), {}, labs.evalCh13(labs.createCh13State())],
  [13, { ...labs.createCh13State(), mode: 'se-wald' }, { a: 12, b: 16, c: 1 }, {}],
  [14, labs.createCh14State(), {}, labs.evalCh14(labs.createCh14State())],
  [14, { ...labs.createCh14State(), mode: 'level-out' }, {}, labs.evalCh14({ ...labs.createCh14State(), mode: 'level-out' })],
  [14, { ...labs.createCh14State(), mode: 'best-fit', showBestFit: true }, {}, labs.evalCh14({ ...labs.createCh14State(), mode: 'best-fit', showBestFit: true })],
  [14, { ...labs.createCh14State(), mode: 'histogram' }, { a: 25, b: 30, c: 18 }, {}],
  [15, { mode: 'default' }, { a: 6, b: 3, c: 50 }, {}],
  [16, { mode: 'default' }, { a: 2, b: 95, c: 5 }, {}],
  [17, labs.createCalcState(17), {}, labs.evalCalcState(labs.createCalcState(17))],
  [18, labs.createCalcState(18), {}, labs.evalCalcState(labs.createCalcState(18))],
  [19, { mode: 'default' }, { a: 3.5, b: 2.0, c: 60 }, {}],
  [20, { mode: 'default' }, { a: 2.0, b: 1.0, c: 2.0 }, {}],
];

const BANNED_SVG_JARGON = ['SSR =', 'OLS =', 'MAD ATELIER', 'stair-pairing invariant', 'lockstep'];
for (const [chNum, st, prm, ev] of svgCases) {
  const lightSvg = atelier.renderAtelierSvg(chNum, st, prm, ev, { isDark: false, quirk: 'slightly-quirky' });
  const darkSvg = atelier.renderAtelierSvg(chNum, st, prm, ev, { isDark: true, quirk: 'atelier' });
  assert.ok(typeof lightSvg === 'string' && lightSvg.includes('<svg'), `Ch ${chNum} (${st.mode || 'default'}) light SVG failed`);
  assert.ok(typeof darkSvg === 'string' && darkSvg.includes('<svg'), `Ch ${chNum} (${st.mode || 'default'}) dark SVG failed`);
  for (const word of BANNED_SVG_JARGON) {
    assert.ok(!lightSvg.includes(word), `Ch ${chNum} light SVG contains jargon "${word}"`);
    assert.ok(!darkSvg.includes(word), `Ch ${chNum} dark SVG contains jargon "${word}"`);
  }
}

// Regressions:
// - Ch 0 overlap handle drag formula roundtrips accurately across [least..most]
{
  const p = { a: 18, b: 15, c: 7 };
  const s = atelier.evalCh00FromParams(p);
  const ratio = s.most > 0 ? (s.inter - s.least) / Math.max(1, s.most - s.least || s.most) : 0;
  const sep = 122 - ratio * 72;
  const cxB = 280 + sep * 0.5;
  const recoveredRatio = Math.min(1, Math.max(0, (61 - (cxB - 280)) / 36));
  const recoveredInter = Math.round(s.least + recoveredRatio * (s.most - s.least));
  assert.equal(recoveredInter, s.inter);
}

// - Ch 5 beam tilts DOWN on left (negative tiltRad) when left > right
{
  const st = labs.createCh05State(0);
  st.symLock = false;
  labs.applyCh05Op(st, 'left', 'ones', 2);
  const ev = labs.evalCh05(st);
  assert.equal(ev.balanced, false);
  assert.ok(ev.tiltRad < 0, `Expected left>right to tilt left pan down (tiltRad < 0), got ${ev.tiltRad}`);
}

// - Ch 4 formatSignedPoly strips 0x and 1x cleanly
assert.equal(labs.formatSignedPoly(0, -9), 'x² − 9');
assert.equal(labs.formatSignedPoly(1, 0), 'x² + x');

// - Ch 14 mean-balance hides Mean/Median text before Reveal, shows after Reveal
{
  const st14 = labs.createCh14State();
  st14.revealedCenter = false;
  const ev14 = labs.evalCh14(st14);
  const hiddenSvg = atelier.renderAtelierSvg(14, st14, {}, ev14, {});
  assert.ok(!hiddenSvg.includes('Mean '), 'Ch 14 SVG must not spoil Mean before Reveal');
  assert.ok(!hiddenSvg.includes('Median '), 'Ch 14 SVG must not spoil Median before Reveal');
  st14.revealedCenter = true;
  const revealedSvg = atelier.renderAtelierSvg(14, st14, {}, ev14, {});
  assert.ok(revealedSvg.includes('Mean '), 'Ch 14 SVG should show Mean after Reveal');
  assert.ok(revealedSvg.includes('Median '), 'Ch 14 SVG should show Median after Reveal');
}

// - Ch 17 predictNodes start flat on y=0; Ch 18 goalReached=false on load then true after sweep
{
  const st17 = labs.createCalcState(17);
  assert.ok(st17.predictNodes.every(n => n.y === 0), 'Ch 17 prediction sketch should start flat at y = 0');

  const st18 = labs.createCalcState(18);
  assert.equal(labs.evalCalcState(st18).goalReached, false, 'Ch 18 goalReached must start false');
  st18.interacted = true;
  st18.minRefX = 0.6;
  st18.maxRefX = 2.4;
  assert.equal(labs.evalCalcState(st18).goalReached, true, 'Ch 18 goalReached should become true after sweep');
}

// - Ch 3 compare-blind requires explicit prediction + reveal for goalReached
{
  const st3 = labs.createCh03State();
  st3.mode = 'compare-blind';
  st3.compareTargetLeft = 2;
  st3.compareTargetRight = 3;
  st3.compareUserLeft = 4;
  st3.compareUserRight = 5;
  st3.compareRevealed = true;
  st3.comparePrediction = null;
  assert.equal(labs.evalCh03(st3).goalReached, false);
  st3.comparePrediction = 'different';
  assert.equal(labs.evalCh03(st3).goalReached, true);
  const svg3 = atelier.renderAtelierSvg(3, st3, {}, labs.evalCh03(st3), {});
  assert.ok(svg3.includes('Correct!'), `Expected SVG reveal to acknowledge prediction, got ${svg3.slice(0, 300)}`);
}

// - Ch 7 mysteryMode revealed SVG shows mysterySecret ops, not user guesses
{
  const st7 = labs.createCh07State();
  st7.mode = 'function-machine';
  st7.mysteryMode = true;
  st7.mysteryRevealed = true;
  st7.mysterySecret = ['mul2', 'add2'];
  st7.op1 = 'sub3';
  st7.op2 = 'div2';
  const ev7 = labs.evalCh07(st7);
  const svg7 = atelier.renderAtelierSvg(7, st7, {}, ev7, {});
  assert.ok(svg7.includes('Two-Step Rule: × 2  then  + 2'), `Expected revealed secret ops, got ${svg7.slice(0, 300)}`);
}

for (let ch = 0; ch <= 20; ch++) {
  const st = ch === 0 ? {} : (ch === 1 ? labs.createCh01State() : (ch === 2 ? labs.createCh02State() : (ch === 3 ? labs.createCh03State() : (ch === 4 ? labs.createCh04State() : (ch === 5 ? labs.createCh05State(0) : (ch === 7 ? labs.createCh07State() : (ch === 13 ? labs.createCh13State() : (ch === 14 ? labs.createCh14State() : ((ch === 17 || ch === 18) ? labs.createCalcState(ch) : {})))))))));
  const ev = labs.evalChapterData(ch, st);
  const html = atelier.renderReactiveProse(ch, st, { a: 2, b: 3, c: 4 }, ev);
  assert.ok(typeof html === 'string' && html.includes('<p>') && html.includes('tk-aside'), `Ch ${ch} reactive prose missing`);
  for (const word of BANNED_SVG_JARGON) {
    assert.ok(!html.includes(word), `Ch ${ch} reactive prose contains jargon "${word}"`);
  }
}

console.log(`PASS  test_phet_labs (${chapterDirs.length} Atlas sonify chapters + ${svgCases.length} Atelier SVG views + all 21 prose chapters + invariants verified)`);
