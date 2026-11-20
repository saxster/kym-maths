// Ch 5 · Twin-Pan Balance Equations & Inequality Mirror — 3D Interactive Mathematics Atlas chapter.
import { SUBJECT } from '../subject.js';
import * as EKit from '../../../engine/math_kit.js';
import { BYRNE_THEME } from '../../../engine/theme.js';
import * as M from './model.js';

export const PAGES = [
  {
    tab: 'Balance Beam',
    fig: 'Figure 5.1 · Solving ax + b = cx + d by Symmetric Subtraction',
    title: 'Solving ax + b = cx + d by Symmetric Subtraction',
    alt: '3D fulcrum beam with red variable x-blocks and blue unit weights staying level as matching weights are removed.',
    body: ['3D fulcrum beam with red variable x-blocks and blue unit weights staying level as matching weights are removed.'],
    cam: { target: [0, 0.15, 0], az: 16, el: 20, dist: 5.8 },
    lit: 'beam_arm',
    parts: ['beam_arm', 'left_pan', 'right_pan'],
    look: { xray: 0, section: 0 },
  },
  {
    tab: 'Subject Onion',
    fig: 'Figure 5.2 · Changing the Subject of a Formula by Reverse Operations',
    title: 'Changing the Subject of a Formula by Reverse Operations',
    alt: '3D layered operation shells peeling +b, ×a, and square in reverse order.',
    body: ['3D layered operation shells peeling +b, ×a, and square in reverse order.'],
    cam: { target: [0, 0.15, 0], az: 2, el: 20, dist: 5.8 },
    lit: 'onion_core',
    parts: ['onion_core'],
    look: { xray: 0, section: 0 },
  },
  {
    tab: 'Inequality Flip',
    fig: 'Figure 5.3 · Why Multiplying by −1 Reverses < to > Across 0',
    title: 'Why Multiplying by −1 Reverses < to > Across 0',
    alt: 'Number-line interval reflected 180° across 0 so right-of becomes left-of.',
    body: ['Number-line interval reflected 180° across 0 so right-of becomes left-of.'],
    cam: { target: [0, 0.15, 0], az: -12, el: 20, dist: 5.8 },
    lit: 'ineq_ray',
    parts: ['ineq_ray'],
    look: { xray: 0, section: 0 },
  }
];

export const PLATES = {
  beam_arm: {
    title: 'Equilibrium Balance Beam',
    text: 'The beam stays horizontal only when the exact same operation is performed on both pans.',
    facts: s => [['x solution', `x = ${s.eq.x.toFixed(2)}`], ['Both pans', `${s.eq.sideVal.toFixed(1)}`]],
  },
  left_pan: {
    title: 'Left Pan (ax + b)',
    text: 'Holds a red unknown x-bars and b blue unit weights. Subtracting cx and b isolates (a − c)x.',
    facts: s => [['Left', `${s.eq.a}x + ${s.eq.b}`]],
  },
  right_pan: {
    title: 'Right Pan (cx + d)',
    text: 'Holds c red x-bars and d blue unit weights. After removing cx and b, net constant (d − b) remains.',
    facts: s => [['Right', `${s.eq.c}x + ${s.eq.d}`]],
  },
  onion_core: {
    title: 'Inverse-Operation Onion Peeler',
    text: 'To make x the subject of y = ax + b, undo the outermost operation (+b → −b) before the inner one (×a → ÷a): x = (y − b)/a.',
    facts: s => [['Subject x', `(y − ${s.eq.b}) / ${s.eq.a}`]],
  },
  ineq_ray: {
    title: 'Negative Reflection Mirror',
    text: 'Multiplying by −1 reflects the number line across 0: since +2 < +5, its mirror image −2 sits to the RIGHT of −5 (−2 > −5)!',
    facts: s => [['Positive', '2 < 5'], ['Reflected', '−2 > −5']],
  }
};

