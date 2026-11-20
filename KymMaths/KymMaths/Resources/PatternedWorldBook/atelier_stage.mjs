// Interactive Atelier SVG Stage & Oliver Byrne Reactive Prose Engine for KymMaths.
// Uses vendored @saxster/atlas 2D kits (draft_kit.js, iso_kit.js, prose.js, diegetic.js).
import {
  isoSvg,
  isoBox,
  isoCyl,
  isoCoinStack,
  isoPt,
  isoTextTransform,
} from './atlas/engine/iso_kit.js';
import {
  draftSvg,
  draftArrow,
  draftDimension,
  draftHatch,
  draftSupportTicks,
} from './atlas/engine/draft_kit.js';
import {
  byrne,
  term,
  val,
  scrub,
  aside,
  bindProse,
} from './atlas/engine/prose.js';
import {
  wireModeBar,
  ensureInkChromeDefs,
} from './atlas/engine/diegetic.js';

const SVG_W = 560;
const SVG_H = 290;

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const roundTo = (v, decimals = 2) => {
  const f = Math.pow(10, decimals);
  return Math.round(v * f) / f;
};
const fmtNum = v => {
  if (typeof v !== 'number' || !Number.isFinite(v)) return '—';
  const clean = Math.abs(v) < 1e-9 ? 0 : roundTo(v, 2);
  return String(clean).replace('-', '−');
};
const esc = s => String(s ?? '')
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;');

const gcd = (x, y) => {
  let a = Math.abs(Math.round(x));
  let b = Math.abs(Math.round(y));
  while (b !== 0) { const t = b; b = a % b; a = t; }
  return Math.max(1, a);
};
const comb = (n, k) => {
  if (k < 0 || k > n) return 0;
  let res = 1;
  for (let i = 1; i <= k; i++) res = (res * (n - i + 1)) / i;
  return Math.round(res);
};

export function paletteFor(isDark = false) {
  const shared = typeof window !== 'undefined' ? window.__kymPhetStage?.getThemeColors?.(isDark) : null;
  if (shared) {
    return {
      red: shared.red,
      redSoft: isDark ? 'rgba(229,97,79,0.20)' : 'rgba(195,54,43,0.16)',
      blue: shared.blue,
      blueSoft: isDark ? 'rgba(112,151,218,0.20)' : 'rgba(35,81,156,0.16)',
      amber: shared.amber,
      amberSoft: isDark ? 'rgba(240,188,69,0.24)' : 'rgba(226,164,28,0.22)',
      green: shared.green,
      greenSoft: isDark ? 'rgba(157,184,140,0.22)' : 'rgba(79,107,69,0.18)',
      ink: shared.ink,
      muted: shared.muted,
      card: shared.card,
      paper: shared.elevated,
      grid: isDark ? 'rgba(240,236,226,0.10)' : 'rgba(31,27,22,0.08)',
    };
  }
  return isDark
    ? {
        red: '#E5614F',
        redSoft: 'rgba(229,97,79,0.20)',
        blue: '#7097DA',
        blueSoft: 'rgba(112,151,218,0.20)',
        amber: '#F0BC45',
        amberSoft: 'rgba(240,188,69,0.24)',
        green: '#9DB88C',
        greenSoft: 'rgba(157,184,140,0.22)',
        ink: '#F0ECE2',
        muted: '#A8A49C',
        card: '#22262A',
        paper: '#181612',
        grid: 'rgba(240,236,226,0.10)',
      }
    : {
        red: '#C3362B',
        redSoft: 'rgba(195,54,43,0.16)',
        blue: '#23519C',
        blueSoft: 'rgba(35,81,156,0.16)',
        amber: '#E2A41C',
        amberSoft: 'rgba(226,164,28,0.22)',
        green: '#4F6B45',
        greenSoft: 'rgba(79,107,69,0.18)',
        ink: '#1F1B16',
        muted: '#6B665E',
        card: '#FFFDF7',
        paper: '#F1EADC',
        grid: 'rgba(31,27,22,0.08)',
      };
}

function themeStyleDefs(P, quirks = {}) {
  return `<style>
    svg {
      --ink: ${P.ink};
      --atlas-ink: ${P.ink};
      --muted: ${P.muted};
      --card: ${P.card};
      --accent: ${P.red};
      --accent-soft: ${P.redSoft};
      --accent-on: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif;
    }
    .at-label { font-size: 11.5px; font-weight: 700; stroke: none; }
    .at-mono { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 11px; font-weight: 600; stroke: none; }
    .at-note { font-size: 10.5px; font-weight: 500; stroke: none; fill: ${P.muted}; }
    [data-handle] { cursor: grab; }
    [data-handle]:active { cursor: grabbing; }
    .at-lit { filter: drop-shadow(0 0 4px ${P.amber}); }
    ${quirks.extraCss || ''}
  </style>`;
}

function keylineCircle(x, y, r, fill, stroke, strokeWidth = 2.2) {
  return `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(1)}" fill="${fill}" stroke="${stroke}" stroke-width="${strokeWidth}"/>`;
}

function handlePuck(id, x, y, fill, P, { label = '', dyLabel = -14, part = '' } = {}) {
  const partAttr = part ? ` data-part="${esc(part)}"` : '';
  const lbl = label
    ? `<text x="${x.toFixed(1)}" y="${(y + dyLabel).toFixed(1)}" text-anchor="middle" class="at-label" fill="${fill}">${esc(label)}</text>`
    : '';
  return `<g data-handle="${esc(id)}"${partAttr}>` +
    `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="18" fill="transparent" stroke="none"/>` +
    `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="8.5" fill="${fill}" stroke="${P.card}" stroke-width="2.2"/>` +
    `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="9.4" fill="none" stroke="${P.ink}" stroke-width="1"/>` +
    lbl +
    `</g>`;
}

export function evalCh00FromParams(params = {}) {
  const A = clamp(Math.round(Number(params.a ?? 18)), 8, 22);
  const B = clamp(Math.round(Number(params.b ?? 15)), 6, 20);
  const least = Math.max(0, A + B - 30);
  const most = Math.min(A, B);
  const rawC = Math.round(Number(params.c ?? 7));
  const inter = clamp(rawC, least, most);
  const onlyA = A - inter;
  const onlyB = B - inter;
  const union = onlyA + onlyB + inter;
  const outside = 30 - union;
  return { A, B, least, most, inter, onlyA, onlyB, union, outside };
}

function panExprLocal(xCoef, ones) {
  if (typeof window !== 'undefined' && typeof window.__kymPhetStage?.formatPanExpr === 'function') {
    return window.__kymPhetStage.formatPanExpr(xCoef, ones);
  }
  const parts = [];
  if (xCoef !== 0) {
    if (xCoef === 1) parts.push('x');
    else if (xCoef === -1) parts.push('−x');
    else parts.push(`${xCoef < 0 ? '−' : ''}${Math.abs(xCoef)}x`);
  }
  if (ones !== 0) {
    if (!parts.length) parts.push(fmtNum(ones));
    else parts.push(ones > 0 ? `+ ${ones}` : `− ${Math.abs(ones)}`);
  }
  return parts.length ? parts.join(' ') : '0';
}

function signedPolyLocal(lin, constTerm) {
  if (typeof window !== 'undefined' && typeof window.__kymPhetStage?.formatSignedPoly === 'function') {
    return window.__kymPhetStage.formatSignedPoly(lin, constTerm);
  }
  let out = 'x²';
  if (lin !== 0) {
    const absLin = Math.abs(lin);
    out += `${lin >= 0 ? ' + ' : ' − '}${absLin === 1 ? '' : fmtNum(absLin)}x`;
  }
  if (constTerm !== 0) {
    out += `${constTerm >= 0 ? ' + ' : ' − '}${fmtNum(Math.abs(constTerm))}`;
  }
  return out;
}

function calcPoint(kind, x) {
  if (typeof window !== 'undefined' && typeof window.__kymPhetStage?.evalCalcFunction === 'function') {
    return window.__kymPhetStage.evalCalcFunction(kind, x);
  }
  switch (kind) {
    case 'wave':
      return { f: Math.sin(x * 1.6), fp: 1.6 * Math.cos(x * 1.6), F: (1 - Math.cos(x * 1.6)) / 1.6, definedDeriv: true };
    case 'cusp': {
      const diff = x - 1.5;
      const at = Math.abs(diff) < 0.04;
      return {
        f: Math.abs(diff),
        fp: at ? NaN : (x < 1.5 ? -1 : 1),
        F: x < 1.5 ? 1.5 * x - 0.5 * x * x : 1.125 + 0.5 * diff * diff,
        definedDeriv: !at,
      };
    }
    case 'step': {
      const before = x < 1.5;
      const at = Math.abs(x - 1.5) < 0.05;
      return {
        f: before ? 0.6 : 2.0,
        fp: at ? NaN : 0,
        F: before ? 0.6 * x : 0.9 + 2.0 * (x - 1.5),
        definedDeriv: !at,
      };
    }
    default:
      return { f: 0.5 * x * x, fp: x, F: (x * x * x) / 6, definedDeriv: true };
  }
}

function safeDimension(opts) {
  const along = opts.axis === 'x' ? 0 : 1;
  const s = opts.witnesses?.[0]?.[along];
  const e = opts.witnesses?.[1]?.[along];
  if (!(typeof s === 'number' && typeof e === 'number' && e - s > 18)) return '';
  try {
    const d = draftDimension(opts);
    return `<g data-draft-role="dimension">` +
      `<path d="${d.witnessD}" stroke="currentColor"/>` +
      `<path d="${d.lineD}" stroke="currentColor"/>` +
      `<path d="${d.slashD}" stroke="currentColor"/>` +
      `<text x="${d.label.anchor[0].toFixed(1)}" y="${d.label.anchor[1].toFixed(1)}" text-anchor="middle" class="at-mono" data-draft-text="label">${esc(d.label.text)}</text>` +
      `</g>`;
  } catch {
    return '';
  }
}

// ---------- Chapter SVG Renderers ----------

function svgCh00(params, P) {
  const s = evalCh00FromParams(params);
  const cxBase = 280;
  const cy = 144;
  const r = 68;
  // Shrink center distance monotonically as intersection grows
  const ratio = s.most > 0 ? (s.inter - s.least) / Math.max(1, s.most - s.least || s.most) : 0;
  const sep = 122 - ratio * 72;
  const cxA = cxBase - sep * 0.5;
  const cxB = cxBase + sep * 0.5;

  const lensClip = `<clipPath id="ch0-lens-a"><circle cx="${cxA.toFixed(1)}" cy="${cy}" r="${r}"/></clipPath>`;
  const hatch = draftHatch({ region: { kind: 'rect', x: cxBase - r, y: cy - r, width: r * 2, height: r * 2 }, pattern: 'H1', pitch: 9 });

  const body = `
    <g data-part="univ">
      <rect x="26" y="18" width="508" height="254" rx="10" fill="${P.greenSoft}" stroke="${P.green}" stroke-width="2"/>
      <text x="42" y="38" class="at-label" fill="${P.green}">Class of 30 students · Outside both: ${s.outside}</text>
    </g>
    <g data-part="setA">
      <circle cx="${cxA.toFixed(1)}" cy="${cy}" r="${r}" fill="${P.redSoft}" stroke="${P.red}" stroke-width="2.4"/>
      <text x="${(cxA - 28).toFixed(1)}" y="${cy - r - 9}" text-anchor="middle" class="at-label" fill="${P.red}">A · Cricket (${s.A})</text>
      <text x="${(cxA - 34).toFixed(1)}" y="${cy + 4}" text-anchor="middle" class="at-mono" fill="${P.red}">only ${s.onlyA}</text>
    </g>
    <g data-part="setB">
      <circle cx="${cxB.toFixed(1)}" cy="${cy}" r="${r}" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="2.4"/>
      <text x="${(cxB + 28).toFixed(1)}" y="${cy - r - 9}" text-anchor="middle" class="at-label" fill="${P.blue}">B · Football (${s.B})</text>
      <text x="${(cxB + 34).toFixed(1)}" y="${cy + 4}" text-anchor="middle" class="at-mono" fill="${P.blue}">only ${s.onlyB}</text>
    </g>
    <g data-part="inter" clip-path="url(#ch0-lens-a)">
      <circle cx="${cxB.toFixed(1)}" cy="${cy}" r="${r}" fill="${P.amberSoft}" stroke="none"/>
      <path d="${hatch.d}" stroke="${P.amber}" stroke-width="1.3" opacity="0.55"/>
    </g>
    <g data-part="inter">
      <rect x="${(cxBase - 34).toFixed(1)}" y="${cy - 14}" width="68" height="24" rx="6" fill="${P.card}" stroke="${P.amber}" stroke-width="1.6"/>
      <text x="${cxBase}" y="${cy + 2}" text-anchor="middle" class="at-label" fill="${P.amber}">Both: ${s.inter}</text>
    </g>
    ${handlePuck('inter', cxB, cy + r + 8, P.amber, P, { label: `drag ↔ overlap (${s.least}..${s.most})`, dyLabel: 20, part: 'inter' })}
  `;

  return draftSvg({
    id: 'ch00-venn',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Inclusion–Exclusion Venn Diagram',
    desc: `Class of 30 with ${s.onlyA} only in A, ${s.inter} in both, ${s.onlyB} only in B, and ${s.outside} outside.`,
    mode: 'geometric-construction',
    defs: themeStyleDefs(P) + lensClip,
    body,
  });
}