function buildWorld(rawE) {
  const E = { ...EKit, ...rawE };
  const { THREE, scene, asm } = E;
  const root = new THREE.Group();
  scene.add(root);
  EKit.studioGrid(root, { x0: -3, x1: 3 });
  const groups = {};
  for (const k of Object.keys(PLATES)) {
    const grp = asm ? asm(k, root, { title: PLATES[k].title, sub: '' }) : new THREE.Group();
    if (!asm) root.add(grp);
    groups[k] = grp;
  }
  const g = k => groups[k];
  const built = (function() {
    
    const pArm = g('beam_arm');
    pArm.add(E.vectorArrow({ from: [-1.7, 0, 0], to: [1.7, 0, 0], color: E.MATH_COL.axis, radius: 0.04 }));
    pArm.add(E.rightTrianglePlate({ a: 0.45, b: 0.45, thickness: 0.25, color: E.MATH_COL.warn }));

    const pLeft = g('left_pan');
    const lTray = E.algebraTile({ width: 1.25, height: 0.1, depth: 0.72, color: E.MATH_COL.inter });
    lTray.position.set(-1.12, 0.16, 0);
    pLeft.add(lTray);
    const leftXBlocks = [];
    for (let i = 0; i < 6; i++) {
      const bx = E.algebraTile({ width: 0.2, height: 0.34, depth: 0.22, color: E.MATH_COL.setA });
      bx.position.set(-1.5 + (i % 3) * 0.25, 0.38 + Math.floor(i / 3) * 0.36, -0.14);
      pLeft.add(bx);
      leftXBlocks.push(bx);
    }
    const leftUnits = [];
    for (let i = 0; i < 12; i++) {
      const coin = E.algebraTile({ width: 0.14, height: 0.11, depth: 0.14, color: E.MATH_COL.warn });
      coin.position.set(-0.76 - (i % 3) * 0.16, 0.27 + Math.floor(i / 3) * 0.13, 0.16);
      pLeft.add(coin);
      leftUnits.push(coin);
    }

    const pRight = g('right_pan');
    const rTray = E.algebraTile({ width: 1.25, height: 0.1, depth: 0.72, color: E.MATH_COL.inter });
    rTray.position.set(1.12, 0.16, 0);
    pRight.add(rTray);
    const rightXBlocks = [];
    for (let i = 0; i < 6; i++) {
      const bx = E.algebraTile({ width: 0.2, height: 0.34, depth: 0.22, color: E.MATH_COL.setA });
      bx.position.set(0.74 + (i % 3) * 0.25, 0.38 + Math.floor(i / 3) * 0.36, -0.14);
      pRight.add(bx);
      rightXBlocks.push(bx);
    }
    const rightUnits = [];
    for (let i = 0; i < 24; i++) {
      const coin = E.algebraTile({ width: 0.12, height: 0.09, depth: 0.12, color: E.MATH_COL.setB });
      coin.position.set(1.48 - (i % 4) * 0.14, 0.26 + Math.floor(i / 4) * 0.11, 0.16);
      pRight.add(coin);
      rightUnits.push(coin);
    }

    const pOnion = g('onion_core');
    pOnion.add(E.ringTorus({ radius: 0.85, tube: 0.04, color: E.MATH_COL.proof }));
    pOnion.add(E.ringTorus({ radius: 0.52, tube: 0.04, color: E.MATH_COL.warn }));

    const pIneq = g('ineq_ray');
    pIneq.add(E.numberLine3D({ min: -1.8, max: 1.8, step: 0.45, color: E.MATH_COL.inter }));
    pIneq.position.y = -0.85;

    return {
      at(s, p) {
        leftXBlocks.forEach((m, i) => { m.visible = i < Math.round(p.coefA); });
        leftUnits.forEach((m, i) => { m.visible = i < Math.round(p.constB); });
        rightXBlocks.forEach((m, i) => { m.visible = i < Math.round(p.coefC); });
        rightUnits.forEach((m, i) => { m.visible = i < Math.round(p.constD); });
      }
    };

  })();
  Object.entries(groups).forEach(([k, grp], gIdx) => {
    let mIdx = 0;
    grp.traverse(o => {
      if (o.isMesh && o.userData.part === undefined) {
        o.userData.part = PLATES[k]?.title || k;
        o.userData.home = o.position.clone();
        o.userData.ex = new THREE.Vector3((gIdx % 2 === 0 ? -0.28 : 0.28), 0.18 + mIdx * 0.08, 0.22);
        mIdx++;
      }
    });
  });
  return {
    labels: [
      { text: () => `${(CHAPTER.params || CHAPTER.defaultParams).coefA}x + ${(CHAPTER.params || CHAPTER.defaultParams).constB}`, cls: 'board', at: () => new THREE.Vector3(-1.12, 0.78, 0), leader: [-18, -22], on: () => (CHAPTER._pageIdx || 0) === 0 },
      { text: () => `${(CHAPTER.params || CHAPTER.defaultParams).coefC}x + ${(CHAPTER.params || CHAPTER.defaultParams).constD}`, cls: 'board', at: () => new THREE.Vector3(1.12, 0.78, 0), leader: [18, -22], on: () => (CHAPTER._pageIdx || 0) === 0 },
      { text: () => 'Undo +b then ÷a', cls: 'board', at: () => new THREE.Vector3(0, 0.9, 0), leader: [0, -24], on: () => (CHAPTER._pageIdx || 0) === 1 },
      { text: () => '×(−1) flips order', cls: 'board', at: () => new THREE.Vector3(0, -0.65, 0), leader: [24, -18], on: () => (CHAPTER._pageIdx || 0) === 2 },
    ],
    update(s, look) {
      const p = CHAPTER.params || CHAPTER.defaultParams;
      const pageIdx = CHAPTER._pageIdx || 0;
      const visibleSet = new Set(PAGES[pageIdx]?.parts || Object.keys(groups));
      for (const [k, grp] of Object.entries(groups)) {
        grp.visible = visibleSet.has(k);
      }
      if (built && built.at) built.at(s, p, pageIdx, look?.section ? 'cut' : look?.xray ? 'xray' : 'solid');
    },
  };
}