function svgCh01(st, evalData, P) {
  const yLine = 154;
  const x0 = 48;
  const x1 = SVG_W - 48;
  const toX = v => x0 + ((v + 10) / 20) * (x1 - x0);
  const unit = st.context === 'temp' ? '°C' : (st.context === 'money' ? ' ₹' : '');

  const ticks = [];
  for (let t = -10; t <= 10; t += 2) {
    const tx = toX(t);
    const isZero = t === 0;
    ticks.push(
      `<line x1="${tx.toFixed(1)}" y1="${yLine - (isZero ? 11 : 5)}" x2="${tx.toFixed(1)}" y2="${yLine + (isZero ? 11 : 5)}" stroke="${isZero ? P.ink : P.muted}" stroke-width="${isZero ? 2.2 : 1}"/>` +
      `<text x="${tx.toFixed(1)}" y="${yLine + 24}" text-anchor="middle" class="at-mono" fill="${isZero ? P.ink : P.muted}">${fmtNum(t)}</text>`
    );
  }

  const ax = toX(st.a);
  const bx = toX(st.b);
  const distCol = st.mode === 'distance' ? P.amber : (evalData.directed >= 0 ? P.green : P.red);
  let arrowSvg = '';
  if (Math.abs(bx - ax) > 10) {
    const arr = draftArrow({ from: [ax, yLine - 34], to: [bx, yLine - 34] });
    arrowSvg = `<g data-part="span" stroke="${distCol}">` +
      `<path d="${arr.shaftD}" stroke="${distCol}" stroke-width="3.2" stroke-linecap="round"/>` +
      `<path d="${arr.headD}" stroke="${distCol}" stroke-width="2.4" fill="none" stroke-linejoin="round" stroke-linecap="round"/>` +
      `</g>`;
  }

  const spanDim = Math.abs(bx - ax) > 20
    ? safeDimension({
        axis: 'x',
        witnesses: [[Math.min(ax, bx), yLine - 10], [Math.max(ax, bx), yLine - 10]],
        position: yLine - 66,
        label: {
          text: st.mode === 'distance'
            ? `|B − A| = ${fmtNum(evalData.distance)}${unit}`
            : `B − A = ${evalData.directed > 0 ? '+' : ''}${fmtNum(evalData.directed)}${unit}`,
          anchor: [(ax + bx) / 2, yLine - 76],
        },
      })
    : `<text x="${ax.toFixed(1)}" y="${yLine - 46}" text-anchor="middle" class="at-label" fill="${distCol}">A = B (${fmtNum(st.a)}${unit})</text>`;

  const ctxTag = st.context === 'temp' ? 'Temperature (°C)' : (st.context === 'money' ? 'Net Worth (₹)' : 'Number Line (−10 to +10)');
  const body = `
    <text x="28" y="34" class="at-label" fill="${P.muted}">${esc(ctxTag)} · ${st.mode === 'distance' ? 'Distance |B − A|' : 'Directed Change B − A'}</text>
    <line x1="${x0}" y1="${yLine}" x2="${x1}" y2="${yLine}" stroke="${P.muted}" stroke-width="2"/>
    ${ticks.join('')}
    ${arrowSvg}
    ${spanDim}
    ${handlePuck('a', ax, yLine, P.blue, P, { label: `A = ${fmtNum(st.a)}`, dyLabel: -18, part: 'ptA' })}
    ${handlePuck('b', bx, yLine, P.red, P, { label: `B = ${fmtNum(st.b)}`, dyLabel: 48, part: 'ptB' })}
  `;

  return draftSvg({
    id: 'ch01-numline',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Number line directed change and distance',
    desc: `A at ${st.a}, B at ${st.b}, distance ${evalData.distance}.`,
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh01Classic(params, P) {
  const A = clamp(Math.round(Number(params.a ?? 24)), 6, 48);
  const B = clamp(Math.round(Number(params.b ?? 36)), 6, 60);
  const flips = clamp(Math.round(Number(params.c ?? 2)), 0, 2);
  const hcf = gcd(A, B);
  const lcm = (A * B) / hcf;
  const dir = flips % 2 === 0 ? 1 : -1;
  const cx = 280;
  const yLine = 84;
  const arr = draftArrow({ from: [cx, yLine], to: [cx + dir * 135, yLine] });
  const turnArcs = Array.from({ length: flips }, (_, f) => {
    const r = 34 + f * 16;
    return `<path d="M ${(cx - r).toFixed(1)},${yLine} A ${r},${r} 0 0 1 ${(cx + r).toFixed(1)},${yLine}" fill="none" stroke="${P.amber}" stroke-width="2" stroke-dasharray="4 3"/>`;
  }).join('');

  const body = `
    <text x="36" y="34" class="at-label" fill="${P.amber}">${flips} half-turn${flips === 1 ? '' : 's'}: facing ${dir > 0 ? 'forward (+)' : 'backward (−)'}</text>
    <line x1="48" y1="${yLine}" x2="512" y2="${yLine}" stroke="${P.muted}" stroke-width="1.8"/>
    <text x="${cx}" y="${yLine + 18}" text-anchor="middle" class="at-mono" fill="${P.ink}">0</text>
    ${turnArcs}
    <g data-part="span">
      <path d="${arr.shaftD}" stroke="${dir > 0 ? P.green : P.red}" stroke-width="3.2" stroke-linecap="round"/>
      <path d="${arr.headD}" stroke="${dir > 0 ? P.green : P.red}" stroke-width="2.4" fill="none"/>
    </g>
    <g data-part="ptA">
      <rect x="48" y="150" width="218" height="52" rx="8" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="2"/>
      <text x="157" y="180" text-anchor="middle" class="at-label" fill="${P.blue}">HCF(${A}, ${B}) = ${hcf}</text>
    </g>
    <g data-part="ptB">
      <rect x="294" y="150" width="218" height="52" rx="8" fill="${P.amberSoft}" stroke="${P.amber}" stroke-width="2"/>
      <text x="403" y="180" text-anchor="middle" class="at-label" fill="${P.amber}">LCM(${A}, ${B}) = ${lcm}</text>
    </g>
    <text x="280" y="236" text-anchor="middle" class="at-label" fill="${P.green}">HCF × LCM = ${hcf} × ${lcm} = ${hcf * lcm} = ${A} × ${B}</text>
  `;

  return draftSvg({
    id: 'ch01-classic',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Half-turns on the number line and HCF × LCM product',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh02(st, evalData, P) {
  const x0 = 56;
  const x1 = SVG_W - 44;
  const yTop = 104;
  const yBot = 192;
  const toX = s => x0 + (clamp(s, 0, 6) / 6) * (x1 - x0);
  const ux = toX(1);
  const px = toX(st.probeScale);

  const ticks = [];
  for (let s = 0; s <= 6; s += 1) {
    const tx = toX(s);
    const topV = roundTo((st.topUnit / Math.max(1, st.bottomUnit)) * s, 2);
    ticks.push(
      `<line x1="${tx.toFixed(1)}" y1="${yTop - 6}" x2="${tx.toFixed(1)}" y2="${yBot + 6}" stroke="${P.grid}" stroke-width="1"/>` +
      `<line x1="${tx.toFixed(1)}" y1="${yTop - 6}" x2="${tx.toFixed(1)}" y2="${yTop + 6}" stroke="${P.red}" stroke-width="1.6"/>` +
      `<text x="${tx.toFixed(1)}" y="${yTop - 14}" text-anchor="middle" class="at-mono" fill="${P.red}">${fmtNum(topV)}</text>` +
      `<line x1="${tx.toFixed(1)}" y1="${yBot - 6}" x2="${tx.toFixed(1)}" y2="${yBot + 6}" stroke="${P.blue}" stroke-width="1.6"/>` +
      `<text x="${tx.toFixed(1)}" y="${yBot + 22}" text-anchor="middle" class="at-mono" fill="${P.blue}">${s}</text>`
    );
  }
  const sup = draftSupportTicks({ from: [x0, yBot + 38], to: [x1, yBot + 38], extent: 6, pitch: 18, side: -1 });
  const unitDim = safeDimension({
    axis: 'x',
    witnesses: [[x0, yTop - 22], [ux, yTop - 22]],
    position: 52,
    label: { text: `1 unit = ${fmtNum(evalData.unitRatio)}`, anchor: [(x0 + ux) / 2, 42] },
  });

  const body = `
    <g data-part="unit">${unitDim}</g>
    <g data-part="topRail">
      <line x1="${x0}" y1="${yTop}" x2="${x1}" y2="${yTop}" stroke="${P.red}" stroke-width="3" stroke-linecap="round"/>
      <text x="16" y="${yTop + 4}" class="at-label" fill="${P.red}">Top</text>
    </g>
    <g data-part="botRail">
      <line x1="${x0}" y1="${yBot}" x2="${x1}" y2="${yBot}" stroke="${P.blue}" stroke-width="3" stroke-linecap="round"/>
      <text x="16" y="${yBot + 4}" class="at-label" fill="${P.blue}">Bot</text>
      <path d="${sup.d}" stroke="${P.muted}" stroke-width="0.9" opacity="0.45"/>
    </g>
    ${ticks.join('')}
    <g data-part="unit">
      <rect x="${(ux - 28).toFixed(1)}" y="${yTop + 12}" width="56" height="22" rx="5" fill="${P.greenSoft}" stroke="${P.green}" stroke-width="1.3"/>
      <text x="${ux.toFixed(1)}" y="${yTop + 27}" text-anchor="middle" class="at-mono" fill="${P.green}">${fmtNum(evalData.unitRatio)} / 1</text>
    </g>
    <g data-part="probe">
      <line x1="${px.toFixed(1)}" y1="${yTop}" x2="${px.toFixed(1)}" y2="${yBot}" stroke="${P.amber}" stroke-width="2.6" stroke-dasharray="4 3"/>
      <circle cx="${px.toFixed(1)}" cy="${yTop}" r="5.5" fill="${P.amber}" stroke="${P.ink}" stroke-width="1"/>
      <rect x="${(px - 44).toFixed(1)}" y="${yBot - 36}" width="88" height="22" rx="6" fill="${P.card}" stroke="${P.amber}" stroke-width="1.4"/>
      <text x="${px.toFixed(1)}" y="${yBot - 21}" text-anchor="middle" class="at-label" fill="${P.amber}">${fmtNum(evalData.topAtProbe)} : ${fmtNum(st.probeScale)}</text>
    </g>
    ${handlePuck('probe', px, yBot, P.amber, P, { label: 'slide scale', dyLabel: 44, part: 'probe' })}
  `;

  return draftSvg({
    id: 'ch02-doubleline',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Double number line proportionality rails',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh02Recurring(params, P) {
  const blk = clamp(Math.round(Number(params.a ?? 36)), 1, 99);
  const whole = clamp(Math.round(Number(params.b ?? 3)), 1, 8);
  const den = clamp(Math.round(Number(params.c ?? 4)), 2, 8);
  const g = gcd(blk, 99);
  const sNum = blk / g;
  const sDen = 99 / g;
  const bStr = String(blk).padStart(2, '0');
  const quotient = (whole * den) / 2;

  const body = `
    <g data-part="topRail">
      <rect x="44" y="34" width="472" height="40" rx="8" fill="${P.redSoft}" stroke="${P.red}" stroke-width="2"/>
      <text x="60" y="59" class="at-label" fill="${P.red}">100 × number = ${blk}.${bStr}${bStr}${bStr}…</text>
    </g>
    <g data-part="botRail">
      <rect x="128" y="88" width="388" height="40" rx="8" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="2"/>
      <text x="144" y="113" class="at-label" fill="${P.blue}">− 1 × number = 0.${bStr}${bStr}${bStr}…</text>
    </g>
    <g data-part="unit">
      <rect x="44" y="146" width="472" height="44" rx="8" fill="${P.greenSoft}" stroke="${P.green}" stroke-width="2"/>
      <text x="60" y="173" class="at-label" fill="${P.green}">99 × number = ${blk}  ⇒  0.${bStr}${bStr}… = ${blk}/99 = ${sNum}/${sDen}</text>
    </g>
    <g data-part="probe">
      <rect x="44" y="210" width="472" height="44" rx="8" fill="${P.amberSoft}" stroke="${P.amber}" stroke-width="1.8"/>
      <text x="60" y="237" class="at-label" fill="${P.amber}">Measure pieces: ${whole} ÷ 2/${den} = ${whole} × ${den}/2 = ${fmtNum(quotient)} pieces</text>
    </g>
  `;

  return draftSvg({
    id: 'ch02-recurring',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Recurring decimals via 100x − x and fraction division',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh03Compound(params, P) {
  const pA = clamp(Math.round(Number(params.a ?? 3)), 1, 8);
  const pB = clamp(Math.round(Number(params.b ?? 5)), 1, 10);
  const ratePct = clamp(Number(params.c ?? 8), 2, 18);
  const rate = ratePct / 100;
  const simp20 = 1000 * (1 + 20 * rate);
  const comp20 = 1000 * Math.pow(1 + rate, 20);
  const maxVal = Math.max(comp20, simp20, 2000);
  const ox = 56;
  const oy = 212;
  const gw = 268;
  const gh = 148;
  const toX = yr => ox + (yr / 20) * gw;
  const toY = v => oy - (v / maxVal) * gh;

  let simpD = '';
  let compD = '';
  for (let yr = 0; yr <= 20; yr += 1) {
    const sx = toX(yr);
    const sy = toY(1000 * (1 + yr * rate));
    const cy = toY(1000 * Math.pow(1 + rate, yr));
    simpD += `${yr === 0 ? 'M' : 'L'}${sx.toFixed(1)},${sy.toFixed(1)} `;
    compD += `${yr === 0 ? 'M' : 'L'}${sx.toFixed(1)},${cy.toFixed(1)} `;
  }

  const bars = [1, 2, 3, 4, 5].map((i, idx) => {
    const yr = i * 4;
    const bx = toX(yr) - 6;
    const cy = toY(1000 * Math.pow(1 + rate, yr));
    return `<rect x="${bx.toFixed(1)}" y="${cy.toFixed(1)}" width="12" height="${(oy - cy).toFixed(1)}" rx="2" fill="${P.redSoft}" stroke="${P.red}" stroke-width="1.2"/>`;
  }).join('');

  const body = `
    <g data-part="leftHand">
      <rect x="44" y="20" width="224" height="28" rx="6" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="1.4"/>
      <text x="56" y="38" class="at-label" fill="${P.blue}">Share ${pA} : ${pB} = ₹${pA * 40} : ₹${pB * 40}</text>
    </g>
    <g data-part="rightHand">
      <line x1="${ox}" y1="${oy}" x2="${ox + gw + 10}" y2="${oy}" stroke="${P.muted}" stroke-width="1.5"/>
      <line x1="${ox}" y1="54" x2="${ox}" y2="${oy}" stroke="${P.muted}" stroke-width="1.5"/>
      ${bars}
      <path d="${simpD}" stroke="${P.blue}" stroke-width="2.4" stroke-dasharray="5 4" fill="none"/>
      <path d="${compD}" stroke="${P.red}" stroke-width="2.8" fill="none"/>
      <circle cx="${toX(20)}" cy="${toY(simp20)}" r="4.5" fill="${P.blue}"/>
      <circle cx="${toX(20)}" cy="${toY(comp20)}" r="5" fill="${P.red}"/>
    </g>
    <g data-part="ratioLock" transform="translate(348, 66)">
      <rect x="0" y="0" width="188" height="148" rx="8" fill="${P.card}" stroke="${P.amber}" stroke-width="1.6"/>
      <text x="14" y="26" class="at-label" fill="${P.ink}">₹1,000 over 20 years</text>
      <text x="14" y="54" class="at-mono" fill="${P.red}">Compound (${ratePct}%): ₹${Math.round(comp20).toLocaleString('en-IN')}</text>
      <text x="14" y="78" class="at-mono" fill="${P.blue}">Simple (${ratePct}%):   ₹${Math.round(simp20).toLocaleString('en-IN')}</text>
      <text x="14" y="106" class="at-note">Gap = ₹${Math.round(comp20 - simp20).toLocaleString('en-IN')}</text>
      <text x="14" y="130" class="at-label" fill="${P.green}">+20% then −20% → 0.96×</text>
    </g>
  `;

  return draftSvg({
    id: 'ch03-compound',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Ratio sharing and simple vs compound interest growth',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh03(st, evalData, params, P, quirk) {
  if (st.mode === 'compound-growth') {
    return svgCh03Compound(params, P);
  }
  if (st.mode === 'compare-blind') {
    const tL = clamp(st.compareTargetLeft, 1, 9);
    const tR = clamp(st.compareTargetRight, 1, 9);
    const uL = clamp(st.compareUserLeft, 1, 9);
    const uR = clamp(st.compareUserRight, 1, 9);
    const pred = st.comparePrediction;
    const guessedRight = pred
      ? (pred === 'same') === Boolean(evalData.actualSame)
      : evalData.actualSame;
    const statusCol = st.compareRevealed
      ? (guessedRight ? P.green : P.red)
      : P.amber;
    const revealMsg = st.compareRevealed
      ? (pred
          ? (guessedRight
              ? `Correct! ${evalData.actualSame ? `Same ratio (${tL}:${tR} = ${uL}:${uR})` : `Different! +2/+2 changed ${tL}:${tR} to ${uL}:${uR}`}`
              : `Not quite — ${evalData.actualSame ? `Actually the same ratio (${tL}:${tR} = ${uL}:${uR})` : `Different! Adding +2 to both changes ${tL}:${tR}`}`)
          : (evalData.actualSame ? `Same ratio (${tL}:${tR} = ${uL}:${uR})` : `Different! +2/+2 changed the ratio`))
      : 'Ratio hidden · Predict Same or Different below';
    const dyn = `
      <text x="140" y="34" text-anchor="middle" class="at-label" fill="${P.ink}">Target Pair: ${tL} : ${tR}</text>
      <text x="420" y="34" text-anchor="middle" class="at-label" fill="${P.ink}">Test Pair: ${uL} : ${uR}</text>
      <g data-part="leftHand">
        ${isoCyl({ x: -16, y: 0, z: 0, r: 16, h: 12 + tL * 6, tone: 'accent', origin: [140, 200], scale: 1.5 })}
        ${isoCyl({ x: 18, y: 0, z: 0, r: 16, h: 12 + tR * 6, tone: 'cobalt', origin: [140, 200], scale: 1.5 })}
      </g>
      <g data-part="rightHand">
        ${isoCyl({ x: -16, y: 0, z: 0, r: 16, h: 12 + uL * 6, tone: 'accent', origin: [420, 200], scale: 1.5 })}
        ${isoCyl({ x: 18, y: 0, z: 0, r: 16, h: 12 + uR * 6, tone: 'cobalt', origin: [420, 200], scale: 1.5 })}
      </g>
      <rect x="65" y="238" width="430" height="32" rx="8" fill="${P.card}" stroke="${statusCol}" stroke-width="1.8"/>
      <text x="280" y="258" text-anchor="middle" class="at-label" fill="${statusCol}">${esc(revealMsg)}</text>
    `;
    return isoSvg({
      id: 'ch03-compare',
      vb: [0, 0, SVG_W, SVG_H],
      quirk,
      staticBody: isoBox({ x: -80, y: -32, z: -6, dx: 160, dy: 64, dz: 6, tone: 'stone', origin: [140, 206], scale: 1.25 }) +
        isoBox({ x: -80, y: -32, z: -6, dx: 160, dy: 64, dz: 6, tone: 'stone', origin: [420, 206], scale: 1.25 }),
      dynamicBody: themeStyleDefs(P) + dyn,
      label: 'Proportionality twin pair comparison',
    });
  }

  const maxV = 8;
  const xL = 166;
  const xR = 394;
  const baseY = 232;
  const hScale = 18;
  const hL = clamp(st.left, 0.5, maxV) * hScale;
  const hR = clamp(st.right, 0.5, maxV) * hScale;
  const bannerCol = evalData.inProportion ? P.green : P.red;
  const bannerTxt = evalData.inProportion
    ? `IN TUNE · ${fmtNum(st.left)}:${fmtNum(st.right)} = ${st.targetLeft}:${st.targetRight}`
    : `Target ${st.targetLeft}:${st.targetRight} · Current ${fmtNum(st.left)}:${fmtNum(st.right)}`;

  const ticksL = st.tickMode !== 'none'
    ? [1, 2, 3, 4, 5, 6, 7, 8].map(n => {
        const y = baseY - n * hScale;
        const lbl = st.tickMode === 'numbered'
          ? `<text x="${xL - 44}" y="${y + 4}" text-anchor="end" class="at-mono" fill="${P.muted}">${n}</text>`
          : '';
        return `<line x1="${xL - 38}" y1="${y}" x2="${xL - 28}" y2="${y}" stroke="${P.muted}" stroke-width="1.2"/>${lbl}`;
      }).join('')
    : '';
  const ticksR = st.tickMode !== 'none'
    ? [1, 2, 3, 4, 5, 6, 7, 8].map(n => {
        const y = baseY - n * hScale;
        const lbl = st.tickMode === 'numbered'
          ? `<text x="${xR + 44}" y="${y + 4}" text-anchor="start" class="at-mono" fill="${P.muted}">${n}</text>`
          : '';
        return `<line x1="${xR + 28}" y1="${y}" x2="${xR + 38}" y2="${y}" stroke="${P.muted}" stroke-width="1.2"/>${lbl}`;
      }).join('')
    : '';

  const bridgeY = (baseY - hL * 0.5 + (baseY - hR * 0.5)) * 0.5;
  const dyn = `
    <g data-part="ratioLock">
      <line x1="${xL + 26}" y1="${(baseY - hL).toFixed(1)}" x2="${xR - 26}" y2="${(baseY - hR).toFixed(1)}" stroke="${bannerCol}" stroke-width="${st.ratioLocked ? 3.2 : 2}" stroke-dasharray="${st.ratioLocked ? '' : '5 4'}"/>
      <rect x="120" y="14" width="320" height="28" rx="14" fill="${evalData.inProportion ? P.greenSoft : P.redSoft}" stroke="${bannerCol}" stroke-width="1.8"/>
      <text x="280" y="32" text-anchor="middle" class="at-label" fill="${bannerCol}">${esc(bannerTxt)}${st.ratioLocked ? ' · 🔒 Locked' : ''}</text>
      <circle cx="280" cy="${bridgeY.toFixed(1)}" r="16" fill="${P.card}" stroke="${bannerCol}" stroke-width="1.8"/>
      <text x="280" y="${(bridgeY + 4).toFixed(1)}" text-anchor="middle" class="at-mono" fill="${bannerCol}">${fmtNum(evalData.currentRatio)}</text>
    </g>
    ${ticksL}
    ${ticksR}
    <g data-part="leftHand">
      ${isoCyl({ x: 0, y: 0, z: 0, r: 22, h: Math.max(8, hL), tone: 'accent', origin: [xL, baseY], scale: 1 })}
    </g>
    <g data-part="rightHand">
      ${isoCyl({ x: 0, y: 0, z: 0, r: 22, h: Math.max(8, hR), tone: 'cobalt', origin: [xR, baseY], scale: 1 })}
    </g>
    <text x="${xL}" y="274" text-anchor="middle" class="at-label" fill="${P.red}">Left = ${fmtNum(st.left)}</text>
    <text x="${xR}" y="274" text-anchor="middle" class="at-label" fill="${P.blue}">Right = ${fmtNum(st.right)}</text>
    ${handlePuck('left', xL, baseY - hL - 12, P.red, P, { label: 'drag ↕', dyLabel: -12, part: 'leftHand' })}
    ${handlePuck('right', xR, baseY - hR - 12, P.blue, P, { label: 'drag ↕', dyLabel: -12, part: 'rightHand' })}
  `;

  return isoSvg({
    id: 'ch03-ratio-tuner',
    vb: [0, 0, SVG_W, SVG_H],
    quirk,
    staticBody: isoBox({ x: -34, y: -22, z: -6, dx: 68, dy: 44, dz: 6, tone: 'stone', origin: [xL, baseY], scale: 1 }) +
      isoBox({ x: -34, y: -22, z: -6, dx: 68, dy: 44, dz: 6, tone: 'stone', origin: [xR, baseY], scale: 1 }),
    dynamicBody: themeStyleDefs(P) + dyn,
    label: 'Isometric two-hand ratio vessels',
  });
}

function svgCh04(st, evalData, P) {
  const xVal = evalData.x;
  const pVal = st.mode === 'area-factor' ? Math.round(st.guessP) : evalData.p;
  const qVal = st.mode === 'area-factor' ? Math.round(st.guessQ) : evalData.q;
  const lin = pVal + qVal;
  const constTerm = pVal * qVal;

  const isScale = st.mode === 'area-scale';
  const unit = 16;
  const wX = isScale ? clamp(xVal * unit, 58, 108) : 96;
  const wP = isScale ? clamp(Math.abs(pVal) * unit, 36, 62) : 60;
  const hQ = isScale ? clamp(Math.abs(qVal) * unit, 32, 62) : 56;
  const ox = 68;
  const oy = 68;

  const hatchTop = pVal < 0 ? draftHatch({ region: { kind: 'rect', x: ox + wX, y: oy, width: wP, height: wX }, pattern: 'H1', pitch: 8 }).d : '';
  const hatchBot = qVal < 0 ? draftHatch({ region: { kind: 'rect', x: ox, y: oy + wX, width: wX, height: hQ }, pattern: 'H2', pitch: 8 }).d : '';
  const hatchCor = constTerm < 0 ? draftHatch({ region: { kind: 'rect', x: ox + wX, y: oy + wX, width: wP, height: hQ }, pattern: 'H1', pitch: 8 }).d : '';

  const signStr = n => `${n >= 0 ? '+' : '−'}${Math.abs(n)}`;
  const dimTopX = safeDimension({
    axis: 'x',
    witnesses: [[ox, oy], [ox + wX, oy]],
    position: oy - 18,
    label: { text: isScale ? `x = ${xVal}` : 'x', anchor: [ox + wX / 2, oy - 26] },
  });
  const dimTopP = safeDimension({
    axis: 'x',
    witnesses: [[ox + wX, oy], [ox + wX + wP, oy]],
    position: oy - 18,
    label: { text: signStr(pVal), anchor: [ox + wX + wP / 2, oy - 26] },
  });
  const dimLeftX = safeDimension({
    axis: 'y',
    witnesses: [[ox, oy], [ox, oy + wX]],
    position: ox - 18,
    label: { text: isScale ? `${xVal}` : 'x', anchor: [ox - 32, oy + wX / 2 + 4] },
  });
  const dimLeftQ = safeDimension({
    axis: 'y',
    witnesses: [[ox, oy + wX], [ox, oy + wX + hQ]],
    position: ox - 18,
    label: { text: signStr(qVal), anchor: [ox - 32, oy + wX + hQ / 2 + 4] },
  });

  const summaryX = Math.max(276, ox + wX + wP + 46);
  const pz = evalData.puzzle;
  const linCol = lin === 0 ? P.green : P.blue;
  const banner = st.mode === 'area-factor'
    ? (evalData.factorSolved
        ? `SOLVED · (x ${signStr(pVal)})(x ${signStr(qVal)})`
        : `Target: ${pz.label}`)
    : `(x ${signStr(pVal)})(x ${signStr(qVal)})`;

  const body = `
    ${dimTopX}${dimTopP}${dimLeftX}${dimLeftQ}
    <g data-part="tileX2">
      <rect x="${ox}" y="${oy}" width="${wX}" height="${wX}" fill="${P.redSoft}" stroke="${P.red}" stroke-width="2.2"/>
      <text x="${ox + wX / 2}" y="${oy + wX / 2 + 4}" text-anchor="middle" class="at-label" fill="${P.red}">${isScale ? `x² = ${xVal * xVal}` : 'x²'}</text>
    </g>
    <g data-part="tileLin">
      <rect x="${ox + wX}" y="${oy}" width="${wP}" height="${wX}" fill="${pVal >= 0 ? P.blueSoft : P.redSoft}" stroke="${pVal >= 0 ? P.blue : P.red}" stroke-width="2" ${pVal < 0 ? 'stroke-dasharray="4 3"' : ''}/>
      ${hatchTop ? `<path d="${hatchTop}" stroke="${P.red}" stroke-width="1.1" opacity="0.45"/>` : ''}
      <text x="${ox + wX + wP / 2}" y="${oy + wX / 2 + 4}" text-anchor="middle" class="at-label" fill="${pVal >= 0 ? P.blue : P.red}">${fmtNum(pVal)}x</text>
      <rect x="${ox}" y="${oy + wX}" width="${wX}" height="${hQ}" fill="${qVal >= 0 ? P.blueSoft : P.redSoft}" stroke="${qVal >= 0 ? P.blue : P.red}" stroke-width="2" ${qVal < 0 ? 'stroke-dasharray="4 3"' : ''}/>
      ${hatchBot ? `<path d="${hatchBot}" stroke="${P.red}" stroke-width="1.1" opacity="0.45"/>` : ''}
      <text x="${ox + wX / 2}" y="${oy + wX + hQ / 2 + 4}" text-anchor="middle" class="at-label" fill="${qVal >= 0 ? P.blue : P.red}">${fmtNum(qVal)}x</text>
    </g>
    <g data-part="tileConst">
      <rect x="${ox + wX}" y="${oy + wX}" width="${wP}" height="${hQ}" fill="${constTerm >= 0 ? P.amberSoft : P.redSoft}" stroke="${constTerm >= 0 ? P.amber : P.red}" stroke-width="2"/>
      ${hatchCor ? `<path d="${hatchCor}" stroke="${P.red}" stroke-width="1.1" opacity="0.45"/>` : ''}
      <text x="${ox + wX + wP / 2}" y="${oy + wX + hQ / 2 + 4}" text-anchor="middle" class="at-label" fill="${constTerm >= 0 ? P.amber : P.red}">${fmtNum(constTerm)}</text>
    </g>
    ${st.mode !== 'area-factor' ? handlePuck('area-corner', ox + wX + wP, oy + wX + hQ, P.ink, P, { label: 'drag ↔↕', dyLabel: 22, part: 'tileConst' }) : ''}
    <g transform="translate(${summaryX}, 64)">
      <rect x="0" y="0" width="${Math.max(185, SVG_W - summaryX - 18)}" height="164" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.2" opacity="0.96"/>
      <text x="14" y="24" class="at-label" fill="${evalData.factorSolved ? P.green : P.ink}">${esc(banner)}</text>
      <text x="14" y="54" class="at-mono" fill="${P.red}">Square:   x² ${isScale ? `= ${xVal * xVal}` : ''}</text>
      <text x="14" y="78" class="at-mono" fill="${linCol}">Middle:   ${fmtNum(pVal)}x + ${fmtNum(qVal)}x = ${fmtNum(lin)}x</text>
      <text x="14" y="102" class="at-mono" fill="${P.amber}">Corner:   (${fmtNum(pVal)})(${fmtNum(qVal)}) = ${fmtNum(constTerm)}</text>
      <line x1="14" y1="118" x2="${Math.max(168, SVG_W - summaryX - 32)}" y2="118" stroke="${P.muted}" stroke-width="1"/>
      <text x="14" y="140" class="at-label" fill="${P.ink}">Sum: ${signedPolyLocal(lin, constTerm)}</text>
    </g>
  `;

  return draftSvg({
    id: 'ch04-area',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Quadratic area-array multiplication model',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function panBlockGroup(xCoef, ones, origin, P, sideTag) {
  const out = [];
  const absX = clamp(Math.abs(Math.round(xCoef)), 0, 5);
  const absOnes = clamp(Math.abs(Math.round(ones)), 0, 12);

  for (let i = 0; i < absX; i++) {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const px = -26 + col * 14;
    const py = -12 + row * 12;
    if (xCoef > 0) {
      out.push(isoBox({ x: px, y: py, z: 3, dx: 11, dy: 10, dz: 14, tone: 'accent', origin, scale: 1 }));
    } else {
      const [sx, sy] = isoPt(px + 5, py + 5, 10, origin, 1);
      out.push(`<rect x="${(sx - 6).toFixed(1)}" y="${(sy - 7).toFixed(1)}" width="12" height="14" rx="2" fill="${P.redSoft}" stroke="${P.red}" stroke-width="1.4" stroke-dasharray="3 2"/>`);
      out.push(`<text x="${sx.toFixed(1)}" y="${(sy + 3).toFixed(1)}" text-anchor="middle" class="at-mono" fill="${P.red}">−x</text>`);
    }
  }
  const coinStacks = Math.ceil(absOnes / 4);
  for (let sIdx = 0; sIdx < coinStacks; sIdx++) {
    const cnt = Math.min(4, absOnes - sIdx * 4);
    const cx = 12 + (sIdx % 2) * 14;
    const cy = -8 + Math.floor(sIdx / 2) * 14;
    if (ones > 0) {
      out.push(isoCoinStack({ x: cx, y: cy, z: 3, count: cnt, r: 5.8, discH: 2.4, gap: 0.2, tone: 'gold', origin, scale: 1 }));
    } else {
      out.push(isoCoinStack({ x: cx, y: cy, z: 3, count: cnt, r: 5.8, discH: 2.4, gap: 0.2, tone: 'cobalt', origin, scale: 1 }));
    }
  }
  return `<g data-part="${sideTag}">` +
    isoBox({ x: -34, y: -20, z: 0, dx: 74, dy: 42, dz: 3, tone: 'wood', origin, scale: 1 }) +
    out.join('') +
    `</g>`;
}

function svgCh05(st, evalData, P, quirk) {
  const pivX = 280;
  const pivY = 128;
  const tiltDeg = (evalData.tiltRad || 0) * (180 / Math.PI);
  const beamHalf = 132;
  const sinT = Math.sin(evalData.tiltRad || 0);
  const cosT = Math.cos(evalData.tiltRad || 0);
  const leftPanOrigin = [pivX - beamHalf * cosT, pivY + 28 - beamHalf * sinT];
  const rightPanOrigin = [pivX + beamHalf * cosT, pivY + 28 + beamHalf * sinT];
  const leftStr = panExprLocal(st.leftX, st.leftOnes);
  const rightStr = panExprLocal(st.rightX, st.rightOnes);
  const badgeCol = evalData.isolated ? P.green : (evalData.balanced ? P.blue : P.red);
  const badgeText = evalData.isolated
    ? `SOLVED! x = ${fmtNum(evalData.solvedValue)}`
    : (evalData.balanced ? `${leftStr} = ${rightStr}` : `TILTS (${leftStr} ≠ ${rightStr})`);

  const stat = `
    <g data-part="fulcrum">
      ${isoBox({ x: -24, y: -16, z: 0, dx: 48, dy: 32, dz: 8, tone: 'stone', origin: [pivX, 244], scale: 1 })}
      <polygon points="${pivX - 18},236 ${pivX + 18},236 ${pivX},${pivY + 6}" fill="${P.card}" stroke="${P.ink}" stroke-width="2" stroke-linejoin="round"/>
      <circle cx="${pivX}" cy="${pivY}" r="5.5" fill="${P.amber}" stroke="${P.ink}" stroke-width="1.6"/>
    </g>
  `;
  const dyn = `
    <g transform="rotate(${tiltDeg.toFixed(2)} ${pivX} ${pivY})">
      <line x1="${pivX - beamHalf}" y1="${pivY}" x2="${pivX + beamHalf}" y2="${pivY}" stroke="${P.ink}" stroke-width="5.5" stroke-linecap="round"/>
      <line x1="${pivX - beamHalf}" y1="${pivY}" x2="${pivX + beamHalf}" y2="${pivY}" stroke="${badgeCol}" stroke-width="2.2" stroke-linecap="round"/>
      <circle cx="${pivX - beamHalf}" cy="${pivY}" r="3.5" fill="${P.amber}" stroke="${P.ink}" stroke-width="1"/>
      <circle cx="${pivX + beamHalf}" cy="${pivY}" r="3.5" fill="${P.amber}" stroke="${P.ink}" stroke-width="1"/>
    </g>
    <line x1="${leftPanOrigin[0].toFixed(1)}" y1="${(leftPanOrigin[1] - 28).toFixed(1)}" x2="${leftPanOrigin[0].toFixed(1)}" y2="${leftPanOrigin[1].toFixed(1)}" stroke="${P.muted}" stroke-width="1.5"/>
    <line x1="${rightPanOrigin[0].toFixed(1)}" y1="${(rightPanOrigin[1] - 28).toFixed(1)}" x2="${rightPanOrigin[0].toFixed(1)}" y2="${rightPanOrigin[1].toFixed(1)}" stroke="${P.muted}" stroke-width="1.5"/>
    ${panBlockGroup(st.leftX, st.leftOnes, leftPanOrigin, P, 'leftPan')}
    ${panBlockGroup(st.rightX, st.rightOnes, rightPanOrigin, P, 'rightPan')}
    <text x="${leftPanOrigin[0].toFixed(1)}" y="${(leftPanOrigin[1] + 54).toFixed(1)}" text-anchor="middle" class="at-label" fill="${P.ink}">${esc(leftStr)}</text>
    <text x="${rightPanOrigin[0].toFixed(1)}" y="${(rightPanOrigin[1] + 54).toFixed(1)}" text-anchor="middle" class="at-label" fill="${P.ink}">${esc(rightStr)}</text>
    <rect x="132" y="14" width="296" height="28" rx="14" fill="${evalData.isolated ? P.greenSoft : (evalData.balanced ? P.blueSoft : P.redSoft)}" stroke="${badgeCol}" stroke-width="1.8"/>
    <text x="280" y="32" text-anchor="middle" class="at-label" fill="${badgeCol}">${esc(badgeText)}</text>
    ${st.zeroPairsCleared > 0 ? `<text x="280" y="276" text-anchor="middle" class="at-note">Zero-pairs cancelled: ${st.zeroPairsCleared} · Lock: ${st.symLock ? 'ON' : 'OFF'}</text>` : `<text x="280" y="276" text-anchor="middle" class="at-note">Red blocks = +x · Gold stacks = +1 coins · Lock: ${st.symLock ? 'ON' : 'OFF'}</text>`}
  `;

  return isoSvg({
    id: 'ch05-balance',
    vb: [0, 0, SVG_W, SVG_H],
    quirk,
    staticBody: stat,
    dynamicBody: themeStyleDefs(P) + dyn,
    label: 'Isometric twin-pan balance equation solver',
  });
}

function svgCh07(st, evalData, P, quirk) {
  if (st.mode === 'function-machine') {
    const reveal = !st.mysteryMode || st.mysteryRevealed;
    const opMap = { add2: '+ 2', sub3: '− 3', mul2: '× 2', mul3: '× 3', div2: '÷ 2' };
    const shownOp1 = st.mysteryMode && st.mysteryRevealed && Array.isArray(st.mysterySecret) ? st.mysterySecret[0] : st.op1;
    const shownOp2 = st.mysteryMode && st.mysteryRevealed && Array.isArray(st.mysterySecret) ? st.mysterySecret[1] : st.op2;
    const lbl1 = reveal ? (opMap[shownOp1] || shownOp1) : '?';
    const lbl2 = reveal ? (opMap[shownOp2] || shownOp2) : '?';
    const arr1 = draftArrow({ from: [122, 134], to: [176, 134] });
    const arr2 = draftArrow({ from: [258, 134], to: [302, 134] });
    const arr3 = draftArrow({ from: [384, 134], to: [438, 134] });
    const dyn = `
      <text x="280" y="32" text-anchor="middle" class="at-label" fill="${P.ink}">${st.mysteryMode && !st.mysteryRevealed ? 'Mystery Machine · Test different inputs!' : `Two-Step Rule: ${lbl1}  then  ${lbl2}`}</text>
      ${isoBox({ x: -24, y: -16, z: 0, dx: 48, dy: 32, dz: 18, tone: 'cobalt', origin: [88, 152], scale: 1 })}
      <text transform="${isoTextTransform('flatTop', 0, 0, 22, { origin: [88, 152], scale: 1 })}" text-anchor="middle" class="at-mono" fill="${P.ink}">${fmtNum(st.testInput)}</text>
      <text x="88" y="196" text-anchor="middle" class="at-label" fill="${P.blue}">Input x</text>
      <path d="${arr1.shaftD}" stroke="${P.muted}" stroke-width="2"/><path d="${arr1.headD}" stroke="${P.muted}" stroke-width="2" fill="none"/>
      <g data-part="step1">
        ${isoBox({ x: -26, y: -18, z: 0, dx: 52, dy: 36, dz: 24, tone: reveal ? 'gold' : 'stone', origin: [216, 154], scale: 1 })}
        <text transform="${isoTextTransform('flatTop', 0, 0, 27, { origin: [216, 154], scale: 1 })}" text-anchor="middle" class="at-label" fill="${P.ink}">${esc(lbl1)}</text>
        <text x="216" y="196" text-anchor="middle" class="at-mono" fill="${P.muted}">mid = ${reveal ? fmtNum(evalData.midVal) : '?'}</text>
      </g>
      <path d="${arr2.shaftD}" stroke="${P.muted}" stroke-width="2"/><path d="${arr2.headD}" stroke="${P.muted}" stroke-width="2" fill="none"/>
      <g data-part="step2">
        ${isoBox({ x: -26, y: -18, z: 0, dx: 52, dy: 36, dz: 24, tone: reveal ? 'accent' : 'stone', origin: [342, 154], scale: 1 })}
        <text transform="${isoTextTransform('flatTop', 0, 0, 27, { origin: [342, 154], scale: 1 })}" text-anchor="middle" class="at-label" fill="${P.ink}">${esc(lbl2)}</text>
      </g>
      <path d="${arr3.shaftD}" stroke="${P.muted}" stroke-width="2"/><path d="${arr3.headD}" stroke="${P.muted}" stroke-width="2" fill="none"/>
      <g data-part="output">
        ${isoBox({ x: -24, y: -16, z: 0, dx: 48, dy: 32, dz: 18, tone: 'emerald', origin: [472, 152], scale: 1 })}
        <text transform="${isoTextTransform('flatTop', 0, 0, 22, { origin: [472, 152], scale: 1 })}" text-anchor="middle" class="at-mono" fill="${P.ink}">${fmtNum(evalData.outVal)}</text>
        <text x="472" y="196" text-anchor="middle" class="at-label" fill="${P.green}">Output y</text>
      </g>
      ${handlePuck('inputVal', 88, 222, P.blue, P, { label: 'drag ↔ test input', dyLabel: 22, part: 'step1' })}
    `;
    return isoSvg({
      id: 'ch07-machine',
      vb: [0, 0, SVG_W, SVG_H],
      quirk,
      staticBody: '',
      dynamicBody: themeStyleDefs(P) + dyn,
      label: 'Two-step function machine in 2.5D',
    });
  }

  const ox = 250;
  const oy = 165;
  const sc = 26;
  const toX = x => ox + x * sc;
  const toY = y => oy - y * sc;

  const gridLines = [];
  for (let g = -6; g <= 7; g++) {
    const gx = toX(g);
    if (gx >= 52 && gx <= SVG_W - 28) {
      gridLines.push(`<line x1="${gx}" y1="22" x2="${gx}" y2="${SVG_H - 20}" stroke="${g === 0 ? P.muted : P.grid}" stroke-width="${g === 0 ? 1.8 : 1}"/>`);
    }
  }
  for (let g = -4; g <= 5; g++) {
    const gy = toY(g);
    if (gy >= 22 && gy <= SVG_H - 20) {
      gridLines.push(`<line x1="52" y1="${gy}" x2="${SVG_W - 28}" y2="${gy}" stroke="${g === 0 ? P.muted : P.grid}" stroke-width="${g === 0 ? 1.8 : 1}"/>`);
    }
  }

  let ghostLine = '';
  if (st.ghost) {
    const xL = -6, xR = 7;
    const gCol = evalData.isPerpGhost ? P.green : P.amber;
    ghostLine = `<g data-part="ghost">` +
      `<line x1="${toX(xL)}" y1="${toY(st.ghost.m * xL + st.ghost.c)}" x2="${toX(xR)}" y2="${toY(st.ghost.m * xR + st.ghost.c)}" stroke="${gCol}" stroke-width="2.2" stroke-dasharray="6 4"/>` +
      `</g>`;
  }

  let lineSvg = '';
  if (evalData.vertical) {
    const vx = toX(st.p1.x);
    lineSvg = `<line x1="${vx}" y1="24" x2="${vx}" y2="${SVG_H - 22}" stroke="${P.blue}" stroke-width="2.8"/>`;
  } else {
    const xL = -6, xR = 7;
    lineSvg = `<line x1="${toX(xL)}" y1="${toY(evalData.m * xL + evalData.c)}" x2="${toX(xR)}" y2="${toY(evalData.m * xR + evalData.c)}" stroke="${P.blue}" stroke-width="2.8"/>`;
  }

  const p1x = toX(st.p1.x), p1y = toY(st.p1.y);
  const p2x = toX(st.p2.x), p2y = toY(st.p2.y);
  const slopeTri = Math.abs(p2x - p1x) > 4 && Math.abs(p2y - p1y) > 4
    ? `<g data-part="slopeTri">` +
      `<line x1="${p1x}" y1="${p1y}" x2="${p2x}" y2="${p1y}" stroke="${P.amber}" stroke-width="2" stroke-dasharray="4 3"/>` +
      `<line x1="${p2x}" y1="${p1y}" x2="${p2x}" y2="${p2y}" stroke="${P.red}" stroke-width="2" stroke-dasharray="4 3"/>` +
      `</g>`
    : '';

  const badgeTxt = evalData.vertical
    ? `x = ${fmtNum(st.p1.x)}`
    : `y = ${fmtNum(evalData.m)}x + ${fmtNum(evalData.c)}`;

  const body = `
    ${gridLines.join('')}
    ${ghostLine}
    ${slopeTri}
    <g data-part="line">${lineSvg}</g>
    <rect x="18" y="14" width="166" height="26" rx="6" fill="${P.card}" stroke="${P.blue}" stroke-width="1.4"/>
    <text x="28" y="31" class="at-label" fill="${P.blue}">${esc(badgeTxt)}</text>
    ${handlePuck('p1', p1x, p1y, P.blue, P, { label: `(${fmtNum(st.p1.x)},${fmtNum(st.p1.y)})`, dyLabel: 20, part: 'line' })}
    ${handlePuck('p2', p2x, p2y, P.blue, P, { label: `(${fmtNum(st.p2.x)},${fmtNum(st.p2.y)})`, dyLabel: -14, part: 'line' })}
    ${st.probeActive ? handlePuck('probe', toX(st.probe.x), toY(st.probe.y), evalData.probeOnLine ? P.green : P.amber, P, { label: evalData.probeOnLine ? 'On line!' : 'Probe', dyLabel: -14, part: 'probe' }) : ''}
  `;

  return draftSvg({
    id: 'ch07-graph',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Linear graph with slope triangle and point probe',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh13ErrorBar(params, P) {
  const sigma = clamp(Number(params.a ?? 12), 4, 30);
  const n = clamp(Math.round(Number(params.b ?? 16)), 4, 64);
  const engineHits = clamp(Math.round(Number(params.c ?? 1)), 0, 5);
  const se = sigma / Math.sqrt(n);
  const cx = 175;
  const baseY = 218;
  const scX = 16;
  let curveD = '';
  for (let x = -126; x <= 126; x += 3) {
    const z = x / Math.max(4, se * scX);
    const y = baseY - 135 * Math.exp(-0.5 * z * z);
    curveD += `${x === -126 ? 'M' : 'L'}${(cx + x).toFixed(1)},${y.toFixed(1)} `;
  }
  const sePx = Math.min(110, se * scX);
  const body = `
    <g data-part="pop">
      <line x1="38" y1="${baseY}" x2="312" y2="${baseY}" stroke="${P.muted}" stroke-width="1.5"/>
      <path d="${curveD}" stroke="${P.red}" stroke-width="2.6" fill="${P.redSoft}"/>
      <text x="${cx}" y="38" text-anchor="middle" class="at-label" fill="${P.blue}">Population σ = ${fmtNum(sigma)} · Sample n = ${n}</text>
      <text x="${cx}" y="${baseY + 22}" text-anchor="middle" class="at-mono" fill="${P.red}">±SE = ±${fmtNum(se)}</text>
      <line x1="${(cx - sePx).toFixed(1)}" y1="${baseY - 40}" x2="${(cx + sePx).toFixed(1)}" y2="${baseY - 40}" stroke="${P.amber}" stroke-width="3"/>
    </g>
    <g data-part="samples" transform="translate(342, 46)">
      <rect x="0" y="0" width="194" height="176" rx="8" fill="${P.card}" stroke="${P.blue}" stroke-width="1.6"/>
      <rect x="28" y="42" width="138" height="22" rx="4" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="1.6"/>
      <rect x="82" y="14" width="30" height="84" rx="4" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="1.6"/>
      <text x="97" y="124" text-anchor="middle" class="at-label" fill="${P.amber}">Wald survivorship view</text>
      <text x="97" y="144" text-anchor="middle" class="at-note">Visible engine hits: ${engineHits}</text>
      <text x="97" y="162" text-anchor="middle" class="at-note">Missing planes took hits here</text>
    </g>
  `;
  return draftSvg({
    id: 'ch13-errorbar',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Standard error bell curve and survivorship bias view',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh13(st, evalData, params, P) {
  if (st.mode !== 'live-sampler') {
    return svgCh13ErrorBar(params, P);
  }
  const x0 = 46;
  const x1 = SVG_W - 46;
  const toX = v => x0 + ((v - 10) / 80) * (x1 - x0);
  const gauss = (v, sd) => Math.exp(-0.5 * Math.pow((v - 50) / Math.max(1, sd), 2));

  let popD = '';
  let samD = '';
  for (let v = 12; v <= 88; v += 1.5) {
    const px = toX(v);
    const py = 114 - gauss(v, st.popSigma) * 74;
    popD += `${v === 12 ? 'M' : 'L'}${px.toFixed(1)},${py.toFixed(1)} `;
    const sy = 242 - gauss(v, evalData.theoreticalSE) * 76;
    samD += `${v === 12 ? 'M' : 'L'}${px.toFixed(1)},${sy.toFixed(1)} `;
  }

  const bins = {};
  const dots = st.samples.map(m => {
    const q = Math.round(m / 1.6) * 1.6;
    bins[q] = (bins[q] || 0) + 1;
    const cx = toX(clamp(m, 14, 86));
    const cy = 242 - bins[q] * 9;
    return keylineCircle(cx, Math.max(146, cy), 4.2, P.red, P.card, 1);
  }).join('');

  const seLeft = toX(50 - evalData.theoreticalSE);
  const seRight = toX(50 + evalData.theoreticalSE);
  const seDim = safeDimension({
    axis: 'x',
    witnesses: [[seLeft, 242], [seRight, 242]],
    position: 266,
    label: { text: `±SE = σ/√${st.sampleN} = ${fmtNum(evalData.theoreticalSE)}`, anchor: [(seLeft + seRight) / 2, 280] },
  });

  const body = `
    <g data-part="pop">
      <line x1="${x0}" y1="114" x2="${x1}" y2="114" stroke="${P.muted}" stroke-width="1.4"/>
      <path d="${popD}" stroke="${P.blue}" stroke-width="2.4" fill="none"/>
      <text x="48" y="34" class="at-label" fill="${P.blue}">Population (μ = 50, σ = ${st.popSigma})</text>
      ${handlePuck('popSigma', toX(50 + st.popSigma), 88, P.blue, P, { label: `σ=${st.popSigma}`, dyLabel: -12, part: 'pop' })}
    </g>
    <g data-part="samples">
      <line x1="${x0}" y1="242" x2="${x1}" y2="242" stroke="${P.muted}" stroke-width="1.4"/>
      <path d="${samD}" stroke="${P.amber}" stroke-width="1.8" stroke-dasharray="4 3" fill="none"/>
      <line x1="${toX(50)}" y1="24" x2="${toX(50)}" y2="250" stroke="${P.green}" stroke-width="1.4" stroke-dasharray="4 3"/>
      ${dots}
      <text x="48" y="148" class="at-label" fill="${P.red}">Sample Means x̄ (${evalData.count} samples, n = ${st.sampleN})</text>
    </g>
    ${seDim}
  `;

  return draftSvg({
    id: 'ch13-sampler',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Population distribution vs distribution of sample means',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh14Histogram(params, P) {
  const w3 = clamp(Number(params.a ?? 25), 10, 40);
  const f3 = clamp(Number(params.b ?? 30), 10, 60);
  const iqr = clamp(Number(params.c ?? 18), 6, 35);
  const fd3 = f3 / w3;
  const bins = [
    { l: '0–10', w: 10, f: 18, fd: 1.8, c: P.blue, soft: P.blueSoft },
    { l: '10–20', w: 10, f: 24, fd: 2.4, c: P.green, soft: P.greenSoft },
    { l: `20–${20 + w3}`, w: w3, f: f3, fd: fd3, c: P.red, soft: P.redSoft },
  ];
  let xCur = 52;
  const yBase = 228;
  const scW = 4.6;
  const scH = 56;
  const rects = bins.map(bn => {
    const bw = bn.w * scW;
    const bh = clamp(bn.fd * scH, 16, 175);
    const out = `<rect x="${xCur.toFixed(1)}" y="${(yBase - bh).toFixed(1)}" width="${bw.toFixed(1)}" height="${bh.toFixed(1)}" fill="${bn.soft}" stroke="${bn.c}" stroke-width="2"/>` +
      `<text x="${(xCur + bw / 2).toFixed(1)}" y="${(yBase - bh - 7).toFixed(1)}" text-anchor="middle" class="at-mono" fill="${bn.c}">area ${bn.f}</text>` +
      `<text x="${(xCur + bw / 2).toFixed(1)}" y="${yBase + 18}" text-anchor="middle" class="at-mono" fill="${P.muted}">${esc(bn.l)}</text>`;
    xCur += bw;
    return out;
  }).join('');

  const body = `
    <line x1="40" y1="${yBase}" x2="340" y2="${yBase}" stroke="${P.muted}" stroke-width="1.5"/>
    <g data-part="residuals">${rects}</g>
    <g data-part="fulcrum" transform="translate(352, 54)">
      <rect x="0" y="0" width="186" height="160" rx="8" fill="${P.card}" stroke="${P.amber}" stroke-width="1.6"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Area = Frequency</text>
      <text x="14" y="58" class="at-mono" fill="${P.red}">Bar height = f ÷ width</text>
      <text x="14" y="82" class="at-mono" fill="${P.red}">= ${f3} ÷ ${w3} = ${fmtNum(fd3)}</text>
      <text x="14" y="110" class="at-mono" fill="${P.amber}">Check: ${fmtNum(fd3)} × ${w3} = ${f3}</text>
      <text x="14" y="138" class="at-label" fill="${P.green}">Middle half IQR = ${iqr}</text>
    </g>
  `;
  return draftSvg({
    id: 'ch14-histogram',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Frequency-density histogram where bar area equals frequency',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh14(st, evalData, params, P) {
  if (st.mode === 'histogram') {
    return svgCh14Histogram(params, P);
  }
  if (st.mode === 'best-fit') {
    const ox = 66;
    const oy = 250;
    const sx = 64;
    const sy = 25;
    const toX = x => ox + x * sx;
    const toY = y => oy - y * sy;

    const grid = [];
    for (let gx = 1; gx <= 6; gx++) grid.push(`<line x1="${toX(gx)}" y1="28" x2="${toX(gx)}" y2="${oy}" stroke="${P.grid}"/>`);
    for (let gy = 2; gy <= 8; gy += 2) grid.push(`<line x1="${ox}" y1="${toY(gy)}" x2="${toX(6.6)}" y2="${toY(gy)}" stroke="${P.grid}"/>`);

    const squares = st.scatterPts.map(p => {
      const pred = st.mySlope * p.x + st.myIntercept;
      const px = toX(p.x);
      const py = toY(p.y);
      const ly = toY(pred);
      const side = Math.abs(py - ly);
      const topY = Math.min(py, ly);
      const h = side > 4 ? draftHatch({ region: { kind: 'rect', x: px, y: topY, width: side, height: side }, pattern: 'H1', pitch: 7 }).d : '';
      return `<rect x="${px.toFixed(1)}" y="${topY.toFixed(1)}" width="${side.toFixed(1)}" height="${side.toFixed(1)}" fill="${P.amberSoft}" stroke="${P.amber}" stroke-width="1.3"/>` +
        (h ? `<path d="${h}" stroke="${P.amber}" stroke-width="0.9" opacity="0.5"/>` : '') +
        keylineCircle(px, py, 5, P.blue, P.card, 1.4);
    }).join('');

    const olsLine = st.showBestFit
      ? `<line data-part="olsLine" x1="${toX(0.4)}" y1="${toY(evalData.ols.m * 0.4 + evalData.ols.c)}" x2="${toX(6.5)}" y2="${toY(evalData.ols.m * 6.5 + evalData.ols.c)}" stroke="${P.green}" stroke-width="2.2" stroke-dasharray="6 4"/>`
      : '';

    const y1 = st.mySlope * 1 + st.myIntercept;
    const y2 = st.mySlope * 6 + st.myIntercept;
    const body = `
      ${grid.join('')}
      <line x1="${ox}" y1="28" x2="${ox}" y2="${oy}" stroke="${P.ink}" stroke-width="1.6"/>
      <line x1="${ox}" y1="${oy}" x2="${toX(6.6)}" y2="${oy}" stroke="${P.ink}" stroke-width="1.6"/>
      <g data-part="residuals">${squares}</g>
      ${olsLine}
      <line data-part="fitLine" x1="${toX(0.5)}" y1="${toY(st.mySlope * 0.5 + st.myIntercept)}" x2="${toX(6.5)}" y2="${toY(st.mySlope * 6.5 + st.myIntercept)}" stroke="${P.red}" stroke-width="2.6"/>
      ${handlePuck('h1', toX(1), toY(y1), P.red, P, { part: 'fitLine' })}
      ${handlePuck('h2', toX(6), toY(y2), P.red, P, { part: 'fitLine' })}
      <text x="${ox + 12}" y="28" class="at-label" fill="${P.ink}">y = ${fmtNum(st.mySlope)}x + ${fmtNum(st.myIntercept)} · Total squared error = ${fmtNum(evalData.mySSR)}</text>
    `;
    return draftSvg({
      id: 'ch14-bestfit',
      vb: [0, 0, SVG_W, SVG_H],
      title: 'Least-squares regression with geometric residual squares',
      mode: 'geometric-construction',
      defs: themeStyleDefs(P),
      body,
    });
  }

  if (st.mode === 'level-out') {
    const x0 = 56;
    const x1 = SVG_W - 56;
    const yBase = 232;
    const scH = 8.5;
    const slotW = (x1 - x0) / Math.max(1, st.dots.length);
    const bw = Math.min(48, slotW - 12);
    const meanY = yBase - evalData.meanVal * scH;
    const bars = st.dots.map((v, i) => {
      const cx = x0 + (i + 0.5) * slotW;
      const bh = clamp(v, 1, 20) * scH;
      return `<rect x="${(cx - bw / 2).toFixed(1)}" y="${(yBase - bh).toFixed(1)}" width="${bw.toFixed(1)}" height="${bh.toFixed(1)}" rx="4" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="2"/>` +
        `<text x="${cx.toFixed(1)}" y="${yBase + 18}" text-anchor="middle" class="at-mono" fill="${P.muted}">#${i + 1}</text>` +
        handlePuck(`dot-${i}`, cx, yBase - bh, P.blue, P, { label: String(v), dyLabel: -14, part: 'dots' });
    }).join('');
    const body = `
      <line x1="${x0 - 8}" y1="${yBase}" x2="${x1 + 8}" y2="${yBase}" stroke="${P.ink}" stroke-width="1.6"/>
      ${bars}
      <line data-part="meanMark" x1="${x0 - 12}" y1="${meanY.toFixed(1)}" x2="${x1 + 12}" y2="${meanY.toFixed(1)}" stroke="${P.amber}" stroke-width="2.6" stroke-dasharray="6 4"/>
      <text x="${x0}" y="28" class="at-label" fill="${P.amber}">Level-out mean height = ${fmtNum(evalData.meanVal)} (Total ${evalData.totalSum} ÷ ${st.dots.length} bars) — drag any bar top ↕</text>
    `;
    return draftSvg({
      id: 'ch14-levelout',
      vb: [0, 0, SVG_W, SVG_H],
      title: 'Levelling out bar heights to find the arithmetic mean',
      mode: 'geometric-construction',
      defs: themeStyleDefs(P),
      body,
    });
  }

  const x0 = 44;
  const x1 = SVG_W - 44;
  const toX = v => x0 + ((v - 1) / 18) * (x1 - x0);
  const beamY = 178;
  const fulcX = toX(st.fulcrumX);
  const fulcCol = evalData.fulcrumBalanced ? P.green : P.amber;
  const tilt = clamp((evalData.meanVal - st.fulcrumX) * 2.4, -13, 13);
  const beamAtX = x => {
    const dx = x - fulcX;
    return beamY + dx * Math.tan((tilt * Math.PI) / 180);
  };

  const ticks = [2, 4, 6, 8, 10, 12, 14, 16, 18].map(n => {
    const tx = toX(n);
    return `<line x1="${tx}" y1="226" x2="${tx}" y2="234" stroke="${P.muted}" stroke-width="1"/>` +
      `<text x="${tx}" y="246" text-anchor="middle" class="at-mono" fill="${P.muted}">${n}</text>`;
  }).join('');

  const stackCounts = {};
  const dots = st.dots.map((v, i) => {
    stackCounts[v] = (stackCounts[v] || 0) + 1;
    const dx = toX(v);
    const by = beamAtX(dx);
    const dy = by - 12 - (stackCounts[v] - 1) * 18;
    return handlePuck(`dot-${i}`, dx, dy, P.blue, P, { label: String(v), dyLabel: -12, part: 'dots' });
  }).join('');

  const showCenters = Boolean(st.revealedCenter);
  const splitMeanMed = Math.abs(evalData.meanVal - evalData.medianVal) < 1.3;
  const meanX = toX(evalData.meanVal);
  const medX = toX(evalData.medianVal);
  const markers = showCenters
    ? `<line data-part="meanMark" x1="${meanX}" y1="36" x2="${meanX}" y2="224" stroke="${P.red}" stroke-width="1.8" stroke-dasharray="4 3"/>` +
      `<text x="${splitMeanMed ? meanX - 8 : meanX}" y="26" text-anchor="${splitMeanMed ? 'end' : 'middle'}" class="at-label" fill="${P.red}">Mean ${fmtNum(evalData.meanVal)}</text>` +
      `<line data-part="medianMark" x1="${medX}" y1="48" x2="${medX}" y2="224" stroke="${P.green}" stroke-width="2"/>` +
      `<text x="${splitMeanMed ? medX + 8 : medX}" y="${splitMeanMed ? 26 : 42}" text-anchor="${splitMeanMed ? 'start' : 'middle'}" class="at-label" fill="${P.green}">Median ${fmtNum(evalData.medianVal)}</text>`
    : '';

  const predictMarker = handlePuck('predict', toX(st.predictVal ?? 10), 56, P.red, P, {
    label: `Predict ${fmtNum(st.predictVal ?? 10)}`,
    dyLabel: -12,
    part: 'fulcrum',
  });

  const body = `
    <line x1="${x0}" y1="230" x2="${x1}" y2="230" stroke="${P.muted}" stroke-width="1.5"/>
    ${ticks}
    ${markers}
    <g transform="rotate(${tilt.toFixed(2)} ${fulcX.toFixed(1)} ${beamY})">
      <line x1="${x0}" y1="${beamY}" x2="${x1}" y2="${beamY}" stroke="${P.ink}" stroke-width="4" stroke-linecap="round"/>
    </g>
    ${dots}
    ${predictMarker}
    <g data-part="fulcrum" data-handle="fulcrum">
      <polygon points="${(fulcX - 15).toFixed(1)},228 ${(fulcX + 15).toFixed(1)},228 ${fulcX.toFixed(1)},${beamY + 2}" fill="${fulcCol}" stroke="${P.ink}" stroke-width="1.6"/>
      <text x="${fulcX.toFixed(1)}" y="266" text-anchor="middle" class="at-label" fill="${fulcCol}">Fulcrum = ${fmtNum(st.fulcrumX)}</text>
    </g>
  `;

  return draftSvg({
    id: 'ch14-balance',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Data balance fulcrum showing mean vs median sensitivity',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCalc(chNum, st, evalData, P) {
  const x0 = 64;
  const x1 = SVG_W - 28;
  const toX = u => x0 + (u / 3.0) * (x1 - x0);
  const panels = [
    { key: 'f', lbl: 'f(x)', yMid: 62, sc: 9.5, col: P.blue, part: 'curveF' },
    { key: 'fp', lbl: "f′(x)", yMid: 150, sc: 10.5, col: P.red, part: 'curveFp' },
    { key: 'F', lbl: '∫f(t)dt', yMid: 238, sc: 8.5, col: P.amber, part: 'curveInt' },
  ];

  // Signed area shading under f(x) in Ch 18 (or both)
  const strips = [];
  if (chNum === 18) {
    const stepU = 0.06;
    for (let u = 0; u < st.refX; u += stepU) {
      const yv = calcPoint(st.curveKind, u).f;
      const px = toX(u);
      const pw = Math.max(2, toX(Math.min(st.refX, u + stepU)) - px);
      const bh = clamp(yv * 9.5, -36, 36);
      const ry = yv >= 0 ? 62 - bh : 62;
      strips.push(`<rect x="${px.toFixed(1)}" y="${ry.toFixed(1)}" width="${pw.toFixed(1)}" height="${Math.abs(bh).toFixed(1)}" fill="${yv >= 0 ? P.blueSoft : P.redSoft}" stroke="none"/>`);
    }
  }

  const curves = panels.map(pn => {
    const axis = `<line x1="${x0}" y1="${pn.yMid}" x2="${x1}" y2="${pn.yMid}" stroke="${P.muted}" stroke-width="1"/>` +
      `<text x="14" y="${pn.yMid + 4}" class="at-label" fill="${pn.col}">${esc(pn.lbl)}</text>`;

    if (pn.key === 'fp' && st.predictEnabled && !st.predictRevealed) {
      const nodes = st.predictNodes.map((nd, i) =>
        handlePuck(`pred-${i}`, toX(nd.x), clamp(pn.yMid - nd.y * pn.sc, pn.yMid - 34, pn.yMid + 34), P.red, P, { part: pn.part })
      ).join('');
      return axis +
        `<text x="${x0 + 8}" y="${pn.yMid - 38}" class="at-note">Drag the 5 red sketch dots, then press Reveal my f′(x)</text>` +
        nodes;
    }

    let segs = [];
    let cur = '';
    for (let u = 0; u <= 3.001; u += 0.04) {
      const v = calcPoint(st.curveKind, u)[pn.key];
      if (!Number.isFinite(v)) {
        if (cur) { segs.push(cur); cur = ''; }
        continue;
      }
      const px = toX(u);
      const py = clamp(pn.yMid - v * pn.sc, pn.yMid - 38, pn.yMid + 38);
      cur += `${cur ? 'L' : 'M'}${px.toFixed(1)},${py.toFixed(1)} `;
    }
    if (cur) segs.push(cur);
    const paths = segs.map(d => `<path d="${d}" stroke="${pn.col}" stroke-width="2.4" fill="none"/>`).join('');

    let disc = '';
    if (pn.key === 'fp' && (st.curveKind === 'cusp' || st.curveKind === 'step')) {
      const cx = toX(1.5);
      disc = `<circle cx="${cx.toFixed(1)}" cy="${pn.yMid}" r="4.5" fill="${P.card}" stroke="${P.red}" stroke-width="2"/>`;
    }
    return `<g data-part="${pn.part}">${axis}${paths}${disc}</g>`;
  }).join('');

  const rx = toX(st.refX);
  const fy = clamp(62 - evalData.val.f * 9.5, 22, 100);
  let tangentSeg = '';
  if (evalData.val.definedDeriv) {
    const du = 0.28;
    const xA = toX(st.refX - du), xB = toX(st.refX + du);
    const yA = clamp(62 - (evalData.val.f - evalData.val.fp * du) * 9.5, 18, 102);
    const yB = clamp(62 - (evalData.val.f + evalData.val.fp * du) * 9.5, 18, 102);
    tangentSeg = `<line x1="${xA.toFixed(1)}" y1="${yA.toFixed(1)}" x2="${xB.toFixed(1)}" y2="${yB.toFixed(1)}" stroke="${P.red}" stroke-width="2.8" stroke-linecap="round"/>`;
  }

  const body = `
    ${strips.join('')}
    ${curves}
    ${tangentSeg}
    <g data-part="refLine" data-handle="refX">
      <line x1="${rx.toFixed(1)}" y1="18" x2="${rx.toFixed(1)}" y2="270" stroke="${P.ink}" stroke-width="18" opacity="0.01"/>
      <line x1="${rx.toFixed(1)}" y1="20" x2="${rx.toFixed(1)}" y2="266" stroke="${P.green}" stroke-width="2" stroke-dasharray="5 3"/>
      <circle cx="${rx.toFixed(1)}" cy="${fy.toFixed(1)}" r="5" fill="${P.blue}" stroke="${P.card}" stroke-width="1.5"/>
      <circle cx="${rx.toFixed(1)}" cy="264" r="7" fill="${P.green}" stroke="${P.card}" stroke-width="2"/>
      <text x="${rx.toFixed(1)}" y="282" text-anchor="middle" class="at-label" fill="${P.green}">x = ${fmtNum(st.refX)}</text>
    </g>
  `;

  return draftSvg({
    id: `ch${chNum}-calc`,
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Aligned f(x), f prime(x), and integral accumulation graphs',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh06(params, P) {
  const n = clamp(Math.round(Number(params.a ?? 5)), 3, 8);
  const first = clamp(Math.round(Number(params.b ?? 1)), 1, 5);
  const d = clamp(Math.round(Number(params.c ?? 1)), 1, 3);
  const last = first + (n - 1) * d;
  const pair = first + last;
  const sum = (n * pair) / 2;
  const x0 = 48;
  const yBase = 216;
  const bw = Math.min(34, 240 / n);
  const uH = Math.min(13, 154 / Math.max(1, pair));

  const cols = Array.from({ length: n }, (_, i) => {
    const tVal = first + i * d;
    const h1 = tVal * uH;
    const h2 = (pair - tVal) * uH;
    const x = x0 + i * bw;
    return `<g data-part="stairRed"><rect x="${x.toFixed(1)}" y="${(yBase - h1).toFixed(1)}" width="${(bw - 4).toFixed(1)}" height="${h1.toFixed(1)}" rx="2" fill="${P.redSoft}" stroke="${P.red}" stroke-width="1.8"/></g>` +
      `<g data-part="stairBlue"><rect x="${x.toFixed(1)}" y="${(yBase - h1 - h2).toFixed(1)}" width="${(bw - 4).toFixed(1)}" height="${h2.toFixed(1)}" rx="2" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="1.8"/></g>`;
  }).join('');

  const dim = safeDimension({
    axis: 'x',
    witnesses: [[x0, yBase], [x0 + n * bw - 4, yBase]],
    position: 244,
    label: { text: `${n} columns`, anchor: [x0 + (n * bw) / 2, 260] },
  });

  const body = `
    ${cols}
    ${dim}
    <line x1="${x0 - 6}" y1="${(yBase - pair * uH).toFixed(1)}" x2="${(x0 + n * bw).toFixed(1)}" y2="${(yBase - pair * uH).toFixed(1)}" stroke="${P.amber}" stroke-width="1.8" stroke-dasharray="4 3"/>
    <g transform="translate(318, 48)">
      <rect x="0" y="0" width="218" height="172" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Flipped-Staircase Rectangle</text>
      <text x="14" y="58" class="at-mono" fill="${P.red}">First term: ${first}</text>
      <text x="14" y="82" class="at-mono" fill="${P.blue}">Last term:  ${last}</text>
      <text x="14" y="108" class="at-mono" fill="${P.amber}">Every column: ${first} + ${last} = ${pair}</text>
      <text x="14" y="134" class="at-mono" fill="${P.muted}">Double box: ${n} × ${pair} = ${n * pair}</text>
      <text x="14" y="158" class="at-label" fill="${P.green}">Half = ${fmtNum(sum)}</text>
    </g>
  `;

  return draftSvg({
    id: 'ch06-gauss',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Arithmetic sequence staircase paired with its flipped copy',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh08(params, P) {
  const A = clamp(Math.round(Number(params.a ?? 50)), 25, 70);
  const B = clamp(Math.round(Number(params.b ?? 60)), 25, 70);
  const C = 180 - A - B;
  const n = clamp(Math.round(Number(params.c ?? 6)), 3, 8);
  const rad = d => (d * Math.PI) / 180;
  const baseY = 204;
  const xA = 56;
  const hUnit = (Math.sin(rad(A)) * Math.sin(rad(B))) / Math.sin(rad(A + B));
  const L = Math.min(180, 118 / Math.max(0.2, hUnit));
  const xB = xA + L;
  const ac = (L * Math.sin(rad(B))) / Math.sin(rad(A + B));
  const xC = xA + ac * Math.cos(rad(A));
  const yC = baseY - ac * Math.sin(rad(A));

  // Regular n-gon exterior turn fan on the right
  const polyCx = 434;
  const polyCy = 136;
  const polyR = 64;
  const polyPts = Array.from({ length: n }, (_, k) => {
    const th = -Math.PI / 2 + (k * 2 * Math.PI) / n;
    return [polyCx + polyR * Math.cos(th), polyCy + polyR * Math.sin(th)];
  });
  const polyPath = polyPts.map((pt, i) => `${i === 0 ? 'M' : 'L'}${pt[0].toFixed(1)},${pt[1].toFixed(1)}`).join(' ') + ' Z';
  const extTurn = roundTo(360 / n, 1);

  const body = `
    <line x1="36" y1="${yC.toFixed(1)}" x2="296" y2="${yC.toFixed(1)}" stroke="${P.green}" stroke-width="1.8" stroke-dasharray="5 4"/>
    <polygon points="${xA},${baseY} ${xB.toFixed(1)},${baseY} ${xC.toFixed(1)},${yC.toFixed(1)}" fill="${P.blueSoft}" stroke="${P.ink}" stroke-width="2.2"/>
    <line x1="${xB.toFixed(1)}" y1="${baseY}" x2="${(xB + 54).toFixed(1)}" y2="${baseY}" stroke="${P.ink}" stroke-width="2"/>
    <g data-part="angA">
      <circle cx="${xA}" cy="${baseY}" r="14" fill="${P.redSoft}" stroke="${P.red}" stroke-width="1.8"/>
      <text x="${xA + 22}" y="${baseY - 10}" class="at-label" fill="${P.red}">${A}°</text>
    </g>
    <g data-part="angB">
      <circle cx="${xB.toFixed(1)}" cy="${baseY}" r="14" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="1.8"/>
      <text x="${(xB - 28).toFixed(1)}" y="${baseY - 10}" class="at-label" fill="${P.blue}">${B}°</text>
      <text x="${(xB + 26).toFixed(1)}" y="${baseY - 10}" class="at-mono" fill="${P.amber}">${180 - B}°</text>
    </g>
    <text x="${xC.toFixed(1)}" y="${(yC - 10).toFixed(1)}" text-anchor="middle" class="at-label" fill="${P.ink}">C = ${C}°</text>
    <text x="56" y="246" class="at-label" fill="${P.ink}">${A}° + ${B}° + ${C}° = 180°</text>
    <path d="${polyPath}" fill="${P.amberSoft}" stroke="${P.amber}" stroke-width="2.2"/>
    <text x="${polyCx}" y="38" text-anchor="middle" class="at-label" fill="${P.amber}">${n}-gon · ${n} turns × ${extTurn}° = 360°</text>
    <text x="${polyCx}" y="246" text-anchor="middle" class="at-mono" fill="${P.ink}">Inside total = ${(n - 2) * 180}°</text>
  `;

  return draftSvg({
    id: 'ch08-angles',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Parallel triangle angle proof and polygon exterior turn total',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh09(params, P) {
  const ab = clamp(Number(params.a ?? 6), 3, 9);
  const r = clamp(Number(params.b ?? 4), 1.5, 6);
  const hP = clamp(Number(params.c ?? 2), 0, 4.5);
  const half = ab / 2;
  const cross = r > half + 1e-6;
  const sc = 24;
  const xm = 178;
  const yM = 148;
  const xA = xm - half * sc;
  const xB = xm + half * sc;
  const hx = cross ? Math.sqrt(r * r - half * half) : 0;
  const yP = yM - hP * sc;

  const arcSvg = cross
    ? `<g data-part="arcs">
         <circle cx="${xA}" cy="${yM}" r="${(r * sc).toFixed(1)}" fill="none" stroke="${P.blue}" stroke-width="1.6" stroke-dasharray="6 4"/>
         <circle cx="${xB}" cy="${yM}" r="${(r * sc).toFixed(1)}" fill="none" stroke="${P.blue}" stroke-width="1.6" stroke-dasharray="6 4"/>
         ${keylineCircle(xm, yM - hx * sc, 4.5, P.blue, P.card, 1.4)}
         ${keylineCircle(xm, yM + hx * sc, 4.5, P.blue, P.card, 1.4)}
       </g>`
    : `<g data-part="arcs">
         <circle cx="${xA}" cy="${yM}" r="${(r * sc).toFixed(1)}" fill="none" stroke="${P.amber}" stroke-width="1.8" stroke-dasharray="5 4"/>
         <circle cx="${xB}" cy="${yM}" r="${(r * sc).toFixed(1)}" fill="none" stroke="${P.amber}" stroke-width="1.8" stroke-dasharray="5 4"/>
       </g>`;

  const bisectorSvg = cross
    ? `<g data-part="bisector">
         <line x1="${xm}" y1="${Math.max(24, yM - hx * sc - 14).toFixed(1)}" x2="${xm}" y2="${Math.min(266, yM + hx * sc + 14).toFixed(1)}" stroke="${P.red}" stroke-width="2.4"/>
         <polyline points="${xA},${yM} ${xm},${yP.toFixed(1)} ${xB},${yM}" fill="none" stroke="${P.green}" stroke-width="2" stroke-dasharray="5 3"/>
         ${keylineCircle(xm, yP, 5, P.green, P.card, 1.5)}
         <text x="${xm + 10}" y="${yP.toFixed(1)}" class="at-label" fill="${P.green}">P</text>
       </g>`
    : '';

  const distPA = Math.hypot(half, hP);
  const body = `
    ${arcSvg}
    <line x1="${xA}" y1="${yM}" x2="${xB}" y2="${yM}" stroke="${P.ink}" stroke-width="2.6"/>
    ${bisectorSvg}
    ${keylineCircle(xA, yM, 4.5, P.ink, P.card, 1.4)}
    ${keylineCircle(xB, yM, 4.5, P.ink, P.card, 1.4)}
    <text x="${xA - 12}" y="${yM + 4}" text-anchor="end" class="at-label" fill="${P.ink}">A</text>
    <text x="${xB + 12}" y="${yM + 4}" class="at-label" fill="${P.ink}">B</text>
    <g transform="translate(332, 48)">
      <rect x="0" y="0" width="204" height="172" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Perpendicular Bisector</text>
      <text x="14" y="58" class="at-mono" fill="${P.blue}">Base AB = ${ab} cm (r = ${r} cm)</text>
      <text x="14" y="84" class="at-mono" fill="${cross ? P.green : P.amber}">${cross ? 'Arcs cross twice at 90°' : `Need compass > ${fmtNum(half)} cm`}</text>
      <text x="14" y="114" class="at-mono" fill="${P.green}">PA = PB = ${fmtNum(distPA)} cm</text>
      <text x="14" y="146" class="at-note">Equal radii build symmetry</text>
    </g>
  `;

  return draftSvg({
    id: 'ch09-loci',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Compass construction of perpendicular bisector locus',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh10(params, P) {
  const r = clamp(Number(params.a ?? 4), 2, 6);
  const n = clamp(Math.round(Number(params.b ?? 12)), 4, 24);
  const ang = clamp(Number(params.c ?? 90), 0, 360);
  const cx = 112;
  const cy = 128;
  const R = r * 13;
  const sliceA = (2 * Math.PI) / n;

  const slices = Array.from({ length: n }, (_, i) => {
    const a0 = -Math.PI / 2 + i * sliceA;
    const a1 = a0 + sliceA;
    const x1 = cx + R * Math.cos(a0);
    const y1 = cy + R * Math.sin(a0);
    const x2 = cx + R * Math.cos(a1);
    const y2 = cy + R * Math.sin(a1);
    const fill = i % 2 === 0 ? P.blueSoft : P.card;
    return `<path d="M ${cx},${cy} L ${x1.toFixed(1)},${y1.toFixed(1)} A ${R},${R} 0 0 1 ${x2.toFixed(1)},${y2.toFixed(1)} Z" fill="${fill}" stroke="${P.blue}" stroke-width="1"/>`;
  }).join('');

  const secRad = (ang * Math.PI) / 180;
  const sx2 = cx + R * Math.cos(-Math.PI / 2 + secRad);
  const sy2 = cy + R * Math.sin(-Math.PI / 2 + secRad);
  const largeArc = ang > 180 ? 1 : 0;
  const sectorSvg = ang >= 360
    ? `<circle data-part="sector" cx="${cx}" cy="${cy}" r="${R}" fill="${P.greenSoft}" stroke="${P.green}" stroke-width="2.2"/>`
    : (ang > 0
        ? `<path data-part="sector" d="M ${cx},${cy} L ${cx},${cy - R} A ${R},${R} 0 ${largeArc} 1 ${sx2.toFixed(1)},${sy2.toFixed(1)} Z" fill="${P.greenSoft}" stroke="${P.green}" stroke-width="2.2"/>`
        : '');

  // Rearranged rectangle strip πr × r on right
  const stripX = 248;
  const stripW = 248;
  const halfN = Math.max(2, Math.floor(n / 2));
  const toothW = stripW / halfN;
  const teeth = Array.from({ length: halfN }, (_, k) => {
    const tx = stripX + k * toothW;
    return `<polygon points="${tx.toFixed(1)},${cy + R / 2} ${(tx + toothW).toFixed(1)},${cy + R / 2} ${(tx + toothW / 2).toFixed(1)},${cy - R / 2}" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="1.2"/>`;
  }).join('');
  const area = Math.PI * r * r;

  const body = `
    ${slices}
    ${sectorSvg}
    <g data-part="strip">
      <rect x="${stripX}" y="${cy - R / 2}" width="${stripW}" height="${R}" fill="none" stroke="${P.red}" stroke-width="2" stroke-dasharray="5 3"/>
      ${teeth}
      <text x="${stripX + stripW / 2}" y="${cy + R / 2 + 22}" text-anchor="middle" class="at-label" fill="${P.blue}">Bottom width ≈ πr = ${fmtNum(Math.PI * r)} cm</text>
      <text x="${stripX - 10}" y="${cy + 4}" text-anchor="end" class="at-label" fill="${P.red}">r</text>
    </g>
    <text x="48" y="256" class="at-label" fill="${P.ink}">Area = πr × r = ${fmtNum(area)} cm² · Green slice (${ang}°) = ${fmtNum((area * ang) / 360)} cm²</text>
  `;

  return draftSvg({
    id: 'ch10-circles',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Circle wedge rearrangement into a πr by r strip',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh11(params, P) {
  const k = clamp(Number(params.a ?? 2), 0.5, 3);
  const ccx = clamp(Number(params.b ?? 0), 0, 3);
  const ccy = clamp(Number(params.c ?? 0), 0, 2);
  const u = 18;
  const ox = 56;
  const oy = 218;
  const toX = gx => ox + gx * u;
  const toY = gy => oy - gy * u;
  const obj = [[3, 3], [5, 3], [3, 4]];
  const img = obj.map(([x, y]) => [ccx + k * (x - ccx), ccy + k * (y - ccy)]);

  const rays = obj.map((pt, i) => {
    const far = k >= 1 ? img[i] : pt;
    return `<line x1="${toX(ccx)}" y1="${toY(ccy)}" x2="${toX(far[0]).toFixed(1)}" y2="${toY(far[1]).toFixed(1)}" stroke="${P.muted}" stroke-width="1.2" stroke-dasharray="4 3"/>`;
  }).join('');

  const polyPts = pts => pts.map(([x, y]) => `${toX(x).toFixed(1)},${toY(y).toFixed(1)}`).join(' ');
  const grid = [];
  for (let gx = 0; gx <= 15; gx += 3) grid.push(`<line x1="${toX(gx)}" y1="36" x2="${toX(gx)}" y2="${oy}" stroke="${P.grid}"/>`);
  for (let gy = 0; gy <= 9; gy += 3) grid.push(`<line x1="${ox}" y1="${toY(gy)}" x2="${toX(15)}" y2="${toY(gy)}" stroke="${P.grid}"/>`);

  const body = `
    ${grid.join('')}
    ${rays}
    <g data-part="imgTri">
      <polygon points="${polyPts(img)}" fill="${P.redSoft}" stroke="${P.red}" stroke-width="2.4"/>
    </g>
    <g data-part="objTri">
      <polygon points="${polyPts(obj)}" fill="${P.blueSoft}" stroke="${P.blue}" stroke-width="2.2"/>
    </g>
    ${keylineCircle(toX(ccx), toY(ccy), 4.5, P.ink, P.card, 1.4)}
    <text x="${toX(ccx) - 8}" y="${toY(ccy) + 18}" class="at-label" fill="${P.ink}">C(${ccx},${ccy})</text>
    <g transform="translate(342, 48)">
      <rect x="0" y="0" width="194" height="162" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Similarity Enlargement</text>
      <text x="14" y="58" class="at-mono" fill="${P.blue}">Scale factor k = ${fmtNum(k)}</text>
      <text x="14" y="84" class="at-mono" fill="${P.red}">Lengths × ${fmtNum(k)}</text>
      <text x="14" y="110" class="at-label" fill="${P.green}">Area × k² = ${fmtNum(k * k)}×</text>
      <text x="14" y="138" class="at-note">Every angle stays equal</text>
    </g>
  `;

  return draftSvg({
    id: 'ch11-similarity',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Triangle enlargement by scale factor k with area k² scaling',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh12(params, P) {
  const deg = clamp(Number(params.a ?? 30), 0, 90);
  const r = clamp(Number(params.b ?? 2), 2, 4);
  const cmp = clamp(Number(params.c ?? 60), 0, 90);
  const ox = 82;
  const oy = 216;
  const R = r * 40;
  const rad = d => (d * Math.PI) / 180;
  const sinV = deg === 90 ? 1 : Math.sin(rad(deg));
  const cosV = deg === 90 ? 0 : Math.cos(rad(deg));
  const px = ox + R * cosV;
  const py = oy - R * sinV;
  const qx = ox + R * (cmp === 90 ? 0 : Math.cos(rad(cmp)));
  const qy = oy - R * (cmp === 90 ? 1 : Math.sin(rad(cmp)));

  const body = `
    <line x1="${ox}" y1="${oy}" x2="${ox + R + 24}" y2="${oy}" stroke="${P.muted}" stroke-width="1.4"/>
    <line x1="${ox}" y1="${oy}" x2="${ox}" y2="${oy - R - 20}" stroke="${P.muted}" stroke-width="1.4"/>
    <path d="M ${ox + R},${oy} A ${R},${R} 0 0 0 ${ox},${oy - R}" fill="none" stroke="${P.muted}" stroke-width="1.6"/>
    ${cmp !== deg ? `<line x1="${ox}" y1="${oy}" x2="${qx.toFixed(1)}" y2="${qy.toFixed(1)}" stroke="${P.muted}" stroke-width="1.4" stroke-dasharray="4 3"/>` : ''}
    <line x1="${ox}" y1="${oy}" x2="${px.toFixed(1)}" y2="${oy}" stroke="${P.blue}" stroke-width="3"/>
    <line x1="${px.toFixed(1)}" y1="${oy}" x2="${px.toFixed(1)}" y2="${py.toFixed(1)}" stroke="${P.red}" stroke-width="3"/>
    <g data-part="theta">
      <line x1="${ox}" y1="${oy}" x2="${px.toFixed(1)}" y2="${py.toFixed(1)}" stroke="${P.green}" stroke-width="3"/>
      <text x="${ox + 26}" y="${oy - 12}" class="at-label" fill="${P.ink}">θ = ${deg}°</text>
    </g>
    ${keylineCircle(px, py, 5, P.ink, P.card, 1.5)}
    <g transform="translate(314, 48)">
      <rect x="0" y="0" width="222" height="170" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Unit-Circle Ratios (r = ${r})</text>
      <text x="14" y="58" class="at-mono" fill="${P.red}">sin ${deg}° = ${fmtNum(sinV)}</text>
      <text x="14" y="84" class="at-mono" fill="${P.blue}">cos ${deg}° = ${fmtNum(cosV)}</text>
      <text x="14" y="110" class="at-mono" fill="${P.amber}">${deg === 90 ? 'tan 90° undefined' : `tan ${deg}° = ${fmtNum(sinV / cosV)}`}</text>
      <text x="14" y="142" class="at-label" fill="${P.green}">sin²θ + cos²θ = 1.00</text>
    </g>
  `;

  return draftSvg({
    id: 'ch12-trig',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Quarter-circle right triangle showing sine, cosine, and radius invariance',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh15(params, P) {
  const n = clamp(Math.round(Number(params.a ?? 6)), 4, 10);
  const k = clamp(Math.round(Number(params.b ?? 3)), 0, n);
  const p = clamp(Number(params.c ?? 50), 20, 80) / 100;
  const ways = comb(n, k);
  const prob = ways * Math.pow(p, k) * Math.pow(1 - p, n - k);
  const x0 = 46;
  const yBase = 232;
  const bw = Math.min(34, 248 / (n + 1));
  let maxP = 0;
  for (let i = 0; i <= n; i++) maxP = Math.max(maxP, comb(n, i) * Math.pow(p, i) * Math.pow(1 - p, n - i));

  const bars = Array.from({ length: n + 1 }, (_, i) => {
    const pr = comb(n, i) * Math.pow(p, i) * Math.pow(1 - p, n - i);
    const bh = clamp((pr / Math.max(0.01, maxP)) * 155, 8, 160);
    const isPeak = i === k;
    const x = x0 + i * bw;
    return `<g data-part="${isPeak ? 'peakCol' : 'pegCols'}">` +
      `<rect x="${x.toFixed(1)}" y="${(yBase - bh).toFixed(1)}" width="${(bw - 4).toFixed(1)}" height="${bh.toFixed(1)}" rx="3" fill="${isPeak ? P.redSoft : P.blueSoft}" stroke="${isPeak ? P.red : P.blue}" stroke-width="1.8"/>` +
      `<text x="${(x + (bw - 4) / 2).toFixed(1)}" y="${yBase + 16}" text-anchor="middle" class="at-mono" fill="${P.muted}">${i}</text>` +
      `</g>`;
  }).join('');

  const body = `
    <line x1="${x0 - 6}" y1="${yBase}" x2="${(x0 + (n + 1) * bw).toFixed(1)}" y2="${yBase}" stroke="${P.muted}" stroke-width="1.4"/>
    ${bars}
    <g transform="translate(322, 48)">
      <rect x="0" y="0" width="214" height="162" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Galton Peg Lattice</text>
      <text x="14" y="58" class="at-mono" fill="${P.blue}">Rows: n = ${n} · Right p = ${Math.round(p * 100)}%</text>
      <text x="14" y="86" class="at-mono" fill="${P.red}">Paths C(${n}, ${k}) = ${ways}</text>
      <text x="14" y="114" class="at-label" fill="${P.green}">Chance P(X=${k}) = ${fmtNum(prob * 100)}%</text>
      <text x="14" y="142" class="at-note">Middle bins collect more routes</text>
    </g>
  `;

  return draftSvg({
    id: 'ch15-galton',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Binomial Galton pegboard path counts and probability bars',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh16(params, P) {
  const prevPct = clamp(Number(params.a ?? 2), 1, 25);
  const sensPct = clamp(Number(params.b ?? 95), 60, 99);
  const fprPct = clamp(Number(params.c ?? 5), 1, 25);
  const sick = 1000 * (prevPct / 100);
  const healthy = 1000 - sick;
  const tp = sick * (sensPct / 100);
  const fp = healthy * (fprPct / 100);
  const ppv = (tp / Math.max(1e-6, tp + fp)) * 100;

  const sqX = 48;
  const sqY = 44;
  const sqW = 216;
  const sqH = 188;
  const wD = Math.max(22, (prevPct / 100) * sqW * 2.2);
  const hTP = (sensPct / 100) * sqH;
  const hFP = Math.max(16, (fprPct / 100) * sqH * 1.8);

  const body = `
    <rect x="${sqX}" y="${sqY}" width="${sqW}" height="${sqH}" fill="${P.card}" stroke="${P.ink}" stroke-width="2"/>
    <rect data-part="truePos" x="${sqX}" y="${(sqY + sqH - hTP).toFixed(1)}" width="${wD.toFixed(1)}" height="${hTP.toFixed(1)}" fill="${P.redSoft}" stroke="${P.red}" stroke-width="1.8"/>
    <rect data-part="falsePos" x="${(sqX + wD).toFixed(1)}" y="${(sqY + sqH - hFP).toFixed(1)}" width="${(sqW - wD).toFixed(1)}" height="${hFP.toFixed(1)}" fill="${P.amberSoft}" stroke="${P.amber}" stroke-width="1.8"/>
    <text x="${sqX + sqW / 2}" y="28" text-anchor="middle" class="at-label" fill="${P.blue}">1,000 people (${Math.round(sick)} with trait · ${Math.round(healthy)} without)</text>
    <g transform="translate(292, 48)">
      <rect x="0" y="0" width="244" height="176" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">Natural Frequencies out of 1,000</text>
      <text x="14" y="58" class="at-mono" fill="${P.red}">True alarms:  ${tp.toFixed(1)}</text>
      <text x="14" y="84" class="at-mono" fill="${P.amber}">False alarms: ${fp.toFixed(1)}</text>
      <text x="14" y="114" class="at-label" fill="${P.green}">Real chance given +: ${ppv.toFixed(1)}%</text>
      <text x="14" y="146" class="at-note">${tp.toFixed(1)} ÷ (${tp.toFixed(1)} + ${fp.toFixed(1)})</text>
    </g>
  `;

  return draftSvg({
    id: 'ch16-bayes',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Bayesian 1,000-person natural-frequency probability square',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh19(params, P) {
  const ax = Number(params.a ?? 3.5);
  const ay = 1.2;
  const magB = Number(params.b ?? 2.0);
  const angDeg = Number(params.c ?? 60);
  const angRad = (angDeg * Math.PI) / 180;
  const baseAng = Math.atan2(ay, ax);
  const bx = magB * Math.cos(baseAng + angRad);
  const by = magB * Math.sin(baseAng + angRad);
  const ox = 56;
  const oy = 216;
  const sc = 34;
  const p1x = ox + ax * sc;
  const p1y = oy - ay * sc;
  const p2x = p1x + bx * sc;
  const p2y = p1y - by * sc;

  const arrA = draftArrow({ from: [ox, oy], to: [p1x, p1y] });
  const arrB = draftArrow({ from: [p1x, p1y], to: [p2x, p2y] });
  const arrSum = draftArrow({ from: [ox, oy], to: [p2x, p2y] });
  const magA = Math.hypot(ax, ay);
  const cosC = Math.abs(angDeg - 90) < 1e-6 ? 0 : Math.cos(angRad);
  const dot = magA * magB * cosC;

  const body = `
    <g data-part="vecA">
      <path d="${arrA.shaftD}" stroke="${P.red}" stroke-width="3.2" stroke-linecap="round"/>
      <path d="${arrA.headD}" stroke="${P.red}" stroke-width="2.4" fill="none"/>
      <text x="${((ox + p1x) / 2).toFixed(1)}" y="${(oy - 4).toFixed(1)}" class="at-label" fill="${P.red}">a = (${fmtNum(ax)}, 1.2)</text>
    </g>
    <g data-part="vecB">
      <path d="${arrB.shaftD}" stroke="${P.blue}" stroke-width="3.2" stroke-linecap="round"/>
      <path d="${arrB.headD}" stroke="${P.blue}" stroke-width="2.4" fill="none"/>
      <text x="${(p1x + 8).toFixed(1)}" y="${((p1y + p2y) / 2).toFixed(1)}" class="at-label" fill="${P.blue}">b (${angDeg}°)</text>
    </g>
    <g data-part="vecSum">
      <path d="${arrSum.shaftD}" stroke="${P.green}" stroke-width="3.2" stroke-linecap="round"/>
      <path d="${arrSum.headD}" stroke="${P.green}" stroke-width="2.4" fill="none"/>
    </g>
    <g transform="translate(314, 48)">
      <rect x="0" y="0" width="222" height="162" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.green}">Shortcut a + b</text>
      <text x="14" y="58" class="at-mono" fill="${P.green}">(${fmtNum(ax + bx)}, ${fmtNum(ay + by)})</text>
      <text x="14" y="86" class="at-mono" fill="${P.ink}">Length |a + b| = ${fmtNum(Math.hypot(ax + bx, ay + by))}</text>
      <text x="14" y="114" class="at-label" fill="${P.amber}">Dot a · b = ${fmtNum(dot)}</text>
      <text x="14" y="142" class="at-note">${Math.abs(dot) < 1e-3 ? 'Right angle (90°)!' : '|a||b| cos θ projection'}</text>
    </g>
  `;

  return draftSvg({
    id: 'ch19-vectors',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Nose-to-tail vector addition and dot-product projection',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

function svgCh20(params, P) {
  const mA = Number(params.a ?? 2.0);
  const mB = Number(params.b ?? 1.0);
  const mD = Number(params.c ?? 2.0);
  const det = mA * mD - mB * mB;
  const tr = mA + mD;
  const disc = Math.max(0, tr * tr - 4 * det);
  const l1 = 0.5 * (tr + Math.sqrt(disc));
  const l2 = 0.5 * (tr - Math.sqrt(disc));
  const ox = 92;
  const oy = 212;
  const sc = 42;
  const iX = ox + mA * sc;
  const iY = oy - mB * sc;
  const jX = ox + mB * sc;
  const jY = oy - mD * sc;
  const sumX = iX + (jX - ox);
  const sumY = iY + (jY - oy);
  const arrI = draftArrow({ from: [ox, oy], to: [iX, iY] });
  const arrJ = draftArrow({ from: [ox, oy], to: [jX, jY] });

  const body = `
    <g data-part="detArea">
      <polygon points="${ox},${oy} ${iX.toFixed(1)},${iY.toFixed(1)} ${sumX.toFixed(1)},${sumY.toFixed(1)} ${jX.toFixed(1)},${jY.toFixed(1)}" fill="${P.amberSoft}" stroke="${P.amber}" stroke-width="2"/>
    </g>
    <g data-part="basisI">
      <path d="${arrI.shaftD}" stroke="${P.red}" stroke-width="3.2" stroke-linecap="round"/>
      <path d="${arrI.headD}" stroke="${P.red}" stroke-width="2.4" fill="none"/>
      <text x="${(iX + 6).toFixed(1)}" y="${(iY + 4).toFixed(1)}" class="at-mono" fill="${P.red}">Aî(${fmtNum(mA)},${fmtNum(mB)})</text>
    </g>
    <g data-part="basisJ">
      <path d="${arrJ.shaftD}" stroke="${P.blue}" stroke-width="3.2" stroke-linecap="round"/>
      <path d="${arrJ.headD}" stroke="${P.blue}" stroke-width="2.4" fill="none"/>
      <text x="${(jX - 10).toFixed(1)}" y="${(jY - 8).toFixed(1)}" text-anchor="middle" class="at-mono" fill="${P.blue}">Aĵ(${fmtNum(mB)},${fmtNum(mD)})</text>
    </g>
    <g transform="translate(306, 48)">
      <rect x="0" y="0" width="230" height="170" rx="8" fill="${P.card}" stroke="${P.ink}" stroke-width="1.3"/>
      <text x="14" y="28" class="at-label" fill="${P.ink}">2×2 Matrix Stretch</text>
      <text x="14" y="58" class="at-mono" fill="${P.amber}">Area factor = ${fmtNum(det)}</text>
      <text x="14" y="86" class="at-mono" fill="${P.green}">Eigen-stretches: λ₁ = ${fmtNum(l1)}</text>
      <text x="14" y="110" class="at-mono" fill="${P.green}">                  λ₂ = ${fmtNum(l2)}</text>
      <text x="14" y="142" class="at-note">λ₁ × λ₂ = ${fmtNum(l1 * l2)} = det(A)</text>
    </g>
  `;

  return draftSvg({
    id: 'ch20-matrices',
    vb: [0, 0, SVG_W, SVG_H],
    title: 'Matrix transformation of the unit square and eigenvalue stretches',
    mode: 'geometric-construction',
    defs: themeStyleDefs(P),
    body,
  });
}

export function renderAtelierSvg(chNum, st = {}, params = {}, evalData = {}, opts = {}) {
  const P = paletteFor(Boolean(opts.isDark));
  const quirk = opts.quirk || 'slightly-quirky';
  switch (chNum) {
    case 0:
      return svgCh00(params, P);
    case 1:
      return st.mode === 'classic-turns' ? svgCh01Classic(params, P) : svgCh01(st, evalData, P);
    case 2:
      return st.mode === 'double-line' ? svgCh02(st, evalData, P) : svgCh02Recurring(params, P);
    case 3:
      return svgCh03(st, evalData, params, P, quirk);
    case 4:
      return svgCh04(st, evalData, P);
    case 5:
      return svgCh05(st, evalData, P, quirk);
    case 6:
      return svgCh06(params, P);
    case 7:
      return svgCh07(st, evalData, P, quirk);
    case 8:
      return svgCh08(params, P);
    case 9:
      return svgCh09(params, P);
    case 10:
      return svgCh10(params, P);
    case 11:
      return svgCh11(params, P);
    case 12:
      return svgCh12(params, P);
    case 13:
      return svgCh13(st, evalData, params, P);
    case 14:
      return svgCh14(st, evalData, params, P);
    case 15:
      return svgCh15(params, P);
    case 16:
      return svgCh16(params, P);
    case 17:
    case 18:
      return svgCalc(chNum, st, evalData, P);
    case 19:
      return svgCh19(params, P);
    case 20:
      return svgCh20(params, P);
    default:
      return null;
  }
}

export function renderReactiveProse(chNum, st = {}, params = {}, evalData = {}) {
  switch (chNum) {
    case 0: {
      const s = evalCh00FromParams(params);
      return `<p>${byrne.poly('setA', { shape: 'circle', color: 'red', label: 'Circle A' })} ${term('setA', 'Cricket', { color: 'red', isolate: true })} (${scrub('a', { value: s.A, min: 8, max: 22, step: 1, color: 'red', label: 'In A' })}) and ${byrne.poly('setB', { shape: 'circle', color: 'blue', label: 'Circle B' })} ${term('setB', 'Football', { color: 'blue', isolate: true })} (${scrub('b', { value: s.B, min: 6, max: 20, step: 1, color: 'blue', label: 'In B' })}) share ${term('inter', 'overlap', { color: 'ochre', isolate: true })} ${val('ch0_inter', { initial: String(s.inter), color: 'ochre' })} so the union holds ${val('ch0_union', { initial: String(s.union), color: 'green' })} students.</p>` +
        aside('Every person counted once', 'Counting circle A and circle B counts the amber lens twice — subtracting that middle overlap restores exact headcount.');
    }
    case 1:
      if (st.mode === 'classic-turns') {
        const A = clamp(Math.round(Number(params.a ?? 24)), 6, 48);
        const B = clamp(Math.round(Number(params.b ?? 36)), 6, 60);
        const turns = clamp(Math.round(Number(params.c ?? 2)), 0, 2);
        return `<p>Facing flips ${term('span', `${turns} half-turn${turns === 1 ? '' : 's'}`, { color: 'amber', isolate: true })}, while ${term('ptA', `HCF(${A}, ${B})`, { color: 'blue', isolate: true })} × ${term('ptB', `LCM(${A}, ${B})`, { color: 'ochre', isolate: true })} always equals ${A} × ${B}.</p>` +
          aside('Two half-turns face forward again', 'Multiplying two negatives turns 180° twice back to +, and shared factors belong in HCF while combined factors build LCM.');
      }
      return `<p>From ${term('ptA', 'start A', { color: 'blue', isolate: true })} = ${val('ch1_a', { initial: fmtNum(st.a) })} to ${term('ptB', 'finish B', { color: 'red', isolate: true })} = ${val('ch1_b', { initial: fmtNum(st.b) })}, the ${byrne.seg('span', { color: 'red', label: 'directed arrow' })} step is ${val('ch1_dir', { initial: fmtNum(evalData.directed), color: 'red' })} while spacing stays ${val('ch1_dist', { initial: fmtNum(evalData.distance), color: 'ochre' })}.</p>` +
        aside('Zero stays silent inside a step', 'Adding the same shift to both A and B leaves B − A untouched — only the gap between them matters.');
    case 2:
      if (st.mode === 'recurring') {
        return `<p>${term('topRail', '100 lots', { color: 'red', isolate: true })} minus ${term('botRail', '1 lot', { color: 'blue', isolate: true })} leaves ${term('unit', '99 lots', { color: 'green', isolate: true })} so the endless decimal tail cancels, then ${term('probe', 'fraction pieces', { color: 'ochre', isolate: true })} multiply by the flipped fraction.</p>` +
          aside('Why recurring tails vanish on subtraction', 'Multiplying by 100 shifts the repeating block left two places so every digit after the decimal point lines up and cancels.');
      }
      return `<p>${byrne.seg('topRail', { color: 'red', label: 'top rail' })} moves together in step with ${byrne.seg('botRail', { color: 'blue', label: 'bottom rail' })}: one step below equals ${term('unit', 'unit rate', { color: 'green', isolate: true })} ${val('ch2_rate', { initial: fmtNum(evalData.unitRatio), color: 'green' })} and ${val('ch2_probe', { initial: fmtNum(evalData.topAtProbe), color: 'ochre' })} above ${val('ch2_bot', { initial: fmtNum(st.probeScale) })}.</p>` +
        aside('Sliding together keeps alignment', 'Unlike adding a flat constant, multiplying top and bottom rails by the same factor preserves every plumb vertical alignment.');
    case 3:
      if (st.mode === 'compound-growth') {
        return `<p>${term('leftHand', 'Equal-part bars', { color: 'blue', isolate: true })} share the pot proportionally while ${term('rightHand', 'compound interest', { color: 'red', isolate: true })} multiplies by (1 + r) each year for a faster bend over ${term('ratioLock', '20 years', { color: 'green', isolate: true })}.</p>` +
          aside('Why percentages don’t undo evenly', 'Adding 20% then taking away 20% leaves 1.2 × 0.8 = 0.96, because the second percentage acts on a bigger base.');
      }
      return st.mode === 'compare-blind'
        ? `<p>Compare ${term('leftHand', 'Target ratio', { color: 'red', isolate: true })} with ${term('rightHand', 'Test mix', { color: 'blue', isolate: true })} — same multiplicative scale keeps flavor constant.</p>` +
          aside('Watch out for +2/+2', 'Adding the same amount to numerator and denominator changes the steepness of a ratio unless it is already 1:1.')
        : `<p>${term('leftHand', 'Left vessel', { color: 'red', isolate: true })} (${val('ch3_l', { initial: fmtNum(st.left) })}) and ${term('rightHand', 'Right vessel', { color: 'blue', isolate: true })} (${val('ch3_r', { initial: fmtNum(st.right) })}) lock at ${term('ratioLock', 'ratio', { color: 'green', isolate: true })} ${val('ch3_ratio', { initial: fmtNum(evalData.currentRatio), color: 'green' })}.</p>` +
          aside('Proportion is a chord', 'Doubling or tripling both vessels keeps the bridge at the exact same slope.');
    case 4:
      return `<p>${byrne.poly('tileX2', { shape: 'sq', color: 'red', label: 'x squared tile' })} ${term('tileX2', 'square', { color: 'red', isolate: true })} + ${byrne.poly('tileLin', { shape: 'rect', color: 'blue', label: 'linear strips' })} ${term('tileLin', 'strips', { color: 'blue', isolate: true })} + ${byrne.poly('tileConst', { shape: 'sq', color: 'ochre', label: 'constant corner' })} ${term('tileConst', 'corner', { color: 'ochre', isolate: true })} = ${val('ch4_expr', { initial: signedPolyLocal(evalData.linearSum, evalData.pq), color: 'green' })}.</p>` +
        aside('Why (x + p)² is never x² + p²', 'Every binomial product fills all four tiles of a rectangle — the two blue strips never vanish unless p = −q.');
    case 5:
      return `<p>Left pan ${term('leftPan', val('ch5_left', { initial: panExprLocal(st.leftX, st.leftOnes), color: 'red' }), { color: 'red', isolate: true })} opposes right pan ${term('rightPan', val('ch5_right', { initial: panExprLocal(st.rightX, st.rightOnes), color: 'blue' }), { color: 'blue', isolate: true })} across the ${byrne.poly('fulcrum', { shape: 'tri', color: 'ochre', label: 'balance pivot' })}: ${val('ch5_status', { initial: evalData.isolated ? `x = ${evalData.solvedValue}` : (evalData.balanced ? 'Balanced' : 'Tilted'), color: 'green' })}.</p>` +
        aside('Same move on both pans', 'Adding or subtracting the same weight from both sides preserves equality so truth never tips off the beam.');
    case 6:
      return `<p>${byrne.poly('stairRed', { shape: 'rect', color: 'red', label: 'red stairs' })} Start at ${scrub('b', { value: params.b ?? 1, min: 1, max: 4, step: 1, color: 'blue', label: 'first term' })} and add ${scrub('c', { value: params.c ?? 1, min: 1, max: 3, step: 1, color: 'red', label: 'common difference' })} across ${scrub('a', { value: params.a ?? 5, min: 3, max: 8, step: 1, color: 'ochre', label: 'terms' })} terms: pairing with ${byrne.poly('stairBlue', { shape: 'rect', color: 'blue', label: 'blue stairs' })} keeps every column equal.</p>` +
        aside('Why flipping the staircase always gives the same sum', 'Turn a number staircase upside down on top of itself and every vertical pair adds to the exact same height!');
    case 7:
      return st.mode === 'function-machine'
        ? `<p>Input ${val('ch7_in', { initial: fmtNum(st.testInput), color: 'blue' })} enters ${term('step1', 'block 1', { color: 'ochre', isolate: true })} then ${term('step2', 'block 2', { color: 'red', isolate: true })} to exit as ${term('output', 'output', { color: 'green', isolate: true })} = ${val('ch7_out', { initial: fmtNum(evalData.outVal), color: 'green' })}.</p>` +
          aside('Order matters!', 'Swapping + 2 followed by × 3 for × 3 followed by + 2 usually yields two completely different functions.')
        : `<p>${byrne.seg('line', { color: 'blue', label: 'line' })} keeps ${term('slopeTri', 'rise/run slope', { color: 'red', isolate: true })} = ${val('ch7_m', { initial: evalData.vertical ? '∞' : fmtNum(evalData.m), color: 'red' })} at every step while ${term('probe', 'the probe', { color: 'ochre', isolate: true })} tests collinearity.</p>` +
          aside('Steepness belongs to the line, not the triangle size', 'Scale the rise/run triangle bigger or smaller anywhere on the line — the ratio Δy/Δx refuses to budge.');
    case 8:
      return `<p>Tilt corners ${byrne.angle('angA', { color: 'red', label: 'angle A' })} (${scrub('a', { value: params.a ?? 50, min: 30, max: 65, step: 5, unit: '°', color: 'red', label: 'Angle A' })}) and ${byrne.angle('angB', { color: 'blue', label: 'angle B' })} (${scrub('b', { value: params.b ?? 60, min: 30, max: 65, step: 5, unit: '°', color: 'blue', label: 'Angle B' })}) in an ${scrub('c', { value: params.c ?? 6, min: 3, max: 8, step: 1, color: 'ochre', label: 'polygon sides' })}-gon.</p>` +
        aside('Exterior turns always close to 360°', 'Walk once round any closed polygon and your total clockwise turning angle is always one full turn — 360°.');
    case 9:
      return `<p>Strike ${term('arcs', 'compass arcs', { color: 'blue', isolate: true })} with radius ${scrub('b', { value: params.b ?? 4, min: 2, max: 5, step: 0.5, unit: ' cm', color: 'blue', label: 'compass opening' })} along base ${scrub('a', { value: params.a ?? 6, min: 4, max: 8, step: 1, unit: ' cm', color: 'red', label: 'AB' })} to build the ${term('bisector', 'perpendicular bisector', { color: 'red', isolate: true })} at height ${scrub('c', { value: params.c ?? 2, min: 0, max: 4, step: 1, unit: ' cm', color: 'green', label: 'height' })}.</p>` +
        aside('Equal distances force a right angle', 'Two equal circles force the crossing points to stay equidistant from both centres — guaranteeing 90°.');
    case 10:
      return `<p>Cut a disc of radius ${scrub('a', { value: params.a ?? 4, min: 2, max: 6, step: 1, unit: ' cm', color: 'red', label: 'radius' })} into ${scrub('b', { value: params.b ?? 12, min: 4, max: 24, step: 2, color: 'blue', label: 'slices' })} wedges for the ${term('strip', 'πr × r strip', { color: 'blue', isolate: true })} and highlight a ${byrne.angle('sector', { color: 'green', label: 'sector' })} of ${scrub('c', { value: params.c ?? 90, min: 0, max: 360, step: 30, unit: '°', color: 'green', label: 'sector angle' })}.</p>` +
        aside('More slices straighten the wave into a rectangle', 'As wedges get thinner, the alternating zig-zag approaches a rectangle of width πr and height r.');
    case 11:
      return `<p>Enlarge ${term('objTri', 'the blue triangle', { color: 'blue', isolate: true })} into ${term('imgTri', 'the red image', { color: 'red', isolate: true })} by scale factor ${scrub('a', { value: params.a ?? 2, min: 0.5, max: 3, step: 0.5, color: 'red', label: 'scale factor' })} from centre (${scrub('b', { value: params.b ?? 0, min: 0, max: 3, step: 1, color: 'blue', label: 'cx' })}, ${scrub('c', { value: params.c ?? 0, min: 0, max: 2, step: 1, color: 'green', label: 'cy' })}) — area grows as k² while angles stay fixed.</p>` +
        aside('Angles ignore scale factors', 'Doubling every edge length quadruples area and octuples volume without warping a single corner angle.');
    case 12:
      return `<p>At angle ${byrne.angle('theta', { color: 'red', label: 'theta' })} ${scrub('a', { value: params.a ?? 30, min: 0, max: 90, step: 5, unit: '°', color: 'red', label: 'theta' })} and circle radius ${scrub('b', { value: params.b ?? 2, min: 2, max: 4, step: 1, color: 'blue', label: 'radius' })}, cos²θ + sin²θ always pins the point onto the unit circle.</p>` +
        aside('Opposite ÷ Hypotenuse is a shadow ratio', 'Scaling the right triangle scales every leg together so sin θ and cos θ depend purely on angle θ.');
    case 13:
      return `<p>${term('samples', `${evalData.count ?? 0} sample means`, { color: 'red', isolate: true })} (n = ${val('ch13_n', { initial: String(st.sampleN) })}) cluster inside ${term('pop', 'population', { color: 'blue', isolate: true })} σ with theoretical SE = ${val('ch13_se', { initial: fmtNum(evalData.theoreticalSE), color: 'amber' })}.</p>` +
        aside('Quadruple n to halve the jitter', 'Average luck scales by 1/√n: 4× as many measurements shrink standard error by half.');
    case 14: {
      if (st.mode === 'histogram') {
        return `<p>Wide bars spread their count across width so ${term('residuals', 'bar area equals frequency', { color: 'red', isolate: true })}, while ${term('fulcrum', 'the middle half IQR', { color: 'green', isolate: true })} ignores extremes.</p>` +
          aside('Never confuse bar height with bar count', 'Doubling bar width halves its height for the same count, keeping frequency density fair across unequal classes.');
      }
      if (st.mode === 'best-fit') {
        return `<p>${byrne.seg('fitLine', { color: 'red', label: 'fit line' })} minimizes the total area of the ${byrne.poly('residuals', { shape: 'sq', color: 'ochre', label: 'residual squares' })}: total squared error = ${val('ch14_ssr', { initial: fmtNum(evalData.mySSR), color: 'amber' })} (smallest possible = ${val('ch14_ols', { initial: fmtNum(evalData.bestSSR), color: 'green' })}).</p>` +
          aside('Why square residuals instead of taking absolute values?', 'Squaring penalizes distant misses strongly and leaves one unique balance slope passing through (x̄, ȳ).');
      }
      if (st.mode === 'level-out') {
        return `<p>${term('dots', 'All data bars', { color: 'blue', isolate: true })} share their total evenly to level out at the ${term('meanMark', 'mean height', { color: 'ochre', isolate: true })} ${val('ch14_mean', { initial: fmtNum(evalData.meanVal), color: 'red' })}.</p>` +
          aside('Levelling heights finds the mean', 'Taking blocks off taller bars to fill shorter ones stops at the exact arithmetic mean.');
      }
      const hiddenCenter = !st.revealedCenter;
      return `<p>Place the ${byrne.poly('fulcrum', { shape: 'tri', color: 'ochre', label: 'fulcrum' })} at ${val('ch14_fulc', { initial: fmtNum(st.fulcrumX), color: 'amber' })} — ${term('meanMark', 'mean', { color: 'red', isolate: true })} ${val('ch14_mean', { initial: hiddenCenter ? 'hidden until Reveal' : fmtNum(evalData.meanVal), color: 'red' })} and ${term('medianMark', 'median', { color: 'green', isolate: true })} ${val('ch14_med', { initial: hiddenCenter ? 'hidden until Reveal' : fmtNum(evalData.medianVal), color: 'green' })}.</p>` +
        aside('Torque vs middle rank', 'Dragging one rightmost dot pulls the mean linearly with lever arm distance, leaving the middle-ranked median anchored.');
    }
    case 15: {
      const nRows = clamp(Math.round(Number(params.a ?? 6)), 4, 10);
      const bClamped = Math.min(Number(params.b ?? 3), nRows);
      return `<p>Across ${scrub('a', { value: nRows, min: 4, max: 10, step: 1, color: 'blue', label: 'rows' })} peg rows with right-chance ${scrub('c', { value: params.c ?? 50, min: 30, max: 70, step: 10, unit: '%', color: 'amber', label: 'right prob' })}, peak ${term('peakCol', 'bin k', { color: 'red', isolate: true })} (${scrub('b', { value: bClamped, min: 0, max: nRows, step: 1, color: 'red', label: 'bounces' })}) counts ${term('pegCols', 'lattice paths C(n, k)', { color: 'blue', isolate: true })}.</p>` +
        aside('Independent coin flips pile into a bell curve', 'Order does not matter to the bin landing spot — multiple paths converge onto middle columns.');
    }
    case 16:
      return `<p>With prior base rate ${scrub('a', { value: params.a ?? 2, min: 1, max: 20, step: 1, unit: '%', color: 'blue', label: 'base rate' })}, sensitivity ${scrub('b', { value: params.b ?? 95, min: 80, max: 99, step: 1, unit: '%', color: 'green', label: 'sensitivity' })}, and false alarms ${scrub('c', { value: params.c ?? 5, min: 1, max: 20, step: 1, unit: '%', color: 'red', label: 'false positive' })}, compare ${term('truePos', 'true alarms', { color: 'red', isolate: true })} against ${term('falsePos', 'false alarms', { color: 'ochre', isolate: true })} out of 1,000.</p>` +
        aside('Frequency trees stop the base-rate fallacy', 'A 5% false-positive rate in 980 healthy people produces far more alarms than a rare disease in 20 people.');
    case 17:
    case 18: {
      const fNow = evalData.val || calcPoint(st.curveKind, st.refX);
      return `<p>At ${term('refLine', `x = ${fmtNum(st.refX)}`, { color: 'green', isolate: true })}, ${term('curveF', 'height f', { color: 'blue', isolate: true })} = ${val('calc_f', { initial: fmtNum(fNow.f), color: 'blue' })}, ${term('curveFp', 'slope f′', { color: 'red', isolate: true })} = ${val('calc_fp', { initial: fNow.definedDeriv ? fmtNum(fNow.fp) : 'undef', color: 'red' })}, and ${term('curveInt', 'signed area ∫f', { color: 'amber', isolate: true })} = ${val('calc_F', { initial: fmtNum(fNow.F), color: 'amber' })}.</p>` +
        aside('Derivative undoes accumulation', 'Zoom into any smooth bend and f(x) flattens into its straight red tangent — yet corners break slope while area flows seamlessly.');
    }
    case 19:
      return `<p>${term('vecA', 'Vector a', { color: 'red', isolate: true })} steps (${scrub('a', { value: params.a ?? 3.5, min: 1, max: 5, step: 0.5, color: 'red', label: 'step a' })}, 1.2) and ${term('vecB', 'b', { color: 'blue', isolate: true })} reaches length ${scrub('b', { value: params.b ?? 2.0, min: 1, max: 4, step: 0.5, color: 'blue', label: 'len b' })} at ${scrub('c', { value: params.c ?? 60, min: 0, max: 120, step: 15, unit: '°', color: 'green', label: 'angle' })} for ${term('vecSum', 'shortcut a + b', { color: 'green', isolate: true })}.</p>` +
        aside('Perpendicular vectors cast zero shadow', 'Only the component pointing along a contributes to a·b = |a||b| cos θ.');
    case 20:
      return `<p>Symmetric matrix columns ${term('basisI', `(${scrub('a', { value: params.a ?? 2.0, min: 0.5, max: 2.5, step: 0.25, color: 'red', label: 'a' })}, ${scrub('b', { value: params.b ?? 1.0, min: -1.5, max: 1.5, step: 0.25, color: 'amber', label: 'b' })})`, { color: 'red', isolate: true })} and ${term('basisJ', `(${val('ch20_b', { initial: fmtNum(params.b ?? 1), color: 'amber' })}, ${scrub('c', { value: params.c ?? 2.0, min: 0.5, max: 2.5, step: 0.25, color: 'blue', label: 'd' })})`, { color: 'blue', isolate: true })} scale ${term('detArea', 'unit area', { color: 'ochre', isolate: true })} by ad − b².</p>` +
        aside('Eigenvectors stay on their own ray', 'While almost every grid line twists, eigenvector directions only stretch or flip without leaving their span.');
    default:
      return '';
  }
}

function buildProseStateMap(chNum, st, params, evalData) {
  switch (chNum) {
    case 0: {
      const s = evalCh00FromParams(params);
      return { ch0_inter: String(s.inter), ch0_union: String(s.union) };
    }
    case 1:
      return { ch1_a: fmtNum(st.a), ch1_b: fmtNum(st.b), ch1_dir: fmtNum(evalData.directed), ch1_dist: fmtNum(evalData.distance) };
    case 2:
      return { ch2_rate: fmtNum(evalData.unitRatio), ch2_probe: fmtNum(evalData.topAtProbe), ch2_bot: fmtNum(st.probeScale) };
    case 3:
      return { ch3_l: fmtNum(st.left), ch3_r: fmtNum(st.right), ch3_ratio: fmtNum(evalData.currentRatio) };
    case 4:
      return { ch4_expr: signedPolyLocal(evalData.linearSum, evalData.pq) };
    case 5:
      return { ch5_left: panExprLocal(st.leftX, st.leftOnes), ch5_right: panExprLocal(st.rightX, st.rightOnes), ch5_status: evalData.isolated ? `x = ${evalData.solvedValue}` : (evalData.balanced ? 'Balanced' : 'Tilted') };
    case 7: {
      const mVal = evalData.midVal;
      const oVal = evalData.outVal;
      return {
        ch7_in: fmtNum(st.testInput),
        ch7_out: st.mysteryMode && !st.mysteryRevealed ? fmtNum(oVal) : fmtNum(oVal ?? mVal),
        ch7_m: evalData.vertical ? '∞' : fmtNum(evalData.m),
      };
    }
    case 13:
      return { ch13_n: String(st.sampleN), ch13_se: fmtNum(evalData.theoreticalSE) };
    case 14: {
      const hideBalanceCenters = st.mode === 'mean-balance' && !st.revealedCenter;
      return {
        ch14_ssr: fmtNum(evalData.mySSR),
        ch14_ols: fmtNum(evalData.bestSSR),
        ch14_fulc: fmtNum(st.fulcrumX),
        ch14_mean: hideBalanceCenters ? 'hidden until Reveal' : fmtNum(evalData.meanVal),
        ch14_med: hideBalanceCenters ? 'hidden until Reveal' : fmtNum(evalData.medianVal),
      };
    }
    case 17:
    case 18: {
      const fNow = evalData.val || calcPoint(st.curveKind, st.refX);
      return { calc_f: fmtNum(fNow.f), calc_fp: fNow.definedDeriv ? fmtNum(fNow.fp) : 'undef', calc_F: fmtNum(fNow.F) };
    }
    case 20:
      return { ch20_b: fmtNum(params.b ?? 1) };
    default:
      return {};
  }
}

// ---------- Browser Auto-Mount ----------

function toSvgCoords(svg, clientX, clientY) {
  if (!svg || typeof svg.getScreenCTM !== 'function') return [0, 0];
  const ctm = svg.getScreenCTM();
  if (!ctm) return [0, 0];
  const inv = ctm.inverse();
  return [
    inv.a * clientX + inv.c * clientY + inv.e,
    inv.b * clientX + inv.d * clientY + inv.f,
  ];
}

function applyHandleDrag(stageApi, ctx, handleId, sx, sy) {
  const { chNum, st, params } = ctx;
  if (chNum === 0 && handleId === 'inter') {
    const { least, most } = evalCh00FromParams(params);
    const ratio = clamp((61 - (sx - 280)) / 36, 0, 1);
    const nextInter = clamp(Math.round(least + ratio * (most - least)), least, most);
    if (nextInter !== Math.round(params.c)) {
      stageApi.setSliderParam('c', nextInter);
    }
    return;
  }
  if (chNum === 1) {
    const valNum = clamp(Math.round(((sx - 48) / (SVG_W - 96)) * 20 - 10), -10, 10);
    if (handleId === 'a' && valNum !== st.a) { st.a = valNum; stageApi.SoundEngine?.playDetent?.(1); stageApi.recordInteraction(); stageApi.redraw(); }
    if (handleId === 'b' && valNum !== st.b) { st.b = valNum; stageApi.SoundEngine?.playDetent?.(1); stageApi.recordInteraction(); stageApi.redraw(); }
    return;
  }
  if (chNum === 2 && handleId === 'probe') {
    const valScale = clamp(roundTo(((sx - 56) / (SVG_W - 100)) * 6, 1), 0.5, 6);
    st.probeScale = valScale;
    stageApi.recordInteraction();
    stageApi.redraw();
    return;
  }
  if (chNum === 3 && (handleId === 'left' || handleId === 'right')) {
    const val = clamp(roundTo((232 - sy) / 18, 1), 0.5, 8);
    if (st.ratioLocked) {
      const k = st.lockedRatio || (st.left / Math.max(0.5, st.right));
      if (handleId === 'left') { st.left = val; st.right = clamp(roundTo(val / k, 1), 0.5, 8); }
      else { st.right = val; st.left = clamp(roundTo(val * k, 1), 0.5, 8); }
      if (st.left > 3.1) st.movedWhileInTune = true;
    } else {
      if (handleId === 'left') st.left = val;
      else st.right = val;
    }
    stageApi.recordInteraction();
    stageApi.redraw();
    return;
  }
  if (chNum === 4 && handleId === 'area-corner') {
    const isScale = st.mode === 'area-scale';
    const wX = isScale ? clamp(Math.round(st.x) * 16, 58, 108) : 96;
    const ox = 68, oy = 68;
    const pMag = clamp(Math.round((sx - (ox + wX)) / 16), isScale ? 1 : -4, 4);
    const qMag = clamp(Math.round((sy - (oy + wX)) / 16), isScale ? 1 : -4, 4);
    st.p = isScale ? Math.max(1, pMag) : pMag;
    st.q = isScale ? Math.max(1, qMag) : qMag;
    stageApi.syncSliderValue?.('b', st.p);
    stageApi.syncSliderValue?.('c', st.q);
    stageApi.SoundEngine?.playDetent?.(1);
    stageApi.recordInteraction();
    stageApi.redraw();
    return;
  }
  if (chNum === 7) {
    if (handleId === 'inputVal') {
      st.testInput = clamp(roundTo((sx - 88) / 14 + 4, 0), -6, 12);
      stageApi.recordInteraction();
      stageApi.redraw();
      return;
    }
    const gx = clamp(roundTo((sx - 250) / 26, 1), -5, 6);
    const gy = clamp(roundTo((165 - sy) / 26, 1), -4, 5);
    if (handleId === 'p1') { st.p1 = { x: gx, y: gy }; stageApi.recordInteraction(); stageApi.redraw(); }
    if (handleId === 'p2') { st.p2 = { x: gx, y: gy }; stageApi.recordInteraction(); stageApi.redraw(); }
    if (handleId === 'probe') { st.probe = { x: gx, y: gy }; stageApi.recordInteraction(); stageApi.redraw(); }
    return;
  }
  if (chNum === 13 && handleId === 'popSigma') {
    const sig = clamp(Math.round(((sx - (46 + ((50 - 10) / 80) * (SVG_W - 92))) / ((SVG_W - 92) / 80))), 4, 24);
    st.popSigma = sig;
    stageApi.recordInteraction();
    stageApi.redraw();
    return;
  }
  if (chNum === 14) {
    if (st.mode === 'best-fit') {
      const newY = clamp(roundTo((250 - sy) / 25, 2), 0, 9);
      const y1 = handleId === 'h1' ? newY : st.mySlope * 1 + st.myIntercept;
      const y2 = handleId === 'h2' ? newY : st.mySlope * 6 + st.myIntercept;
      st.mySlope = (y2 - y1) / 5;
      st.myIntercept = y1 - st.mySlope;
      stageApi.recordInteraction();
      stageApi.redraw();
      return;
    }
    const valX = clamp(roundTo(((sx - 44) / (SVG_W - 88)) * 18 + 1, 1), 1, 19);
    if (handleId === 'fulcrum') { st.fulcrumX = valX; stageApi.recordInteraction(); stageApi.redraw(); return; }
    if (handleId === 'predict') { st.predictVal = clamp(roundTo(valX, 1), 0, 20); stageApi.recordInteraction(); stageApi.redraw(); return; }
    if (handleId.startsWith('dot-')) {
      const idx = parseInt(handleId.slice(4), 10);
      if (Number.isInteger(idx) && idx >= 0 && idx < st.dots.length) {
        st.dots[idx] = st.mode === 'level-out'
          ? clamp(Math.round((232 - sy) / 8.5), 1, 20)
          : Math.round(valX);
        stageApi.recordInteraction();
        stageApi.redraw();
      }
    }
    return;
  }
  if (chNum === 17 || chNum === 18) {
    if (handleId === 'refX') {
      st.refX = clamp(roundTo(((sx - 64) / (SVG_W - 92)) * 3.0, 2), 0.1, 2.95);
      st.interacted = true;
      st.minRefX = Math.min(st.minRefX ?? st.refX, st.refX);
      st.maxRefX = Math.max(st.maxRefX ?? st.refX, st.refX);
      stageApi.recordInteraction();
      stageApi.redraw();
    } else if (handleId.startsWith('pred-')) {
      const idx = parseInt(handleId.slice(5), 10);
      if (Number.isInteger(idx) && st.predictNodes?.[idx]) {
        st.predictNodes[idx].y = clamp(roundTo((150 - sy) / 10.5, 1), -2.5, 2.5);
        stageApi.recordInteraction();
        stageApi.redraw();
      }
    }
  }
}

function wireUnwiredModeBars(selector) {
  document.querySelectorAll(selector).forEach(bar => {
    if (bar.dataset.kymWired === '1') return;
    bar.dataset.kymWired = '1';
    wireModeBar(bar);
  });
}

export function mountAtelierStage() {
  if (typeof window === 'undefined' || typeof document === 'undefined') return null;
  if (window.__kymAtelierMounted) return window.__kymAtelierMounted;

  const host = document.getElementById('atelier-svg-host');
  const canvas = document.getElementById('sim-canvas');
  const proseEl = document.getElementById('reactive-prose');
  const stageApi = window.__kymPhetStage;
  if (!host || !stageApi) return null;

  ensureInkChromeDefs();
  wireUnwiredModeBars('.quirk-bar, .medium-bar, #lab-tools .lab-mode-bar');

  let toolsObs = null;
  const toolsEl = document.getElementById('lab-tools');
  if (toolsEl && typeof MutationObserver !== 'undefined') {
    toolsObs = new MutationObserver(() => {
      wireUnwiredModeBars('#lab-tools .lab-mode-bar');
    });
    toolsObs.observe(toolsEl, { childList: true });
  }

  let activeProseKey = '';
  let proseCtl = null;
  let activeHandleId = null;

  function highlightSvgParts(keys) {
    const set = new Set(Array.isArray(keys) ? keys : keys ? [keys] : []);
    host.querySelectorAll('[data-part]').forEach(el => {
      const parts = (el.dataset.part || '').split(',').map(s => s.trim()).filter(Boolean);
      const lit = set.size > 0 && parts.some(k => set.has(k));
      el.classList.toggle('at-lit', lit);
    });
  }

  host.addEventListener('pointerdown', e => {
    const target = e.target.closest?.('[data-handle]');
    if (!target || !host.contains(target)) return;
    const svg = host.querySelector('svg');
    if (!svg) return;
    activeHandleId = target.getAttribute('data-handle');
    host.setPointerCapture?.(e.pointerId);
    const [sx, sy] = toSvgCoords(svg, e.clientX, e.clientY);
    applyHandleDrag(stageApi, stageApi.getContext(), activeHandleId, sx, sy);
    e.preventDefault();
  });

  host.addEventListener('pointermove', e => {
    if (!activeHandleId) return;
    const svg = host.querySelector('svg');
    if (!svg) return;
    const [sx, sy] = toSvgCoords(svg, e.clientX, e.clientY);
    applyHandleDrag(stageApi, stageApi.getContext(), activeHandleId, sx, sy);
  });

  const endDrag = () => { activeHandleId = null; };
  host.addEventListener('pointerup', endDrag);
  host.addEventListener('pointercancel', endDrag);

  function renderFromContext(ctx) {
    const svgMarkup = renderAtelierSvg(ctx.chNum, ctx.st, ctx.params, ctx.evalData, {
      isDark: ctx.isDark,
      quirk: ctx.quirk,
      medium: ctx.medium,
      step: ctx.step,
    });

    if (svgMarkup) {
      host.innerHTML = svgMarkup;
      host.hidden = false;
      if (canvas) canvas.hidden = true;
    } else {
      host.innerHTML = '';
      host.hidden = true;
      if (canvas) canvas.hidden = false;
    }

    if (proseEl) {
      const nKey = ctx.chNum === 15 ? String(ctx.params?.a ?? 6) : '';
      const nextKey = `${ctx.chNum}:${ctx.st?.mode || 'default'}:${ctx.st?.puzzleIdx ?? 0}:${Boolean(ctx.st?.mysteryMode)}:${Boolean(ctx.st?.mysteryRevealed)}:${nKey}`;
      if (nextKey !== activeProseKey) {
        activeProseKey = nextKey;
        proseCtl?.destroy?.();
        proseEl.innerHTML = renderReactiveProse(ctx.chNum, ctx.st, ctx.params, ctx.evalData);
        proseCtl = bindProse(proseEl, {
          getStage: () => ({ hoverExtern: keys => highlightSvgParts(keys) }),
          getParams: () => stageApi.getContext().params,
          setParam: (key, v) => stageApi.setSliderParam(key, Number(v)),
          onSound: () => stageApi.SoundEngine?.playDetent?.(1),
        });
      }
      proseCtl?.sync(buildProseStateMap(ctx.chNum, ctx.st, ctx.params, ctx.evalData), ctx.params);
    }
  }

  window.__kymAtelierSvgOwner = true;
  const unsub = stageApi.onUpdate(renderFromContext);
  renderFromContext(stageApi.getContext());
  const api = {
    unmount() {
      unsub();
      toolsObs?.disconnect?.();
      proseCtl?.destroy?.();
      window.__kymAtelierSvgOwner = false;
      window.__kymAtelierMounted = null;
    },
  };
  window.__kymAtelierMounted = api;
  return api;
}

if (typeof window !== 'undefined' && typeof document !== 'undefined') {
  const boot = () => mountAtelierStage();
  if (window.__kymPhetStage) {
    boot();
  } else {
    window.addEventListener('kymPhetStageReady', boot, { once: true });
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', boot, { once: true });
    }
  }
}