export const CHAPTER = {
  subject: SUBJECT,
  no: 5,
  title: 'Ch 5 · Twin-Pan Balance Equations & Inequality Mirror',
  theme: BYRNE_THEME,
  medium: 'pencil-wash',
  quirk: 'slightly-quirky',
  PAGES,
  pages: PAGES,
  PLATES,
  clock0: 0,
  cuts: true,
  defaultParams: {'coefA': 4, 'constB': 3, 'coefC': 1, 'constD': 15},
  controls: [
    { id: 'coefA', label: 'Left x-coefficient a', min: 2, max: 6, step: 1, value: 4, unit: 'x' },
    { id: 'constB', label: 'Left constant b', min: 1, max: 12, step: 1, value: 3, unit: '' },
    { id: 'coefC', label: 'Right x-coefficient c', min: 1, max: 3, step: 1, value: 1, unit: 'x' },
    { id: 'constD', label: 'Right constant d', min: 6, max: 24, step: 3, value: 15, unit: '' }
  ],
  lessons: {
    'atlas-ch05-1': { page: 0, params: {'coefA': 4, 'constB': 3, 'coefC': 1, 'constD': 15} },
    'atlas-ch05-2': { page: 1, params: {} },
    'atlas-ch05-3': { page: 2, params: {} },
    'w_balance_beam_equations': { page: 0, params: {} },
    'w_formula_subject_transposer': { page: 1, params: {} },
    'w_inequality_mirror_line': { page: 2, params: {} }
  },
  state(clock = 0, reduced = false) {
    const p = CHAPTER.params || CHAPTER.defaultParams;
    const t = typeof clock === 'number' ? (reduced ? 1.0 : clock) : 0;
    const eq = M.solveLinearBalance(p.coefA, p.constB, p.coefC, p.constD); return { t, eq };
  },
  readout(s, pageObj, pageIdx = 0) {
    CHAPTER._pageIdx = pageIdx;
    if (pageIdx === 0) return `<b>Twin-Pan Balance</b> · ${s.eq.a}x + ${s.eq.b} = ${s.eq.c}x + ${s.eq.d} ⇒ (${s.eq.a} − ${s.eq.c})x = ${s.eq.d} − ${s.eq.b} ⇒ ${s.eq.netA}x = ${s.eq.netD} ⇒ <b>x = ${s.eq.x.toFixed(2)}</b> (both pans = ${s.eq.sideVal.toFixed(1)}).`;
    if (pageIdx === 1) return `<b>Changing the Subject</b> · From y = ${s.eq.a}x + ${s.eq.b}: subtract ${s.eq.b}, then divide by ${s.eq.a} → <b>x = (y − ${s.eq.b}) / ${s.eq.a}</b>.`;
    return `<b>Inequality Sign Flip</b> · Multiplying 2 < 5 by −1 reflects both points across 0 → <b>−2 > −5</b> (mirror reflection reverses order!).`;
  },
  sonify(ctx, s, pageIdx = 0, p = CHAPTER.defaultParams) {
    if (!s?.eq) return;
    const lhs = s.eq.a * s.eq.x + s.eq.b;
    const rhs = s.eq.c * s.eq.x + s.eq.d;
    const balanced = Math.abs(lhs - rhs) < 1e-6;
    EKit.playInvariantSnap(ctx, { satisfied: balanced, strength: 1.1, gain: 0.035 });
  },
  buildWorld,
  build: buildWorld,
};

export const chapter = CHAPTER;
