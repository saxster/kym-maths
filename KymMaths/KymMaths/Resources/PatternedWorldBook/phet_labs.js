(function (globalScope) {
  'use strict';

  // Pure seeded PRNG (Mulberry32) so sampling & data labs are deterministic in tests and browsers.
  function createRng(seed) {
    let a = (seed >>> 0) || 1;
    return {
      next() {
        a |= 0;
        a = (a + 0x6D2B79F5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
      },
      normal() {
        const u1 = Math.max(1e-7, this.next());
        const u2 = this.next();
        return Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
      }
    };
  }

  function gcd(x, y) {
    let a = Math.abs(Math.round(x));
    let b = Math.abs(Math.round(y));
    while (b !== 0) {
      const t = b;
      b = a % b;
      a = t;
    }
    return Math.max(1, a);
  }

  function clamp(v, lo, hi) {
    return Math.min(hi, Math.max(lo, v));
  }

  function roundTo(v, decimals = 2) {
    const f = Math.pow(10, decimals);
    return Math.round(v * f) / f;
  }

  function fmtNum(v) {
    const clean = Math.abs(v) < 1e-9 ? 0 : roundTo(v, 2);
    return String(clean).replace('-', '−');
  }

  function escapeHtml(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function formatSignedPoly(linearSum, constantTerm) {
    const parts = ['x²'];
    if (linearSum !== 0) {
      const absCoef = Math.abs(linearSum);
      const coefTxt = absCoef === 1 ? 'x' : `${absCoef}x`;
      parts.push(linearSum > 0 ? `+ ${coefTxt}` : `− ${coefTxt}`);
    }
    if (constantTerm !== 0) {
      parts.push(constantTerm > 0 ? `+ ${constantTerm}` : `− ${Math.abs(constantTerm)}`);
    }
    return parts.join(' ');
  }

  function stripHtml(html) {
    const prepared = String(html || '').replace(/<br\s*\/?>/gi, ' · ');
    if (typeof document !== 'undefined') {
      const tmp = document.createElement('div');
      tmp.innerHTML = prepared;
      return (tmp.textContent || tmp.innerText || '')
        .replace(/\s+/g, ' ')
        .replace(/(?:\s*·\s*)+/g, ' · ')
        .trim();
    }
    return prepared
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/gi, ' ')
      .replace(/&amp;/gi, '&')
      .replace(/&lt;/gi, '<')
      .replace(/&gt;/gi, '>')
      .replace(/\s+/g, ' ')
      .replace(/(?:\s*·\s*)+/g, ' · ')
      .trim();
  }

  // ---------- Procedural WebAudio Invariant Sonification (muted by default) ----------
  const SoundEngine = {
    enabled: false,
    ctx: null,
    lastKnockAt: 0,
    lastSoundAt: 0,

    toggle() {
      this.enabled = !this.enabled;
      if (this.enabled && !this.ctx && typeof window !== 'undefined') {
        const Ctor = window.AudioContext || window.webkitAudioContext;
        if (Ctor) {
          try { this.ctx = new Ctor(); } catch (_) {}
        }
      }
      if (this.enabled && this.ctx) {
        if (this.ctx.state === 'suspended') this.ctx.resume?.().catch?.(() => {});
        this.playBoop(2);
      } else if (!this.enabled && this.ctx) {
        this.ctx.suspend?.().catch?.(() => {});
      }
      return this.enabled;
    },

    _ready() {
      if (!this.enabled || !this.ctx || this.ctx.state === 'closed') return false;
      if (this.ctx.state === 'suspended') this.ctx.resume?.().catch?.(() => {});
      return true;
    },

    _tone({ freq = 261.63, slideTo = null, dur = 0.08, type = 'sine', gain = 0.036 } = {}) {
      if (!this._ready()) return;
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = type;
      osc.frequency.setValueAtTime(clamp(freq, 40, 2600), now);
      if (slideTo) osc.frequency.exponentialRampToValueAtTime(clamp(slideTo, 40, 2600), now + dur);
      g.gain.setValueAtTime(Math.max(0.0001, gain), now);
      g.gain.exponentialRampToValueAtTime(0.0005, now + dur);
      osc.connect(g);
      g.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + dur + 0.015);
    },

    playBoop(step = 0) {
      const f = 330 * Math.pow(2, clamp(step, 0, 12) / 12);
      this._tone({ freq: f * 0.92, slideTo: f * 1.12, dur: 0.075, type: 'triangle', gain: 0.04 });
    },

    playDetent(dir = 1) {
      this._tone({ freq: dir >= 0 ? 480 : 380, slideTo: dir >= 0 ? 600 : 280, dur: 0.032, type: 'sine', gain: 0.025 });
    },

    playLevelChime() {
      this._tone({ freq: 392, slideTo: 523.25, dur: 0.12, type: 'triangle', gain: 0.042 });
      this._tone({ freq: 587.33, dur: 0.14, type: 'sine', gain: 0.03 });
    },

    playZeroPairPop() {
      this._tone({ freq: 440, slideTo: 660, dur: 0.065, type: 'sine', gain: 0.038 });
    },

    playTiltKnock(imbalance = 1) {
      const nowMs = Date.now();
      if (nowMs - this.lastKnockAt < 90) return;
      this.lastKnockAt = nowMs;
      const strength = clamp(Math.abs(imbalance) / 10, 0.2, 1);
      this._tone({ freq: 185, slideTo: 115, dur: 0.06, type: 'triangle', gain: 0.055 * strength });
    },

    playDetunedBeat(error = 0, baseFreq = 261.63) {
      const nowMs = Date.now();
      if (nowMs - this.lastSoundAt < 75) return;
      this.lastSoundAt = nowMs;
      const err = clamp(Math.abs(error), 0, 1);
      if (err < 0.035) {
        this._tone({ freq: baseFreq, dur: 0.1, type: 'sine', gain: 0.034 });
        this._tone({ freq: baseFreq * 1.5, dur: 0.1, type: 'triangle', gain: 0.025 });
      } else {
        this._tone({ freq: baseFreq, dur: 0.075, type: 'sine', gain: 0.026 });
        this._tone({ freq: baseFreq * (1.5 + err * 0.25), dur: 0.075, type: 'triangle', gain: 0.02 });
      }
    },

    playCuspJump() {
      this._tone({ freq: 520, slideTo: 240, dur: 0.08, type: 'sawtooth', gain: 0.022 });
    },

    playCollapse() {
      this._tone({ freq: 150, slideTo: 82, dur: 0.11, type: 'triangle', gain: 0.045 });
    }
  };

  // ---------- Pure Mathematical Lab Models (Tested Directly in Node & Used by UI) ----------

  function createCh01State() {
    return { a: -3, b: 4, mode: 'distance', context: 'numberLine', goalDone: false };
  }

  function evalCh01(st) {
    const directed = st.b - st.a;
    const distance = Math.abs(directed);
    const spansZero = (st.a < 0 && st.b > 0) || (st.a > 0 && st.b < 0);
    const goalReached = Math.abs(distance - 7) < 1e-6 && directed < 0;
    return { directed, distance, spansZero, goalReached };
  }

  function createCh02State() {
    return { mode: 'double-line', topUnit: 3, bottomUnit: 4, probeScale: 1, goalDone: false };
  }

  function evalCh02(st) {
    const unitRatio = st.topUnit / Math.max(1, st.bottomUnit);
    const topAtProbe = roundTo(unitRatio * st.probeScale, 3);
    return { unitRatio, topAtProbe, goalReached: st.goalDone || Math.abs(st.probeScale - 5) < 1e-6 };
  }

  function createCh03State() {
    return {
      mode: 'ratio-tuner', // 'ratio-tuner' | 'compare-blind'
      left: 2,
      right: 3,
      targetLeft: 2,
      targetRight: 3,
      tickMode: 'numbered', // 'none' | 'plain' | 'numbered'
      ratioLocked: false,
      lockedRatio: 2 / 3,
      compareTargetLeft: 4,
      compareTargetRight: 6,
      compareUserLeft: 4,
      compareUserRight: 6,
      comparePrediction: null, // 'same' | 'different' | null
      compareRevealed: false,
      movedWhileInTune: false
    };
  }

  function evalCh03(st) {
    const targetRatio = st.targetLeft / Math.max(0.2, st.targetRight);
    const currentRatio = st.left / Math.max(0.2, st.right);
    const relError = Math.abs(currentRatio - targetRatio) / Math.max(0.2, targetRatio);
    const inProportion = st.left >= 0.5 && st.right >= 0.5 && relError <= 0.045;
    const actualSame = Math.abs(
      (st.compareTargetLeft / Math.max(0.1, st.compareTargetRight)) -
      (st.compareUserLeft / Math.max(0.1, st.compareUserRight))
    ) < 1e-6;
    const goalReached =
      st.mode === 'compare-blind'
        ? Boolean(st.compareRevealed && st.comparePrediction && ((st.comparePrediction === 'same') === actualSame))
        : (inProportion && st.left > 3.1 && Math.abs(st.left - st.targetLeft) > 0.6) || st.movedWhileInTune;
    return { targetRatio, currentRatio, relError, inProportion, actualSame, goalReached };
  }

  function createCh04State() {
    return {
      mode: 'area-scale', // 'area-scale' | 'area-generic' | 'area-factor'
      x: 4,
      p: 2,
      q: 3,
      factorPuzzleIdx: 0,
      guessP: 1,
      guessQ: 1
    };
  }

  const CH04_PUZZLES = [
    { targetP: 2, targetQ: 5, label: 'x² + 7x + 10' },
    { targetP: -4, targetQ: 3, label: 'x² − x − 12' },
    { targetP: -3, targetQ: 3, label: 'x² − 9' }
  ];

  function evalCh04(st) {
    const p = st.mode === 'area-scale' ? Math.max(1, Math.round(st.p)) : Math.round(st.p);
    const q = st.mode === 'area-scale' ? Math.max(1, Math.round(st.q)) : Math.round(st.q);
    const x = Math.max(1, Math.round(st.x));
    const x2 = x * x;
    const px = p * x;
    const qx = q * x;
    const pq = p * q;
    const linearSum = p + q;
    const total = x2 + px + qx + pq;
    const pz = CH04_PUZZLES[st.factorPuzzleIdx % CH04_PUZZLES.length];
    const gP = Math.round(st.guessP);
    const gQ = Math.round(st.guessQ);
    const factorSolved =
      (gP === pz.targetP && gQ === pz.targetQ) ||
      (gP === pz.targetQ && gQ === pz.targetP);
    const cancelsMiddle = linearSum === 0 && p !== 0;
    const goalReached = st.mode === 'area-factor' ? factorSolved : cancelsMiddle;
    return { x, p, q, x2, px, qx, pq, linearSum, total, puzzle: pz, factorSolved, cancelsMiddle, goalReached };
  }

  const CH05_PUZZLES = [
    { title: '3x + 4 = x + 10', left: { x: 3, ones: 4 }, right: { x: 1, ones: 10 }, hiddenX: 3 },
    { title: '2x + 3 = 11', left: { x: 2, ones: 3 }, right: { x: 0, ones: 11 }, hiddenX: 4 },
    { title: '4x − 2 = 2x + 6', left: { x: 4, ones: -2 }, right: { x: 2, ones: 6 }, hiddenX: 4 }
  ];

  function createCh05State(puzzleIdx = 0) {
    const puz = CH05_PUZZLES[puzzleIdx % CH05_PUZZLES.length];
    return {
      mode: 'balance-explorer',
      puzzleIdx: puzzleIdx % CH05_PUZZLES.length,
      leftX: puz.left.x,
      leftOnes: puz.left.ones,
      rightX: puz.right.x,
      rightOnes: puz.right.ones,
      hiddenX: puz.hiddenX,
      symLock: true,
      lastMoveLabel: 'Start with both pans balanced.',
      zeroPairsCleared: 0,
      history: []
    };
  }

  function applyCh05Op(st, side, kind, count) {
    // side: 'left' | 'right' | 'both'; kind: 'x' | 'ones' | 'mul' | 'div'
    st.history.push({
      leftX: st.leftX,
      leftOnes: st.leftOnes,
      rightX: st.rightX,
      rightOnes: st.rightOnes,
      symLock: st.symLock,
      lastMoveLabel: st.lastMoveLabel
    });
    if (st.history.length > 30) st.history.shift();

    if (kind === 'div') {
      const d = count;
      if (d !== 0 && st.leftX % d === 0 && st.leftOnes % d === 0 && st.rightX % d === 0 && st.rightOnes % d === 0) {
        if (st.symLock || side === 'both') {
          st.leftX /= d;
          st.leftOnes /= d;
          st.rightX /= d;
          st.rightOnes /= d;
          st.lastMoveLabel = `Divided both pans by ${d}`;
        } else if (side === 'left') {
          st.leftX /= d;
          st.leftOnes /= d;
          st.lastMoveLabel = `Divided left pan by ${d} (beam tilted!)`;
        } else {
          st.rightX /= d;
          st.rightOnes /= d;
          st.lastMoveLabel = `Divided right pan by ${d} (beam tilted!)`;
        }
        return true;
      }
      st.history.pop();
      st.lastMoveLabel = `Not every group divides cleanly by ${d} yet.`;
      return false;
    }

    if (kind === 'mul') {
      const factor = count;
      if (st.symLock || side === 'both') {
        st.leftX *= factor;
        st.leftOnes *= factor;
        st.rightX *= factor;
        st.rightOnes *= factor;
        st.lastMoveLabel = `Multiplied both pans by ${fmtNum(factor)}`;
      } else if (side === 'left') {
        st.leftX *= factor;
        st.leftOnes *= factor;
        st.lastMoveLabel = `Multiplied left pan by ${fmtNum(factor)}`;
      } else {
        st.rightX *= factor;
        st.rightOnes *= factor;
        st.lastMoveLabel = `Multiplied right pan by ${fmtNum(factor)}`;
      }
      return true;
    }

    const applySide = target => {
      if (kind === 'x') {
        const before = st[target + 'X'];
        const after = before + count;
        if ((before > 0 && count < 0) || (before < 0 && count > 0)) st.zeroPairsCleared += 1;
        st[target + 'X'] = after;
      } else {
        const before = st[target + 'Ones'];
        const after = before + count;
        if ((before > 0 && count < 0) || (before < 0 && count > 0)) st.zeroPairsCleared += 1;
        st[target + 'Ones'] = after;
      }
    };

    if (st.symLock || side === 'both') {
      applySide('left');
      applySide('right');
      const unitTxt = kind === 'x' ? 'x' : '1';
      st.lastMoveLabel = `${count > 0 ? 'Added' : 'Took away'} ${Math.abs(count)}${kind === 'x' ? 'x' : ''} on both pans`;
      if (unitTxt === '1' && count < 0) st.lastMoveLabel = `Subtracted ${Math.abs(count)} from both pans`;
    } else {
      applySide(side);
      st.lastMoveLabel = `${count > 0 ? 'Added' : 'Took away'} ${Math.abs(count)}${kind === 'x' ? 'x' : ''} on ${side} pan only`;
    }
    return true;
  }

  function undoCh05(st) {
    const prev = st.history.pop();
    if (!prev) return false;
    st.leftX = prev.leftX;
    st.leftOnes = prev.leftOnes;
    st.rightX = prev.rightX;
    st.rightOnes = prev.rightOnes;
    st.lastMoveLabel = `Undid move → ${prev.lastMoveLabel}`;
    return true;
  }

  function evalCh05(st) {
    const leftVal = st.leftX * st.hiddenX + st.leftOnes;
    const rightVal = st.rightX * st.hiddenX + st.rightOnes;
    const diff = leftVal - rightVal;
    const balanced = Math.abs(diff) < 1e-6;
    // Negative rotation in +y-down SVG/Canvas drops left (-x) down when diff > 0 (left pan heavier)
    const tiltRad = -clamp(diff / 14, -0.32, 0.32);
    const xSolvedLeft = st.leftX === 1 && st.leftOnes === 0 && st.rightX === 0;
    const xSolvedRight = st.rightX === 1 && st.rightOnes === 0 && st.leftX === 0;
    const isolated = balanced && (xSolvedLeft || xSolvedRight);
    const solvedValue = xSolvedLeft ? st.rightOnes : (xSolvedRight ? st.leftOnes : null);
    return { leftVal, rightVal, diff, balanced, tiltRad, isolated, solvedValue, goalReached: isolated };
  }

  function formatPanExpr(xCoef, ones) {
    const parts = [];
    if (xCoef !== 0) {
      if (xCoef === 1) parts.push('x');
      else if (xCoef === -1) parts.push('−x');
      else parts.push(`${xCoef < 0 ? '−' : ''}${Math.abs(xCoef)}x`);
    }
    if (ones !== 0) {
      if (parts.length === 0) parts.push(fmtNum(ones));
      else parts.push(ones > 0 ? `+ ${ones}` : `− ${Math.abs(ones)}`);
    }
    return parts.length ? parts.join(' ') : '0';
  }

  // Ch 7: Graphing Lines (Point Tool + Pin Ghost) & Function Builder (Mystery Blind)
  const CH07_OPS = [
    { id: 'add2', label: '+ 2', fn: v => v + 2 },
    { id: 'sub3', label: '− 3', fn: v => v - 3 },
    { id: 'mul2', label: '× 2', fn: v => v * 2 },
    { id: 'mul3', label: '× 3', fn: v => v * 3 },
    { id: 'div2', label: '÷ 2', fn: v => v / 2 }
  ];

  function createCh07State() {
    return {
      mode: 'graph-probe', // 'graph-probe' | 'function-machine'
      p1: { x: 0, y: 1 },
      p2: { x: 2, y: 5 },
      ghost: null, // { m, c }
      probeActive: true,
      probe: { x: 1, y: 3 },
      op1: 'add2',
      op2: 'mul3',
      testInput: 4,
      mysteryMode: false,
      mysterySecret: ['mul2', 'add2'],
      mysteryRevealed: false,
      testedInputs: [4],
      mysteryMatched: false
    };
  }

  function applyOpId(opId, val) {
    const op = CH07_OPS.find(o => o.id === opId) || CH07_OPS[0];
    return op.fn(val);
  }

  function evalCh07(st) {
    const dx = st.p2.x - st.p1.x;
    const dy = st.p2.y - st.p1.y;
    const vertical = Math.abs(dx) < 1e-6;
    const m = vertical ? Infinity : dy / dx;
    const c = vertical ? NaN : st.p1.y - m * st.p1.x;
    const probeYOnLine = vertical ? st.probe.y : m * st.probe.x + c;
    const probeOnLine = vertical
      ? Math.abs(st.probe.x - st.p1.x) <= 0.18
      : Math.abs(st.probe.y - probeYOnLine) <= 0.22;

    const isParallelGhost = Boolean(st.ghost && !vertical && Math.abs(st.ghost.m - m) < 0.08);
    const isPerpGhost = Boolean(st.ghost && !vertical && Math.abs(st.ghost.m * m + 1) < 0.08);

    // Function machine forward vs swapped
    const activeOps = st.mysteryMode ? st.mysterySecret : [st.op1, st.op2];
    const midVal = applyOpId(activeOps[0], st.testInput);
    const outVal = applyOpId(activeOps[1], midVal);

    const userMatchesMystery = st.mysteryMode &&
      st.op1 === st.mysterySecret[0] &&
      st.op2 === st.mysterySecret[1];

    const goalReached = st.mode === 'function-machine'
      ? (userMatchesMystery || st.mysteryMatched)
      : (isPerpGhost && probeOnLine);

    return {
      vertical,
      m,
      c,
      probeOnLine,
      isParallelGhost,
      isPerpGhost,
      midVal,
      outVal,
      userMatchesMystery,
      goalReached
    };
  }

  // Ch 13: Live Data Sampler (Projectile Data Lab / Sampling Distributions)
  function createCh13State() {
    return {
      mode: 'live-sampler', // 'live-sampler' | 'se-wald'
      popSigma: 12,
      sampleN: 9,
      seed: 17,
      samples: [], // array of sample means
      rng: createRng(17),
      snapshotAtSmallN: false,
      sampledAtLargeN: false
    };
  }

  function drawSamplesCh13(st, count) {
    const mu = 50;
    const sigma = st.popSigma;
    const n = st.sampleN;
    for (let k = 0; k < count; k++) {
      let sum = 0;
      for (let i = 0; i < n; i++) sum += mu + sigma * st.rng.normal();
      st.samples.push(sum / n);
    }
    if (n >= 16 && st.samples.length >= 5) st.sampledAtLargeN = true;
    return st.samples;
  }

  function evalCh13(st) {
    const theoreticalSE = st.popSigma / Math.sqrt(Math.max(1, st.sampleN));
    const count = st.samples.length;
    const meanOfMeans = count
      ? st.samples.reduce((a, b) => a + b, 0) / count
      : 50;
    const varianceOfMeans = count > 1
      ? st.samples.reduce((acc, v) => acc + Math.pow(v - meanOfMeans, 2), 0) / count
      : 0;
    const observedSE = Math.sqrt(varianceOfMeans);
    const goalReached = (st.snapshotAtSmallN && st.sampledAtLargeN) || count >= 15;
    return { theoreticalSE, count, meanOfMeans, observedSE, goalReached };
  }

  // Ch 14: Center & Variability + Mean Balance + Level Out + Best-Fit Residuals
  function createCh14State() {
    return {
      mode: 'mean-balance', // 'mean-balance' | 'level-out' | 'histogram' | 'best-fit'
      dots: [4, 6, 7, 8, 9, 10, 12],
      sorted: false,
      predictVal: 6,
      fulcrumX: 8,
      revealedCenter: false,
      scatterPts: [
        { x: 1, y: 2.2 },
        { x: 2, y: 3.1 },
        { x: 3, y: 4.5 },
        { x: 4, y: 5.0 },
        { x: 5, y: 6.4 },
        { x: 6, y: 7.2 }
      ],
      mySlope: 0.6,
      myIntercept: 2.0,
      showBestFit: false,
      rng: createRng(42)
    };
  }

  function computeMedian(arr) {
    if (!arr.length) return 0;
    const s = [...arr].sort((a, b) => a - b);
    const mid = Math.floor(s.length / 2);
    return s.length % 2 === 1 ? s[mid] : 0.5 * (s[mid - 1] + s[mid]);
  }

  function computeQuartiles(arr) {
    const s = [...arr].sort((a, b) => a - b);
    const n = s.length;
    if (n < 2) return { q1: s[0] || 0, med: s[0] || 0, q3: s[0] || 0, iqr: 0 };
    const med = computeMedian(s);
    const lo = s.slice(0, Math.floor(n / 2));
    const hi = s.slice(Math.ceil(n / 2));
    const q1 = computeMedian(lo);
    const q3 = computeMedian(hi);
    return { q1, med, q3, iqr: q3 - q1 };
  }

  function computeOLS(pts) {
    const n = pts.length || 1;
    const mx = pts.reduce((a, p) => a + p.x, 0) / n;
    const my = pts.reduce((a, p) => a + p.y, 0) / n;
    let num = 0;
    let den = 0;
    for (const p of pts) {
      num += (p.x - mx) * (p.y - my);
      den += (p.x - mx) * (p.x - mx);
    }
    const m = den > 1e-9 ? num / den : 0;
    const c = my - m * mx;
    return { m, c };
  }

  function evalCh14(st) {
    const n = st.dots.length || 1;
    const totalSum = st.dots.reduce((a, b) => a + b, 0);
    const meanVal = totalSum / n;
    const medianVal = computeMedian(st.dots);
    const q = computeQuartiles(st.dots);
    const mad = st.dots.reduce((a, v) => a + Math.abs(v - meanVal), 0) / n;
    const torque = st.dots.reduce((a, v) => a + (v - st.fulcrumX), 0);
    const fulcrumBalanced = Math.abs(st.fulcrumX - meanVal) <= 0.25;
    const hasOutlierSplit = Math.abs(meanVal - medianVal) >= 1.2;

    const mySSR = st.scatterPts.reduce((a, p) => {
      const r = p.y - (st.mySlope * p.x + st.myIntercept);
      return a + r * r;
    }, 0);
    const ols = computeOLS(st.scatterPts);
    const bestSSR = st.scatterPts.reduce((a, p) => {
      const r = p.y - (ols.m * p.x + ols.c);
      return a + r * r;
    }, 0);
    const fitGoal = mySSR <= bestSSR * 1.45;
    const goalReached = st.mode === 'best-fit' ? fitGoal : (fulcrumBalanced && hasOutlierSplit);

    return {
      totalSum,
      meanVal,
      medianVal,
      q1: q.q1,
      q3: q.q3,
      iqr: q.iqr,
      mad,
      torque,
      fulcrumBalanced,
      hasOutlierSplit,
      mySSR,
      bestSSR,
      ols,
      fitGoal,
      goalReached
    };
  }

  // Ch 17 & Ch 18: Calculus Grapher (Reference Line + Smooth/Wave/Cusp/Step + Predict f')
  function createCalcState(chNum) {
    return {
      mode: 'calculus-grapher',
      curveKind: 'smooth', // 'smooth' | 'wave' | 'cusp' | 'step'
      refX: 1.5,
      interacted: false,
      minRefX: 1.5,
      maxRefX: 1.5,
      predictEnabled: chNum === 17,
      predictRevealed: false,
      predictNodes: [
        { x: 0.5, y: 0 },
        { x: 1.0, y: 0 },
        { x: 1.5, y: 0 },
        { x: 2.0, y: 0 },
        { x: 2.5, y: 0 }
      ]
    };
  }

  function evalCalcFunction(kind, x) {
    switch (kind) {
      case 'wave':
        return {
          f: Math.sin(x * 1.6),
          fp: 1.6 * Math.cos(x * 1.6),
          F: (1 - Math.cos(x * 1.6)) / 1.6,
          definedDeriv: true
        };
      case 'cusp': {
        const diff = x - 1.5;
        const left = x < 1.5;
        const atCusp = Math.abs(diff) < 0.04;
        const f = Math.abs(diff);
        const fp = atCusp ? NaN : (left ? -1 : 1);
        const F = left ? 1.5 * x - 0.5 * x * x : 1.125 + 0.5 * (x - 1.5) * (x - 1.5);
        return { f, fp, F, definedDeriv: !atCusp };
      }
      case 'step': {
        const before = x < 1.5;
        const atJump = Math.abs(x - 1.5) < 0.05;
        const f = before ? 0.6 : 2.0;
        const fp = atJump ? NaN : 0;
        const F = before ? 0.6 * x : 0.6 * 1.5 + 2.0 * (x - 1.5);
        return { f, fp, F, definedDeriv: !atJump };
      }
      case 'smooth':
      default:
        return {
          f: 0.5 * x * x,
          fp: x,
          F: (x * x * x) / 6,
          definedDeriv: true
        };
    }
  }

  function evalCalcState(st) {
    const val = evalCalcFunction(st.curveKind, st.refX);
    const errSum = st.predictNodes.reduce((acc, node) => {
      const exact = evalCalcFunction(st.curveKind, node.x).fp;
      return acc + (Number.isFinite(exact) ? Math.abs(node.y - exact) : 0);
    }, 0);
    const avgPredictErr = errSum / Math.max(1, st.predictNodes.length);
    const predictClose = avgPredictErr <= 0.45;
    const minRef = typeof st.minRefX === 'number' ? st.minRefX : st.refX;
    const maxRef = typeof st.maxRefX === 'number' ? st.maxRefX : st.refX;
    const sweptRange = maxRef - minRef;
    const goalReached = st.predictEnabled
      ? (st.predictRevealed && predictClose)
      : Boolean(st.interacted && ((st.curveKind === 'cusp' && Math.abs(st.refX - 1.5) <= 0.15) || sweptRange >= 0.6));
    return { val, avgPredictErr, predictClose, goalReached };
  }

  // ---------- Unified Controller Managing HTML Stage, Snapshots, Voicing & Bridge ----------

  const LAB_REGISTRY = {};

  function getOrCreateLabState(chNum) {
    if (!LAB_REGISTRY[chNum]) {
      switch (chNum) {
        case 1: LAB_REGISTRY[chNum] = createCh01State(); break;
        case 2: LAB_REGISTRY[chNum] = createCh02State(); break;
        case 3: LAB_REGISTRY[chNum] = createCh03State(); break;
        case 4: LAB_REGISTRY[chNum] = createCh04State(); break;
        case 5: LAB_REGISTRY[chNum] = createCh05State(0); break;
        case 7: LAB_REGISTRY[chNum] = createCh07State(); break;
        case 13: LAB_REGISTRY[chNum] = createCh13State(); break;
        case 14: LAB_REGISTRY[chNum] = createCh14State(); break;
        case 17:
        case 18: LAB_REGISTRY[chNum] = createCalcState(chNum); break;
        default: LAB_REGISTRY[chNum] = { mode: 'default', goalDone: false }; break;
      }
    }
    return LAB_REGISTRY[chNum];
  }

  function resetChapterLabState(chNum) {
    delete LAB_REGISTRY[chNum];
    return getOrCreateLabState(chNum);
  }

  function evalChapterData(chNum, st) {
    switch (chNum) {
      case 1: return evalCh01(st);
      case 2: return evalCh02(st);
      case 3: return evalCh03(st);
      case 4: return evalCh04(st);
      case 5: return evalCh05(st);
      case 7: return evalCh07(st);
      case 13: return evalCh13(st);
      case 14: return evalCh14(st);
      case 17:
      case 18: return evalCalcState(st);
      default: return {};
    }
  }

  function buildVoicingForChapter(chNum, st, params, evalData, readoutPlain) {
    switch (chNum) {
      case 1:
        return {
          name: 'Number line distance',
          object: `A = ${fmtNum(st.a)}, B = ${fmtNum(st.b)}`,
          context: `Directed change is ${fmtNum(evalData.directed)} and distance is ${fmtNum(evalData.distance)}.`,
          hint: 'Drag A or B across zero to see when directed change turns negative while distance stays positive.'
        };
      case 2:
        return {
          name: 'Double number line',
          object: `Marker at ${fmtNum(st.probeScale)} bottom units`,
          context: `${fmtNum(st.probeScale)} bottom units match ${fmtNum(evalData.topAtProbe)} top units (1 unit = ${fmtNum(evalData.unitRatio)}).`,
          hint: 'Slide down to 1 on the bottom rail to find the unit rate first.'
        };
      case 3:
        return {
          name: 'Two-hand ratio tuner',
          object: `Left = ${fmtNum(st.left)}, Right = ${fmtNum(st.right)}`,
          context: evalData.inProportion
            ? `In proportion! ${fmtNum(st.left)} to ${fmtNum(st.right)} keeps the target ratio ${st.targetLeft}:${st.targetRight}.`
            : `Out of tune for ${st.targetLeft}:${st.targetRight}. Adjust one hand or lock the ratio once matched.`,
          hint: 'Lock the ratio when green, then move either hand to scale both together.'
        };
      case 4:
        return {
          name: 'Area model',
          object: `Edges (x + ${fmtNum(evalData.p)}) and (x + ${fmtNum(evalData.q)})`,
          context: `Four boxes combine into x² + ${fmtNum(evalData.linearSum)}x + ${fmtNum(evalData.pq)}.`,
          hint: st.mode === 'area-factor' ? 'Step the two edge numbers until all four boxes match the target.' : 'Try opposite signs like +3 and −3.'
        };
      case 5:
        return {
          name: 'Balance beam',
          object: `${formatPanExpr(st.leftX, st.leftOnes)} on left, ${formatPanExpr(st.rightX, st.rightOnes)} on right`,
          context: evalData.isolated
            ? `Balanced with x alone: x = ${evalData.solvedValue}.`
            : (evalData.balanced ? 'The beam is level: both pans still weigh the same.' : `The beam tilts: left minus right differs by ${fmtNum(evalData.diff)}.`),
          hint: st.symLock ? 'Lock is on, so every step hits both pans equally.' : 'Lock is off: turning Lock on protects equality.'
        };
      case 7:
        return st.mode === 'function-machine'
          ? {
              name: 'Rule machine',
              object: `Input ${fmtNum(st.testInput)} gives ${fmtNum(evalData.outVal)}`,
              context: st.mysteryMode && !st.mysteryRevealed
                ? `Mystery shutter closed: test several inputs to deduce the hidden two-step rule.`
                : `Applying the first block then the second sends ${fmtNum(st.testInput)} to ${fmtNum(evalData.outVal)}.`,
              hint: 'Swap the two blocks to check whether order changes the output.'
            }
          : {
              name: 'Line and point probe',
              object: evalData.vertical ? 'Vertical line' : `y = ${fmtNum(evalData.m)}x + ${fmtNum(evalData.c)}`,
              context: evalData.isPerpGhost
                ? 'Perpendicular to pinned ghost: product of slopes is −1.'
                : (evalData.probeOnLine ? `Probe (${fmtNum(st.probe.x)}, ${fmtNum(st.probe.y)}) sits right on the line.` : `Move the line points or drag the probe onto the line.`),
              hint: 'Pin a ghost line, then drag to test perpendicular or parallel lines.'
            };
      case 13:
        return {
          name: 'Live data sampler',
          object: `${evalData.count} samples of size ${st.sampleN}`,
          context: `Theoretical spread is ${fmtNum(evalData.theoreticalSE)}; average sample mean is ${fmtNum(evalData.meanOfMeans)}.`,
          hint: 'Take samples at n = 4, pin a snapshot, then compare with n = 16.'
        };
      case 14:
        return st.mode === 'best-fit'
          ? {
              name: 'Least-squares line',
              object: `My slope ${fmtNum(st.mySlope)}, squared residual sum ${fmtNum(evalData.mySSR)}`,
              context: `Smaller yellow squares mean a tighter fit (best possible sum is ${fmtNum(evalData.bestSSR)}).`,
              hint: 'Drag either orange handle to shrink the sum of squared residuals.'
            }
          : {
              name: 'Data balance and spread',
              object: `Mean ${fmtNum(evalData.meanVal)}, Median ${fmtNum(evalData.medianVal)}, Fulcrum ${fmtNum(st.fulcrumX)}`,
              context: evalData.fulcrumBalanced
                ? `Beam balanced right on the mean (${fmtNum(evalData.meanVal)}).`
                : `Beam tilts: drag the yellow fulcrum toward ${fmtNum(evalData.meanVal)} or drag an extreme dot right.`,
              hint: 'Drag the highest dot far right and watch the mean chase it while the median stays put.'
            };
      case 17:
      case 18:
        return {
          name: 'Calculus grapher',
          object: `Reference line at x = ${fmtNum(st.refX)}`,
          context: evalData.val.definedDeriv
            ? `Height f = ${fmtNum(evalData.val.f)}, slope f′ = ${fmtNum(evalData.val.fp)}, area ∫f = ${fmtNum(evalData.val.F)}.`
            : `At x = ${fmtNum(st.refX)}, the slope jumps suddenly so f′ is undefined here while area stays continuous.`,
          hint: 'Slide the vertical reference line across peaks, roots, and cusps.'
        };
      default:
        return {
          name: `Chapter ${chNum} figure`,
          object: Object.entries(params || {}).map(([k, v]) => `${k}=${fmtNum(v)}`).join(', '),
          context: readoutPlain || `Adjust the figure for Chapter ${chNum} and watch what stays fixed.`,
          hint: 'Try pushing a slider to either end and compare what changes with what stays fixed.'
        };
    }
  }

  // ---------- Canvas Drawing & Direct Pointer Handling for Browser ----------

  function installBrowserRuntime() {
    if (typeof document === 'undefined' || typeof window === 'undefined') return;
    if (window.__kymPhetInstalled) return;
    window.__kymPhetInstalled = true;

    const session = {
      step: 'symbolic',
      interactionCount: 0,
      snapshots: [],
      lockedControls: [],
      customChallengePrompt: null,
      activeDrag: null, // { type, id, pointerId, offset }
      pointers: new Map(), // multi-touch pointer tracking
      lastVoicingText: '',
      lastGoalNotifiedChapter: null
    };

    function getThemeColors() {
      const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
      return {
        isDark,
        red: isDark ? '#E5614F' : '#C3362B',
        blue: isDark ? '#7097DA' : '#23519C',
        amber: isDark ? '#F0BC45' : '#E2A41C',
        green: isDark ? '#9DB88C' : '#4F6B45',
        ink: isDark ? '#F0ECE2' : '#1F1B16',
        muted: isDark ? '#A8A49C' : '#6B665E',
        card: isDark ? '#22262A' : '#FFFDF7',
        elevated: isDark ? '#181612' : '#F1EADC'
      };
    }

    function currentChapterObj() {
      const list = typeof CHAPTERS !== 'undefined' ? CHAPTERS : [];
      const idx = typeof currentChapter !== 'undefined' ? currentChapter : 0;
      return list[idx] || { number: idx, title: `Chapter ${idx}`, intuitionToFormula: { ahaInvariant: '' } };
    }

    function postBridge(payload) {
      try {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.kymmathsBridge) {
          window.webkit.messageHandlers.kymmathsBridge.postMessage(payload);
        }
      } catch (_) {}
    }

    function currentParamsObject() {
      const p = {};
      ['a', 'b', 'c'].forEach(k => {
        const el = document.getElementById(`param-${k}`);
        if (el) p[k] = parseFloat(el.value);
      });
      return p;
    }

    const stageListeners = new Set();
    let lastStageContext = null;

    function syncStepVisibility(chNum, goalReached, voicing) {
      document.documentElement.setAttribute('data-stage-step', session.step);
      const readoutEl = document.getElementById('live-readout');
      if (readoutEl) {
        if (session.step === 'openPlay') {
          if (!readoutEl.dataset.originalHtml) readoutEl.dataset.originalHtml = readoutEl.innerHTML;
          readoutEl.innerHTML = '<i>Explore freely first. Drag on the picture or move the controls, then switch to <b>Cut away</b> or <b>Make it ideal</b>.</i>';
        }
      }
      const banner = document.getElementById('challenge-banner');
      if (banner) {
        if (session.step === 'challenge') {
          banner.hidden = false;
          const prompt = session.customChallengePrompt || defaultChallengePrompt(chNum);
          banner.innerHTML = `<span class="badge ${goalReached ? 'done' : ''}">${goalReached ? 'Goal met' : 'Your task'}</span> ${escapeHtml(prompt)}`;
        } else {
          banner.hidden = true;
        }
      }
      const voiceEl = document.getElementById('voicing-live');
      if (voiceEl && voicing) {
        voiceEl.textContent = voicing.context;
      }
    }

    function syncSliderValue(key, rawValue) {
      const inp = document.getElementById(`param-${key}`);
      const valEl = document.getElementById(`val-${key}`);
      if (!inp) return;
      const numVal = Number(rawValue);
      if (Number.isFinite(numVal)) inp.value = String(numVal);
      if (valEl) valEl.textContent = inp.value + (inp.dataset.unit || '');
    }

    function configureSlidersForState(chNum, st) {
      if (chNum === 4) {
        const inpB = document.getElementById('param-b');
        const inpC = document.getElementById('param-c');
        const lblB = document.getElementById('lbl-b');
        const lblC = document.getElementById('lbl-c');
        if (st.mode === 'area-generic') {
          if (inpB) { inpB.min = '-5'; inpB.max = '5'; inpB.step = '1'; }
          if (inpC) { inpC.min = '-5'; inpC.max = '5'; inpC.step = '1'; }
          if (lblB) lblB.textContent = 'First number p:';
          if (lblC) lblC.textContent = 'Second number q:';
          syncSliderValue('a', st.x);
          syncSliderValue('b', st.p);
          syncSliderValue('c', st.q);
        } else if (st.mode === 'area-scale') {
          st.p = Math.max(1, Math.round(st.p));
          st.q = Math.max(1, Math.round(st.q));
          if (inpB) { inpB.min = '1'; inpB.max = '6'; inpB.step = '1'; }
          if (inpC) { inpC.min = '1'; inpC.max = '6'; inpC.step = '1'; }
          if (lblB) lblB.textContent = 'First number:';
          if (lblC) lblC.textContent = 'Second number:';
          syncSliderValue('a', st.x);
          syncSliderValue('b', st.p);
          syncSliderValue('c', st.q);
        }
      } else if (chNum === 7 && st.mode === 'function-machine') {
        const inpA = document.getElementById('param-a');
        const lblA = document.getElementById('lbl-a');
        if (inpA) { inpA.min = '-4'; inpA.max = '8'; inpA.step = '1'; }
        if (lblA) lblA.textContent = 'Input x:';
        syncSliderValue('a', st.testInput);
      }
    }

    function defaultChallengePrompt(chNum) {
      switch (chNum) {
        case 1: return 'Place A and B so the distance is 7 while B − A is negative.';
        case 2: return 'Slide the marker to 1 unit first, then scale up to 5 units.';
        case 3: return 'Move both hands above 3 while keeping the target ratio tuned in green.';
        case 4: return 'Switch to Factor it and match the four inner areas, or cancel the middle x-term to zero.';
        case 5: return 'Keep the beam balanced and isolate 1x alone on one pan to reveal x.';
        case 7: return 'Pin a ghost line, then build a perpendicular line with the point probe sitting on it.';
        case 13: return 'Draw 15+ samples (or compare snapshots at n = 4 and n = 16).';
        case 14: return 'Balance the yellow fulcrum on the mean, then drag one dot far right to separate mean from median.';
        case 17: return 'Sketch a derivative prediction and reveal f′(x), or inspect the cusp at x = 1.5.';
        case 18: return 'Explore how net signed area accumulates as the reference line crosses zero.';
        default: return 'Explore the figure to find what stays fixed, then test an extreme edge case.';
      }
    }

    function renderSnapshotStrip(chNum) {
      const strip = document.getElementById('snapshot-strip');
      if (!strip) return;
      const items = session.snapshots.filter(s => s.chapterNumber === chNum);
      if (!items.length) {
        strip.hidden = true;
        strip.innerHTML = '';
        return;
      }
      strip.hidden = false;
      strip.innerHTML = items.map(snap => `
        <div class="snap-card" data-snap-id="${escapeHtml(snap.id)}">
          ${snap.dataUrl ? `<img src="${escapeHtml(snap.dataUrl)}" alt="${escapeHtml(snap.title)}">` : ''}
          <div class="snap-meta">
            <b>${escapeHtml(snap.title)}</b>
            <span>${escapeHtml(snap.summary)}</span>
          </div>
          <div class="snap-actions">
            <button type="button" class="btn secondary snap-restore" data-snap-id="${escapeHtml(snap.id)}">Restore</button>
            <button type="button" class="btn snap-journal" data-snap-id="${escapeHtml(snap.id)}">Pin to Journal</button>
          </div>
        </div>
      `).join('');

      strip.querySelectorAll('.snap-restore').forEach(btn => {
        btn.addEventListener('click', () => {
          const snap = session.snapshots.find(s => s.id === btn.dataset.snapId);
          if (!snap) return;
          if (snap.labState) {
            LAB_REGISTRY[chNum] = JSON.parse(JSON.stringify(snap.labState));
            const restored = getOrCreateLabState(chNum);
            configureSlidersForState(chNum, restored);
          }
          ['a', 'b', 'c'].forEach(k => {
            if (typeof snap.params[k] === 'number') syncSliderValue(k, snap.params[k]);
          });
          renderChapterToolbar(chNum);
          if (typeof window.drawSandbox === 'function') window.drawSandbox();
        });
      });
      strip.querySelectorAll('.snap-journal').forEach(btn => {
        btn.addEventListener('click', () => {
          const snap = session.snapshots.find(s => s.id === btn.dataset.snapId);
          if (!snap) return;
          postBridge({
            type: 'saveSnapshotToJournal',
            id: snap.id,
            chapterNumber: snap.chapterNumber,
            title: snap.title,
            summary: snap.summary,
            contextSentence: snap.contextSentence,
            params: snap.params,
            pngDataUrl: snap.pngDataUrl || '',
            dataUrl: snap.pngDataUrl || snap.dataUrl || ''
          });
          btn.textContent = 'Saved ✓';
        });
      });
    }

    // ---------- Interactive Lab Toolbars & Canvas Drawing ----------

    function renderChapterToolbar(chNum) {
      const host = document.getElementById('lab-tools');
      if (!host) return;
      const st = getOrCreateLabState(chNum);
      const htmlBtn = (id, label, active = false) =>
        `<button type="button" class="medium-pill lab-tool-btn" data-tool="${id}" aria-pressed="${active ? 'true' : 'false'}">${label}</button>`;

      let html = '';
      if (chNum === 1) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:distance', 'Distance |B − A|', st.mode === 'distance')
          + htmlBtn('mode:directed', 'Directed B − A', st.mode === 'directed')
          + htmlBtn('mode:classic-turns', 'Turns & HCF/LCM', st.mode === 'classic-turns')
          + `</div>`
          + (st.mode === 'classic-turns'
            ? ''
            : `<div class="lab-mode-bar">`
              + htmlBtn('ctx:numberLine', 'Number line', st.context === 'numberLine')
              + htmlBtn('ctx:temp', 'Temp °C', st.context === 'temp')
              + htmlBtn('ctx:money', 'Net worth ₹', st.context === 'money')
              + `</div>`);
      } else if (chNum === 2) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:double-line', 'Double number line', st.mode === 'double-line')
          + htmlBtn('mode:recurring', 'Recurring decimals', st.mode === 'recurring')
          + `</div>`;
      } else if (chNum === 3) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:ratio-tuner', 'Two-hand tuner', st.mode === 'ratio-tuner')
          + htmlBtn('mode:compare-blind', 'Compare & Predict', st.mode === 'compare-blind')
          + htmlBtn('mode:compound-growth', 'Compound growth', st.mode === 'compound-growth')
          + `</div>`
          + (st.mode === 'ratio-tuner'
            ? `<div class="lab-mode-bar">`
              + htmlBtn('target:2:3', 'Target 2:3', st.targetLeft === 2 && st.targetRight === 3)
              + htmlBtn('target:3:4', 'Target 3:4', st.targetLeft === 3 && st.targetRight === 4)
              + htmlBtn('target:1:2', 'Target 1:2', st.targetLeft === 1 && st.targetRight === 2)
              + htmlBtn('toggle:lock', st.ratioLocked ? 'Ratio Lock: On' : 'Ratio Lock: Off', st.ratioLocked)
              + htmlBtn('toggle:ticks', `Ticks: ${st.tickMode}`, st.tickMode !== 'none')
              + `</div>`
            : (st.mode === 'compare-blind'
              ? `<div class="lab-mode-bar">`
                + htmlBtn('cmp:same', 'Predict: Same ratio', st.comparePrediction === 'same')
                + htmlBtn('cmp:diff', 'Predict: Different', st.comparePrediction === 'different')
                + htmlBtn('cmp:reveal', st.compareRevealed ? 'Revealed' : 'Check prediction', st.compareRevealed)
                + htmlBtn('cmp:additive', 'Try +2/+2 trap', false)
                + `</div>`
              : ''));
      } else if (chNum === 4) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:area-scale', 'To scale', st.mode === 'area-scale')
          + htmlBtn('mode:area-generic', 'Generic (signs)', st.mode === 'area-generic')
          + htmlBtn('mode:area-factor', 'Factor it', st.mode === 'area-factor')
          + `</div>`
          + (st.mode === 'area-factor'
            ? `<div class="lab-mode-bar">`
              + htmlBtn('f:p-', 'p − 1', false) + htmlBtn('f:p+', 'p + 1', false)
              + htmlBtn('f:q-', 'q − 1', false) + htmlBtn('f:q+', 'q + 1', false)
              + htmlBtn('f:next', 'Next puzzle', false)
              + `</div>`
            : ``);
      } else if (chNum === 5) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('op:addX', '+x', false)
          + htmlBtn('op:subX', '−x', false)
          + htmlBtn('op:add1', '+1', false)
          + htmlBtn('op:sub1', '−1', false)
          + htmlBtn('op:div2', '÷2', false)
          + htmlBtn('op:div3', '÷3', false)
          + htmlBtn('op:neg1', '×(−1)', false)
          + `</div><div class="lab-mode-bar">`
          + htmlBtn('toggle:sym', st.symLock ? 'Symmetry Lock: On' : 'Symmetry Lock: Off', st.symLock)
          + htmlBtn('op:undo', 'Undo move', false)
          + htmlBtn('op:nextPuz', 'New equation', false)
          + `</div>`;
      } else if (chNum === 7) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:graph-probe', 'Graph & Probe', st.mode === 'graph-probe')
          + htmlBtn('mode:function-machine', 'Rule Machine', st.mode === 'function-machine')
          + `</div>`
          + (st.mode === 'graph-probe'
            ? `<div class="lab-mode-bar">`
              + htmlBtn('g:pin', st.ghost ? 'Update ghost' : 'Pin ghost', Boolean(st.ghost))
              + htmlBtn('g:clearGhost', 'Clear ghost', false)
              + htmlBtn('g:probe', st.probeActive ? 'Point probe: On' : 'Point probe: Off', st.probeActive)
              + `</div>`
            : `<div class="lab-mode-bar">`
              + htmlBtn('m:swap', 'Swap order', false)
              + htmlBtn('m:cycle1', `Step 1: ${CH07_OPS.find(o => o.id === st.op1)?.label}`, false)
              + htmlBtn('m:cycle2', `Step 2: ${CH07_OPS.find(o => o.id === st.op2)?.label}`, false)
              + htmlBtn('m:mystery', st.mysteryMode ? 'Mystery: On' : 'Mystery: Off', st.mysteryMode)
              + (st.mysteryMode ? htmlBtn('m:reveal', st.mysteryRevealed ? 'Rule shown' : 'Check / Reveal', st.mysteryRevealed) : '')
              + `</div>`);
      } else if (chNum === 13) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:live-sampler', 'Live sampler', st.mode === 'live-sampler')
          + htmlBtn('mode:se-wald', 'Standard error & Wald', st.mode === 'se-wald')
          + `</div>`
          + (st.mode === 'live-sampler'
            ? `<div class="lab-mode-bar">`
              + htmlBtn('s:1', 'Sample 1', false)
              + htmlBtn('s:5', 'Sample 5', false)
              + htmlBtn('s:15', 'Sample 15', false)
              + htmlBtn('s:n4', 'n = 4', st.sampleN === 4)
              + htmlBtn('s:n16', 'n = 16', st.sampleN === 16)
              + `</div>`
            : ``);
      } else if (chNum === 14) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('mode:mean-balance', 'Balance & Median', st.mode === 'mean-balance')
          + htmlBtn('mode:level-out', 'Level Out', st.mode === 'level-out')
          + htmlBtn('mode:histogram', 'Histogram', st.mode === 'histogram')
          + htmlBtn('mode:best-fit', 'Best-Fit Line', st.mode === 'best-fit')
          + `</div>`
          + (st.mode === 'mean-balance' || st.mode === 'level-out'
            ? `<div class="lab-mode-bar">`
              + htmlBtn('d:kick1', '+1 score', false)
              + htmlBtn('d:sort', st.sorted ? 'Sorted ✓' : 'Sort data', st.sorted)
              + htmlBtn('d:reveal', st.revealedCenter ? 'Hide Mean/Med' : 'Reveal Mean & Median', st.revealedCenter)
              + htmlBtn('d:outlier', 'Push outlier →', false)
              + `</div>`
            : (st.mode === 'best-fit'
              ? `<div class="lab-mode-bar">`
                + htmlBtn('bf:reveal', st.showBestFit ? 'Hide best fit' : 'Reveal best fit', st.showBestFit)
                + `</div>`
              : ``));
      } else if (chNum === 17 || chNum === 18) {
        html = `<div class="lab-mode-bar">`
          + htmlBtn('c:smooth', 'Smooth ½x²', st.curveKind === 'smooth')
          + htmlBtn('c:wave', 'Wave sin', st.curveKind === 'wave')
          + htmlBtn('c:cusp', 'Cusp |x−1.5|', st.curveKind === 'cusp')
          + htmlBtn('c:step', 'Step jump', st.curveKind === 'step')
          + (chNum === 17 ? htmlBtn('c:reveal', st.predictRevealed ? 'f′(x) shown' : 'Reveal my f′(x)', st.predictRevealed) : '')
          + `</div>`;
      }
      host.innerHTML = html;
      host.hidden = !html;

      host.querySelectorAll('.lab-tool-btn').forEach(btn => {
        btn.addEventListener('click', () => handleToolClick(chNum, btn.dataset.tool));
      });
    }

    function recordInteraction() {
      session.interactionCount += 1;
    }

    function handleToolClick(chNum, tool) {
      const st = getOrCreateLabState(chNum);
      recordInteraction();
      if (tool.startsWith('mode:')) {
        const nextMode = tool.slice(5);
        st.mode = nextMode;
        configureSlidersForState(chNum, st);
        if (chNum === 1 && nextMode === 'classic-turns' && typeof window.applyChapterSliders === 'function') {
          window.applyChapterSliders(1);
        } else if (chNum === 2 && nextMode === 'recurring' && typeof window.applyChapterSliders === 'function') {
          window.applyChapterSliders(2);
        } else if (chNum === 3 && nextMode === 'compound-growth' && typeof window.applyChapterSliders === 'function') {
          window.applyChapterSliders(3);
        }
        SoundEngine.playDetent(1);
      } else if (chNum === 1 && tool.startsWith('ctx:')) {
        st.context = tool.slice(4);
        SoundEngine.playDetent(1);
      } else if (chNum === 3) {
        if (tool.startsWith('target:')) {
          const [, a, b] = tool.split(':');
          st.targetLeft = Number(a);
          st.targetRight = Number(b);
          st.ratioLocked = false;
        } else if (tool === 'toggle:lock') {
          const ev = evalCh03(st);
          if (!st.ratioLocked && ev.inProportion) {
            st.ratioLocked = true;
            st.lockedRatio = st.left / Math.max(0.2, st.right);
            SoundEngine.playLevelChime();
          } else {
            st.ratioLocked = false;
            SoundEngine.playDetent(-1);
          }
        } else if (tool === 'toggle:ticks') {
          st.tickMode = st.tickMode === 'numbered' ? 'plain' : (st.tickMode === 'plain' ? 'none' : 'numbered');
        } else if (tool === 'cmp:same') {
          st.comparePrediction = 'same';
        } else if (tool === 'cmp:diff') {
          st.comparePrediction = 'different';
        } else if (tool === 'cmp:reveal') {
          st.compareRevealed = true;
          SoundEngine.playLevelChime();
        } else if (tool === 'cmp:additive') {
          st.compareUserLeft = st.compareTargetLeft + 2;
          st.compareUserRight = st.compareTargetRight + 2;
          st.compareRevealed = false;
        }
      } else if (chNum === 4) {
        if (tool === 'f:p-') st.guessP -= 1;
        if (tool === 'f:p+') st.guessP += 1;
        if (tool === 'f:q-') st.guessQ -= 1;
        if (tool === 'f:q+') st.guessQ += 1;
        if (tool === 'f:next') {
          st.factorPuzzleIdx = (st.factorPuzzleIdx + 1) % CH04_PUZZLES.length;
          st.guessP = 1;
          st.guessQ = 1;
        }
        SoundEngine.playDetent(1);
      } else if (chNum === 5) {
        const before = evalCh05(st);
        const prevZeroPairs = st.zeroPairsCleared;
        const side = st.symLock ? 'both' : 'left';
        if (tool === 'op:addX') applyCh05Op(st, side, 'x', 1);
        else if (tool === 'op:subX') applyCh05Op(st, side, 'x', -1);
        else if (tool === 'op:add1') applyCh05Op(st, side, 'ones', 1);
        else if (tool === 'op:sub1') applyCh05Op(st, side, 'ones', -1);
        else if (tool === 'op:div2') applyCh05Op(st, side, 'div', 2);
        else if (tool === 'op:div3') applyCh05Op(st, side, 'div', 3);
        else if (tool === 'op:neg1') applyCh05Op(st, side, 'mul', -1);
        else if (tool === 'toggle:sym') st.symLock = !st.symLock;
        else if (tool === 'op:undo') undoCh05(st);
        else if (tool === 'op:nextPuz') LAB_REGISTRY[5] = createCh05State((st.puzzleIdx + 1) % CH05_PUZZLES.length);
        const curSt = getOrCreateLabState(5);
        const after = evalCh05(curSt);
        if (tool !== 'op:nextPuz' && curSt.zeroPairsCleared > prevZeroPairs && !after.isolated) SoundEngine.playZeroPairPop();
        if (after.isolated) SoundEngine.playLevelChime();
        else if (!after.balanced && before.balanced) SoundEngine.playTiltKnock(after.diff);
      } else if (chNum === 7) {
        const ev = evalCh07(st);
        if (tool === 'g:pin' && !ev.vertical) { st.ghost = { m: ev.m, c: ev.c }; SoundEngine.playBoop(3); }
        else if (tool === 'g:clearGhost') st.ghost = null;
        else if (tool === 'g:probe') st.probeActive = !st.probeActive;
        else if (tool === 'm:swap') { const tmp = st.op1; st.op1 = st.op2; st.op2 = tmp; SoundEngine.playBoop(1); }
        else if (tool === 'm:cycle1') {
          const idx = CH07_OPS.findIndex(o => o.id === st.op1);
          st.op1 = CH07_OPS[(idx + 1) % CH07_OPS.length].id;
        } else if (tool === 'm:cycle2') {
          const idx = CH07_OPS.findIndex(o => o.id === st.op2);
          st.op2 = CH07_OPS[(idx + 1) % CH07_OPS.length].id;
        } else if (tool === 'm:mystery') {
          st.mysteryMode = !st.mysteryMode;
          st.mysteryRevealed = false;
        } else if (tool === 'm:reveal') {
          st.mysteryRevealed = true;
          SoundEngine.playLevelChime();
        }
      } else if (chNum === 13) {
        if (tool === 's:1') { drawSamplesCh13(st, 1); SoundEngine.playBoop(1); }
        else if (tool === 's:5') { drawSamplesCh13(st, 5); SoundEngine.playBoop(3); }
        else if (tool === 's:15') { drawSamplesCh13(st, 15); SoundEngine.playBoop(5); }
        else if (tool === 's:n4') { st.sampleN = 4; st.samples = []; }
        else if (tool === 's:n16') { st.sampleN = 16; st.samples = []; }
      } else if (chNum === 14) {
        if (tool === 'd:kick1') {
          if (st.dots.length < 14) st.dots.push(clamp(Math.round(7 + 3 * st.rng.normal()), 1, 18));
          SoundEngine.playBoop(1);
        } else if (tool === 'd:sort') {
          st.sorted = !st.sorted;
          if (st.sorted) st.dots.sort((a, b) => a - b);
          SoundEngine.playDetent(1);
        } else if (tool === 'd:reveal') {
          st.revealedCenter = !st.revealedCenter;
          SoundEngine.playLevelChime();
        } else if (tool === 'd:outlier') {
          const maxIdx = st.dots.reduce((best, v, i, arr) => v >= arr[best] ? i : best, 0);
          st.dots[maxIdx] = 19;
          SoundEngine.playTiltKnock(4);
        } else if (tool === 'bf:reveal') {
          st.showBestFit = !st.showBestFit;
          SoundEngine.playLevelChime();
        }
      } else if (chNum === 17 || chNum === 18) {
        if (tool.startsWith('c:') && tool !== 'c:reveal') {
          st.curveKind = tool.slice(2);
          st.predictRevealed = false;
          SoundEngine.playDetent(1);
        } else if (tool === 'c:reveal') {
          st.predictRevealed = !st.predictRevealed;
          SoundEngine.playLevelChime();
        }
      }
      renderChapterToolbar(chNum);
      if (typeof window.drawSandbox === 'function') window.drawSandbox();
    }

    function configureCanvasContext() {
      const canvas = document.getElementById('sim-canvas');
      if (!canvas) return null;
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const cssW = canvas.clientWidth || 560;
      const cssH = canvas.clientHeight || 290;
      if (canvas.width !== Math.round(cssW * dpr) || canvas.height !== Math.round(cssH * dpr)) {
        canvas.width = Math.round(cssW * dpr);
        canvas.height = Math.round(cssH * dpr);
      }
      const ctx = canvas.getContext('2d');
      ctx.save();
      ctx.scale(dpr, dpr);
      ctx.clearRect(0, 0, cssW, cssH);
      ctx.font = '600 12.5px -apple-system, BlinkMacSystemFont, sans-serif';
      return { canvas, ctx, w: cssW, h: cssH };
    }

    function shouldUseCustomCanvas(chNum, st) {
      if (chNum === 1 && st.mode !== 'classic-turns') return true;
      if (chNum === 2 && st.mode === 'double-line') return true;
      if (chNum === 3 && st.mode !== 'compound-growth') return true;
      if (chNum === 4 || chNum === 5 || chNum === 7 || chNum === 17 || chNum === 18) return true;
      if (chNum === 13 && st.mode === 'live-sampler') return true;
      if (chNum === 14 && st.mode !== 'histogram') return true;
      return false;
    }

    // Store drag handles in canvas coordinates for direct hit-testing.
    let activeHandles = [];

    function drawCustomChapter(chNum, st, params) {
      const box = configureCanvasContext();
      if (!box) return null;
      const { ctx, w, h } = box;
      const C = getThemeColors();
      activeHandles = [];
      let readoutHtml = '';
      let evalData = {};

      if (chNum === 1) {
        evalData = evalCh01(st);
        const yLine = 135;
        const x0 = 48;
        const x1 = w - 48;
        const toX = v => x0 + ((v + 10) / 20) * (x1 - x0);
        const fromX = px => clamp(Math.round(((px - x0) / (x1 - x0)) * 20 - 10), -10, 10);

        ctx.strokeStyle = C.muted;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x0, yLine);
        ctx.lineTo(x1, yLine);
        ctx.stroke();

        for (let t = -10; t <= 10; t += 2) {
          const tx = toX(t);
          ctx.strokeStyle = t === 0 ? C.ink : C.muted;
          ctx.lineWidth = t === 0 ? 2 : 1;
          ctx.beginPath();
          ctx.moveTo(tx, yLine - (t === 0 ? 10 : 5));
          ctx.lineTo(tx, yLine + (t === 0 ? 10 : 5));
          ctx.stroke();
          ctx.fillStyle = t === 0 ? C.ink : C.muted;
          ctx.fillText(fmtNum(t), tx - 6, yLine + 24);
        }

        const ax = toX(st.a);
        const bx = toX(st.b);
        const spanCol = st.mode === 'distance' ? C.amber : (evalData.directed >= 0 ? C.green : C.red);
        ctx.strokeStyle = spanCol;
        ctx.lineWidth = 4;
        ctx.beginPath();
        ctx.moveTo(ax, yLine - 34);
        ctx.lineTo(bx, yLine - 34);
        ctx.stroke();
        ctx.fillStyle = spanCol;
        const unitLabel = st.context === 'temp' ? '°C' : (st.context === 'money' ? ' ₹' : '');
        const metricLabel = st.mode === 'distance'
          ? `|B − A| = ${fmtNum(evalData.distance)}${unitLabel}`
          : `B − A = ${evalData.directed > 0 ? '+' : ''}${fmtNum(evalData.directed)}${unitLabel}`;
        ctx.fillText(metricLabel, (ax + bx) / 2 - 36, yLine - 46);

        [{ key: 'a', x: ax, col: C.blue, lbl: `A=${fmtNum(st.a)}` },
         { key: 'b', x: bx, col: C.red, lbl: `B=${fmtNum(st.b)}` }].forEach(pt => {
          ctx.fillStyle = pt.col;
          ctx.beginPath();
          ctx.arc(pt.x, yLine, 9, 0, Math.PI * 2);
          ctx.fill();
          ctx.fillText(pt.lbl, pt.x - 16, yLine - 15);
          activeHandles.push({
            id: pt.key,
            x: pt.x,
            y: yLine,
            r: 22,
            onDrag(px) { st[pt.key] = fromX(px); SoundEngine.playDetent(st[pt.key]); }
          });
        });

        ctx.fillStyle = C.muted;
        ctx.fillText('Drag A or B along the line', 48, 36);
        readoutHtml = `Start <b>A = ${fmtNum(st.a)}${unitLabel}</b> · End <b>B = ${fmtNum(st.b)}${unitLabel}</b> · Directed <b>${fmtNum(evalData.directed)}</b> · Distance <b>${fmtNum(evalData.distance)}</b>`;
      } else if (chNum === 2) {
        evalData = evalCh02(st);
        const x0 = 56;
        const x1 = w - 48;
        const yTop = 92;
        const yBot = 172;
        const maxBottom = 6;
        const toX = u => x0 + (u / maxBottom) * (x1 - x0);
        const fromX = px => clamp(roundTo(((px - x0) / (x1 - x0)) * maxBottom, 1), 0.5, maxBottom);

        ctx.strokeStyle = C.red;
        ctx.lineWidth = 2.5;
        ctx.beginPath(); ctx.moveTo(x0, yTop); ctx.lineTo(x1, yTop); ctx.stroke();
        ctx.strokeStyle = C.blue;
        ctx.beginPath(); ctx.moveTo(x0, yBot); ctx.lineTo(x1, yBot); ctx.stroke();

        for (let i = 0; i <= maxBottom; i++) {
          const tx = toX(i);
          ctx.strokeStyle = C.muted;
          ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(tx, yTop - 6); ctx.lineTo(tx, yBot + 6); ctx.stroke();
          ctx.fillStyle = C.red;
          ctx.fillText(fmtNum(roundTo(evalData.unitRatio * i, 2)), tx - 8, yTop - 14);
          ctx.fillStyle = C.blue;
          ctx.fillText(String(i), tx - 4, yBot + 22);
        }

        const px = toX(st.probeScale);
        ctx.strokeStyle = C.amber;
        ctx.lineWidth = 3;
        ctx.beginPath(); ctx.moveTo(px, yTop - 10); ctx.lineTo(px, yBot + 10); ctx.stroke();
        ctx.fillStyle = C.amber;
        ctx.beginPath(); ctx.arc(px, yBot, 9, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = C.ink;
        ctx.fillText(`Scale ${fmtNum(st.probeScale)}× → ${fmtNum(evalData.topAtProbe)} : ${fmtNum(st.probeScale)}`, x0, 232);
        if (Math.abs(st.probeScale - 5) < 0.15) st.goalDone = true;

        activeHandles.push({
          id: 'probe',
          x: px,
          y: yBot,
          r: 22,
          onDrag(nx) {
            st.probeScale = Math.round(fromX(nx) * 2) / 2;
            SoundEngine.playDetent(1);
          }
        });
        readoutHtml = `Unit rate (at 1) = <b>${fmtNum(evalData.unitRatio)}</b> · At ${fmtNum(st.probeScale)} units → <b>${fmtNum(evalData.topAtProbe)}</b>`;
      } else if (chNum === 3) {
        evalData = evalCh03(st);
        if (st.mode === 'ratio-tuner') {
          const yBot = 248;
          const yTop = 44;
          const maxV = 12;
          const lx = 140;
          const rx = 280;
          const toY = v => yBot - (v / maxV) * (yBot - yTop);
          const fromY = py => clamp(roundTo(((yBot - py) / (yBot - yTop)) * maxV, 1), 0.5, maxV);

          [lx, rx].forEach((tx, idx) => {
            ctx.strokeStyle = C.muted;
            ctx.lineWidth = 2;
            ctx.beginPath(); ctx.moveTo(tx, yBot); ctx.lineTo(tx, yTop); ctx.stroke();
            if (st.tickMode !== 'none') {
              for (let t = 0; t <= maxV; t += 2) {
                const ty = toY(t);
                ctx.beginPath(); ctx.moveTo(tx - 6, ty); ctx.lineTo(tx + 6, ty); ctx.stroke();
                if (st.tickMode === 'numbered') {
                  ctx.fillStyle = C.muted;
                  ctx.fillText(String(t), idx === 0 ? tx - 26 : tx + 12, ty + 4);
                }
              }
            }
          });

          const ly = toY(st.left);
          const ry = toY(st.right);
          const lineCol = evalData.inProportion ? C.green : C.amber;
          ctx.strokeStyle = lineCol;
          ctx.lineWidth = 3;
          ctx.beginPath(); ctx.moveTo(lx, ly); ctx.lineTo(rx, ry); ctx.stroke();

          const drawHand = (key, x, y, val, col) => {
            ctx.fillStyle = col;
            ctx.beginPath(); ctx.arc(x, y, 11, 0, Math.PI * 2); ctx.fill();
            ctx.fillStyle = C.card;
            ctx.fillText(key === 'left' ? 'L' : 'R', x - 4, y + 4);
            ctx.fillStyle = col;
            ctx.fillText(fmtNum(val), x - 10, y - 16);
            activeHandles.push({
              id: key,
              x,
              y,
              r: 24,
              onDrag(_, py) {
                const nv = fromY(py);
                if (st.ratioLocked) {
                  if (key === 'left') {
                    st.left = nv;
                    st.right = clamp(roundTo(nv / st.lockedRatio, 2), 0.5, maxV);
                  } else {
                    st.right = nv;
                    st.left = clamp(roundTo(nv * st.lockedRatio, 2), 0.5, maxV);
                  }
                  if (st.left > 3.1) st.movedWhileInTune = true;
                } else {
                  st[key] = nv;
                }
                const ev2 = evalCh03(st);
                SoundEngine.playDetunedBeat(ev2.relError, 261.63);
              }
            });
          };

          drawHand('left', lx, ly, st.left, C.red);
          drawHand('right', rx, ry, st.right, C.blue);

          ctx.fillStyle = evalData.inProportion ? C.green : C.ink;
          ctx.fillText(evalData.inProportion ? 'IN PROPORTION!' : 'Not matching target yet', 340, 100);
          ctx.fillStyle = C.muted;
          ctx.fillText(`Target ratio: ${st.targetLeft} : ${st.targetRight}`, 340, 128);
          ctx.fillText(`Now: ${fmtNum(st.left)} : ${fmtNum(st.right)}`, 340, 152);
          ctx.fillText('Drag both hands (two fingers on iPad)', 340, 184);
          readoutHtml = `Left = <b>${fmtNum(st.left)}</b> · Right = <b>${fmtNum(st.right)}</b> · Target <b>${st.targetLeft}:${st.targetRight}</b> · ${evalData.inProportion ? `<b style="color:${C.green}">In tune!</b>` : 'Adjust to tune'}`;
        } else {
          // Compare & Predict Blind mode
          const barW = 24;
          const drawStack = (x, partsA, partsB, label, hidden) => {
            ctx.fillStyle = C.ink;
            ctx.fillText(label, x, 38);
            if (hidden) {
              ctx.fillStyle = C.elevated;
              ctx.strokeStyle = C.muted;
              ctx.fillRect(x, 54, 120, 160);
              ctx.strokeRect(x, 54, 120, 160);
              ctx.fillStyle = C.muted;
              ctx.fillText('Predict first!', x + 18, 138);
              return;
            }
            for (let i = 0; i < Math.min(10, partsA); i++) {
              ctx.fillStyle = C.red + '44'; ctx.strokeStyle = C.red;
              ctx.fillRect(x + i * 20, 74, 18, barW); ctx.strokeRect(x + i * 20, 74, 18, barW);
            }
            for (let i = 0; i < Math.min(10, partsB); i++) {
              ctx.fillStyle = C.blue + '44'; ctx.strokeStyle = C.blue;
              ctx.fillRect(x + i * 20, 114, 18, barW); ctx.strokeRect(x + i * 20, 114, 18, barW);
            }
            ctx.fillStyle = C.muted;
            ctx.fillText(`${partsA} red : ${partsB} blue`, x, 164);
          };
          drawStack(48, st.compareTargetLeft, st.compareTargetRight, 'Tray A', false);
          drawStack(300, st.compareUserLeft, st.compareUserRight, 'Tray B', !st.compareRevealed);
          if (st.compareRevealed) {
            ctx.fillStyle = evalData.actualSame ? C.green : C.red;
            const verdict = evalData.actualSame ? 'Same ratio (multiplied equally)!' : 'Different ratio (+2/+2 broke it!)';
            const predNote = st.comparePrediction ? (evalData.goalReached ? ' Spot on!' : ' Check the unit ratio.') : '';
            ctx.fillText(verdict + predNote, 48, 224);
          }
          readoutHtml = `Tray A = <b>${st.compareTargetLeft}:${st.compareTargetRight}</b> · Tray B = <b>${st.compareUserLeft}:${st.compareUserRight}</b>`
            + (st.compareRevealed && st.comparePrediction ? (evalData.goalReached ? ' · <b>Prediction matched!</b>' : ' · Compare unit rates') : '');
        }
      } else if (chNum === 4) {
        const x0 = 66;
        const y0 = 42;
        if (st.mode === 'area-scale') {
          st.p = Math.max(1, Math.round(st.p));
          st.q = Math.max(1, Math.round(st.q));
          st.x = Math.max(1, Math.round(st.x));
          evalData = evalCh04(st);
          const u = 16;
          const x = evalData.x;
          const p = evalData.p;
          const q = evalData.q;
          const polyTxt = formatSignedPoly(evalData.linearSum, evalData.pq);
          const drawBox = (bx, by, bw, bh, col, txt) => {
            ctx.fillStyle = col + '2E'; ctx.strokeStyle = col; ctx.lineWidth = 2;
            ctx.fillRect(bx, by, bw, bh); ctx.strokeRect(bx, by, bw, bh);
            ctx.fillStyle = col;
            ctx.fillText(txt, bx + bw / 2 - 14, by + bh / 2 + 4);
          };
          drawBox(x0, y0, x * u, x * u, C.red, 'x²');
          drawBox(x0 + x * u, y0, p * u, x * u, C.blue, `${p}x`);
          drawBox(x0, y0 + x * u, x * u, q * u, C.blue, `${q}x`);
          drawBox(x0 + x * u, y0 + x * u, p * u, q * u, C.amber, `${p * q}`);
          ctx.fillStyle = C.ink;
          ctx.fillText(`(x + ${p})(x + ${q}) = ${polyTxt}`, 290, 90);
          ctx.fillStyle = C.muted;
          ctx.fillText(`At x = ${x}: ${evalData.x2} + ${evalData.px} + ${evalData.qx} + ${evalData.pq} = ${evalData.total}`, 290, 122);
          readoutHtml = `(x + ${p})(x + ${q}) = <b>${polyTxt}</b> (at x=${x}: area = <b>${evalData.total}</b>)`;
        } else {
          // Generic (allows negative p, q!) or Factor-It reverse puzzle — state owns p and q cleanly
          evalData = evalCh04(st);
          const isFactor = st.mode === 'area-factor';
          const pVal = isFactor ? evalData.puzzle.targetP : evalData.p;
          const qVal = isFactor ? evalData.puzzle.targetQ : evalData.q;
          const showP = isFactor ? st.guessP : pVal;
          const showQ = isFactor ? st.guessQ : qVal;
          const bw = 96;
          const bh = 74;
          const cell = (colIdx, rowIdx, col, lbl) => {
            const bx = x0 + colIdx * bw;
            const by = y0 + rowIdx * bh;
            ctx.fillStyle = col + '2A'; ctx.strokeStyle = col; ctx.lineWidth = 2;
            ctx.fillRect(bx, by, bw, bh); ctx.strokeRect(bx, by, bw, bh);
            ctx.fillStyle = col;
            ctx.fillText(lbl, bx + 20, by + 42);
          };
          cell(0, 0, C.red, 'x²');
          cell(1, 0, C.blue, `${pVal >= 0 ? '+' : '−'}${Math.abs(pVal)}x`);
          cell(0, 1, C.blue, `${qVal >= 0 ? '+' : '−'}${Math.abs(qVal)}x`);
          cell(1, 1, C.amber, `${pVal * qVal >= 0 ? '+' : '−'}${Math.abs(pVal * qVal)}`);

          ctx.fillStyle = isFactor ? (evalData.factorSolved ? C.green : C.red) : C.ink;
          ctx.fillText('x', x0 + bw / 2 - 4, y0 - 12);
          ctx.fillText(showP >= 0 ? `+ ${showP}` : `− ${Math.abs(showP)}`, x0 + bw * 1.4, y0 - 12);
          ctx.fillText('x', x0 - 18, y0 + bh / 2);
          ctx.fillText(showQ >= 0 ? `+ ${showQ}` : `− ${Math.abs(showQ)}`, x0 - 34, y0 + bh * 1.5);

          ctx.fillStyle = C.ink;
          if (isFactor) {
            ctx.fillText(`Target inside: ${evalData.puzzle.label}`, 290, 76);
            ctx.fillText(`Your factors: (x ${showP >= 0 ? '+' : '−'} ${Math.abs(showP)})(x ${showQ >= 0 ? '+' : '−'} ${Math.abs(showQ)})`, 290, 108);
            ctx.fillStyle = evalData.factorSolved ? C.green : C.amber;
            ctx.fillText(evalData.factorSolved ? 'Matched all 4 partial products!' : 'Use p± and q± buttons to match edges', 290, 142);
            readoutHtml = `Factoring <b>${evalData.puzzle.label}</b> · Your edges: <b>(x ${showP >= 0 ? '+' : '−'} ${Math.abs(showP)})(x ${showQ >= 0 ? '+' : '−'} ${Math.abs(showQ)})</b>`;
          } else {
            const sum = evalData.linearSum;
            const polyTxt = formatSignedPoly(sum, evalData.pq);
            ctx.fillText(`Generic Box: (x ${pVal >= 0 ? '+' : '−'} ${Math.abs(pVal)})(x ${qVal >= 0 ? '+' : '−'} ${Math.abs(qVal)})`, 290, 82);
            ctx.fillStyle = sum === 0 ? C.green : C.blue;
            ctx.fillText(sum === 0 ? 'Middle x-terms cancel to 0!' : `Middle sum: ${fmtNum(sum)}x`, 290, 114);
            readoutHtml = `Generic Box: <b>${polyTxt}</b>`;
          }
        }
      } else if (chNum === 5) {
        evalData = evalCh05(st);
        const cx = w * 0.5;
        const pivY = 178;
        ctx.save();
        ctx.translate(cx, pivY);
        ctx.rotate(evalData.tiltRad);

        // Beam arm & fulcrum
        ctx.strokeStyle = C.ink;
        ctx.lineWidth = 4;
        ctx.beginPath(); ctx.moveTo(-185, 0); ctx.lineTo(185, 0); ctx.stroke();

        // Left pan & Right pan
        const drawPan = (panX, xCnt, onesCnt, label) => {
          ctx.strokeStyle = C.muted;
          ctx.lineWidth = 2;
          ctx.strokeRect(panX - 72, -88, 144, 78);
          ctx.fillStyle = C.muted;
          ctx.fillText(label, panX - 30, -96);

          // Draw x blocks
          for (let i = 0; i < Math.min(6, Math.abs(xCnt)); i++) {
            const bx = panX - 64 + i * 22;
            const col = xCnt >= 0 ? C.red : C.amber;
            ctx.fillStyle = col + '38'; ctx.strokeStyle = col; ctx.lineWidth = 1.8;
            ctx.fillRect(bx, -80, 18, 28); ctx.strokeRect(bx, -80, 18, 28);
            ctx.fillStyle = col;
            ctx.fillText(xCnt >= 0 ? '+x' : '−x', bx + 2, -62);
          }
          // Draw unit discs
          const unitsShown = Math.min(12, Math.abs(onesCnt));
          for (let i = 0; i < unitsShown; i++) {
            const ux = panX - 58 + (i % 6) * 20;
            const uy = -34 + Math.floor(i / 6) * 16;
            const col = onesCnt >= 0 ? C.blue : C.amber;
            ctx.fillStyle = col;
            ctx.beginPath(); ctx.arc(ux, uy, 6, 0, Math.PI * 2); ctx.fill();
          }
          if (Math.abs(onesCnt) > 12) {
            ctx.fillStyle = C.blue;
            ctx.fillText(`(${fmtNum(onesCnt)})`, panX + 20, -24);
          }
        };

        drawPan(-125, st.leftX, st.leftOnes, formatPanExpr(st.leftX, st.leftOnes));
        drawPan(125, st.rightX, st.rightOnes, formatPanExpr(st.rightX, st.rightOnes));
        ctx.restore();

        // Static fulcrum triangle
        ctx.fillStyle = C.amber;
        ctx.beginPath();
        ctx.moveTo(cx, pivY + 2);
        ctx.lineTo(cx - 18, pivY + 34);
        ctx.lineTo(cx + 18, pivY + 34);
        ctx.closePath();
        ctx.fill();

        const eqSign = evalData.balanced ? '=' : (evalData.diff > 0 ? '>' : '<');
        ctx.fillStyle = evalData.isolated ? C.green : C.ink;
        ctx.fillText(`${formatPanExpr(st.leftX, st.leftOnes)}  ${eqSign}  ${formatPanExpr(st.rightX, st.rightOnes)}`, 40, 34);
        ctx.fillStyle = C.muted;
        ctx.fillText(st.lastMoveLabel, 40, 248);
        if (evalData.isolated) {
          ctx.fillStyle = C.green;
          ctx.fillText(`Isolated! x = ${evalData.solvedValue}`, w - 165, 34);
          readoutHtml = `<b>Solved! x = ${evalData.solvedValue}</b> · ${st.lastMoveLabel}`;
        } else {
          readoutHtml = `<b>${formatPanExpr(st.leftX, st.leftOnes)} ${eqSign} ${formatPanExpr(st.rightX, st.rightOnes)}</b> · ${evalData.balanced ? 'Balanced' : 'Tilted'} · Lock ${st.symLock ? 'On' : 'Off'}`;
        }
      } else if (chNum === 7) {
        evalData = evalCh07(st);
        if (st.mode === 'graph-probe') {
          const ox = 175;
          const oy = 152;
          const sc = 22;
          const toX = x => ox + x * sc;
          const toY = y => oy - y * sc;
          const fromX = px => clamp(Math.round(((px - ox) / sc) * 2) / 2, -6, 6);
          const fromY = py => clamp(Math.round(((oy - py) / sc) * 2) / 2, -5, 5);

          // Grid
          ctx.strokeStyle = C.ink + '18';
          ctx.lineWidth = 1;
          for (let i = -6; i <= 6; i++) {
            ctx.beginPath(); ctx.moveTo(toX(i), 20); ctx.lineTo(toX(i), h - 20); ctx.stroke();
          }
          for (let j = -5; j <= 5; j++) {
            ctx.beginPath(); ctx.moveTo(35, toY(j)); ctx.lineTo(315, toY(j)); ctx.stroke();
          }
          ctx.strokeStyle = C.muted;
          ctx.lineWidth = 1.5;
          ctx.beginPath(); ctx.moveTo(35, oy); ctx.lineTo(315, oy); ctx.moveTo(ox, 20); ctx.lineTo(ox, h - 20); ctx.stroke();

          // Pinned ghost line
          if (st.ghost) {
            ctx.save();
            ctx.strokeStyle = C.amber;
            ctx.setLineDash([6, 4]);
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(toX(-6), toY(-6 * st.ghost.m + st.ghost.c));
            ctx.lineTo(toX(6), toY(6 * st.ghost.m + st.ghost.c));
            ctx.stroke();
            ctx.restore();
          }

          // Active line
          ctx.strokeStyle = C.blue;
          ctx.lineWidth = 2.6;
          ctx.beginPath();
          if (evalData.vertical) {
            ctx.moveTo(toX(st.p1.x), 20);
            ctx.lineTo(toX(st.p1.x), h - 20);
          } else {
            ctx.moveTo(toX(-6), toY(-6 * evalData.m + evalData.c));
            ctx.lineTo(toX(6), toY(6 * evalData.m + evalData.c));
          }
          ctx.stroke();

          // Draggable points p1 & p2
          [{ key: 'p1', pt: st.p1, col: C.green }, { key: 'p2', pt: st.p2, col: C.red }].forEach(item => {
            const px = toX(item.pt.x);
            const py = toY(item.pt.y);
            ctx.fillStyle = item.col;
            ctx.beginPath(); ctx.arc(px, py, 7.5, 0, Math.PI * 2); ctx.fill();
            activeHandles.push({
              id: item.key,
              x: px,
              y: py,
              r: 20,
              onDrag(nx, ny) {
                st[item.key] = { x: fromX(nx), y: fromY(ny) };
                const ev2 = evalCh07(st);
                if (ev2.isPerpGhost) SoundEngine.playLevelChime();
              }
            });
          });

          // Point Probe tool
          if (st.probeActive) {
            const prX = toX(st.probe.x);
            const prY = toY(st.probe.y);
            ctx.strokeStyle = evalData.probeOnLine ? C.green : C.amber;
            ctx.lineWidth = 2;
            ctx.beginPath(); ctx.arc(prX, prY, 10, 0, Math.PI * 2); ctx.stroke();
            ctx.fillStyle = evalData.probeOnLine ? C.green : C.amber;
            ctx.fillText(`(${fmtNum(st.probe.x)}, ${fmtNum(st.probe.y)})`, prX + 12, prY - 6);
            activeHandles.push({
              id: 'probe',
              x: prX,
              y: prY,
              r: 22,
              onDrag(nx, ny) {
                st.probe = { x: fromX(nx), y: fromY(ny) };
                if (evalCh07(st).probeOnLine) SoundEngine.playBoop(4);
              }
            });
          }

          ctx.fillStyle = C.blue;
          ctx.fillText(evalData.vertical ? `x = ${fmtNum(st.p1.x)}` : `y = ${fmtNum(evalData.m)}x + ${fmtNum(evalData.c)}`, 335, 76);
          if (st.ghost) {
            ctx.fillStyle = evalData.isPerpGhost ? C.green : (evalData.isParallelGhost ? C.blue : C.amber);
            const relTxt = evalData.isPerpGhost ? 'Perpendicular (m₁·m₂ = −1)!' : (evalData.isParallelGhost ? 'Parallel (m₁ = m₂)!' : `Ghost m = ${fmtNum(st.ghost.m)}`);
            ctx.fillText(relTxt, 335, 112);
          }
          readoutHtml = `${evalData.vertical ? `x = ${fmtNum(st.p1.x)}` : `<b>y = ${fmtNum(evalData.m)}x + ${fmtNum(evalData.c)}</b>`} · Probe (${fmtNum(st.probe.x)}, ${fmtNum(st.probe.y)}) ${evalData.probeOnLine ? 'on line' : 'off line'}`;
        } else {
          // Rule Machine (Function Builder) — state owns st.testInput cleanly
          const shownIds = st.mysteryMode && st.mysteryRevealed ? st.mysterySecret : [st.op1, st.op2];
          const op1Obj = CH07_OPS.find(o => o.id === shownIds[0]) || CH07_OPS[0];
          const op2Obj = CH07_OPS.find(o => o.id === shownIds[1]) || CH07_OPS[0];
          const xIn = Math.round(clamp(st.testInput, -4, 8));
          const ev = evalCh07(st);

          ctx.fillStyle = C.blue;
          ctx.fillText(`Input: ${xIn}`, 48, 128);
          ctx.strokeStyle = C.ink; ctx.lineWidth = 2;
          ctx.strokeRect(145, 86, 95, 68);
          ctx.strokeRect(270, 86, 95, 68);

          if (st.mysteryMode && !st.mysteryRevealed) {
            ctx.fillStyle = C.elevated;
            ctx.fillRect(145, 86, 220, 68);
            ctx.strokeStyle = C.amber;
            ctx.strokeRect(145, 86, 220, 68);
            ctx.fillStyle = C.amber;
            ctx.fillText('Mystery shutter (hidden)', 176, 124);
          } else {
            ctx.fillStyle = C.red;
            ctx.fillText(op1Obj.label, 178, 124);
            ctx.fillStyle = C.blue;
            ctx.fillText(op2Obj.label, 304, 124);
          }
          ctx.fillStyle = C.green;
          ctx.fillText(`Output: ${fmtNum(ev.outVal)}`, 392, 128);
          ctx.fillStyle = C.muted;
          ctx.fillText('Move slider 1 or drag Input chip to drop numbers through.', 48, 206);
          const secretSuffix = st.mysteryMode
            ? (st.mysteryRevealed ? ` · Hidden rule: ${op1Obj.label} then ${op2Obj.label}` : ' (guess the two hidden blocks!)')
            : '';
          readoutHtml = `Input <b>${xIn}</b> → Output <b>${fmtNum(ev.outVal)}</b>${secretSuffix}`;
        }
      } else if (chNum === 13) {
        evalData = evalCh13(st);
        const yBase = 225;
        const x0 = 56;
        const x1 = w - 48;
        const toX = v => x0 + ((v - 30) / 40) * (x1 - x0);
        ctx.strokeStyle = C.muted; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.moveTo(x0, yBase); ctx.lineTo(x1, yBase); ctx.stroke();
        for (let t = 35; t <= 65; t += 5) {
          ctx.fillStyle = C.muted;
          ctx.fillText(String(t), toX(t) - 6, yBase + 18);
        }
        // Bins for sample means
        const bins = new Map();
        st.samples.forEach(s => {
          const b = Math.round(s * 1) / 1;
          bins.set(b, (bins.get(b) || 0) + 1);
        });
        bins.forEach((cnt, bVal) => {
          const px = toX(bVal);
          for (let j = 0; j < Math.min(12, cnt); j++) {
            ctx.fillStyle = C.blue;
            ctx.beginPath(); ctx.arc(px, yBase - 10 - j * 13, 5, 0, Math.PI * 2); ctx.fill();
          }
        });
        ctx.fillStyle = C.red;
        ctx.fillText(`Samples: ${evalData.count} (n = ${st.sampleN})`, 56, 40);
        ctx.fillStyle = C.amber;
        ctx.fillText(`Expected SE = σ / √n = ${fmtNum(evalData.theoreticalSE)}`, 56, 64);
        readoutHtml = `Samples = <b>${evalData.count}</b> (n=${st.sampleN}) · Theoretical SE = <b>${fmtNum(evalData.theoreticalSE)}</b> · Observed spread = <b>${fmtNum(evalData.observedSE)}</b>`;
      } else if (chNum === 14) {
        evalData = evalCh14(st);
        if (st.mode === 'mean-balance' || st.mode === 'level-out') {
          const x0 = 54;
          const x1 = w - 44;
          const yAxis = 186;
          const toX = v => x0 + (v / 20) * (x1 - x0);
          const fromX = px => clamp(Math.round(((px - x0) / (x1 - x0)) * 20), 0, 20);

          if (st.mode === 'level-out') {
            const bw = (x1 - x0) / Math.max(1, st.dots.length) - 6;
            st.dots.forEach((val, idx) => {
              const bx = x0 + idx * (bw + 6);
              const bh = val * 7;
              ctx.fillStyle = C.blue + '36'; ctx.strokeStyle = C.blue; ctx.lineWidth = 2;
              ctx.fillRect(bx, yAxis - bh, bw, bh); ctx.strokeRect(bx, yAxis - bh, bw, bh);
              ctx.fillStyle = C.ink;
              ctx.fillText(String(val), bx + bw / 2 - 5, yAxis + 16);
            });
            const meanY = yAxis - evalData.meanVal * 7;
            ctx.strokeStyle = C.amber; ctx.lineWidth = 2.5;
            ctx.beginPath(); ctx.moveTo(x0, meanY); ctx.lineTo(x1, meanY); ctx.stroke();
            ctx.fillStyle = C.amber;
            ctx.fillText(`Level-out height (Mean) = ${fmtNum(evalData.meanVal)}`, x0, 38);
            readoutHtml = `Total = ${evalData.totalSum} across ${st.dots.length} bars · Levelled Mean = <b>${fmtNum(evalData.meanVal)}</b>`;
          } else {
            // Balance beam + draggable dots + Predict arrow + Fulcrum
            const tilt = clamp(evalData.torque / 45, -0.22, 0.22);
            ctx.strokeStyle = C.ink; ctx.lineWidth = 2;
            ctx.beginPath(); ctx.moveTo(x0, yAxis); ctx.lineTo(x1, yAxis); ctx.stroke();
            for (let t = 0; t <= 20; t += 2) {
              const tx = toX(t);
              ctx.fillStyle = C.muted;
              ctx.fillText(String(t), tx - 5, yAxis + 22);
            }

            const counts = new Map();
            st.dots.forEach((v, idx) => {
              const stack = counts.get(v) || 0;
              counts.set(v, stack + 1);
              const px = toX(v);
              const py = yAxis - 14 - stack * 18;
              ctx.fillStyle = C.blue;
              ctx.beginPath(); ctx.arc(px, py, 7, 0, Math.PI * 2); ctx.fill();
              activeHandles.push({
                id: `dot-${idx}`,
                x: px,
                y: py,
                r: 18,
                onDrag(nx) {
                  st.dots[idx] = fromX(nx);
                  if (evalCh14(st).fulcrumBalanced) SoundEngine.playLevelChime();
                }
              });
            });

            // Draggable Fulcrum triangle
            const fx = toX(st.fulcrumX);
            ctx.fillStyle = evalData.fulcrumBalanced ? C.green : C.amber;
            ctx.beginPath();
            ctx.moveTo(fx, yAxis + 2);
            ctx.lineTo(fx - 13, yAxis + 28);
            ctx.lineTo(fx + 13, yAxis + 28);
            ctx.closePath();
            ctx.fill();
            activeHandles.push({
              id: 'fulcrum',
              x: fx,
              y: yAxis + 14,
              r: 22,
              onDrag(nx) {
                st.fulcrumX = clamp(roundTo(((nx - x0) / (x1 - x0)) * 20, 1), 0, 20);
                if (evalCh14(st).fulcrumBalanced) SoundEngine.playLevelChime();
              }
            });

            // Predict pointer
            const prx = toX(st.predictVal);
            ctx.strokeStyle = C.red; ctx.lineWidth = 2;
            ctx.beginPath(); ctx.moveTo(prx, 52); ctx.lineTo(prx, 86); ctx.stroke();
            ctx.fillStyle = C.red;
            ctx.fillText(`Predict: ${fmtNum(st.predictVal)}`, prx - 24, 44);
            activeHandles.push({
              id: 'predict',
              x: prx,
              y: 66,
              r: 20,
              onDrag(nx) { st.predictVal = fromX(nx); }
            });

            if (st.revealedCenter) {
              ctx.fillStyle = C.green;
              ctx.fillText(`Mean = ${fmtNum(evalData.meanVal)}   Median = ${fmtNum(evalData.medianVal)}   IQR = ${fmtNum(evalData.iqr)}`, 54, 246);
            }
            readoutHtml = st.revealedCenter
              ? `Mean = <b>${fmtNum(evalData.meanVal)}</b> · Median = <b>${fmtNum(evalData.medianVal)}</b> · Fulcrum = ${fmtNum(st.fulcrumX)}`
              : `Fulcrum at <b>${fmtNum(st.fulcrumX)}</b> · ${evalData.fulcrumBalanced ? 'Level!' : 'Tilted — drag fulcrum or push a dot!'}`;
          }
        } else {
          // Best-fit Residuals
          const ox = 60;
          const oy = 240;
          const sx = 64;
          const sy = 26;
          const toX = x => ox + x * sx;
          const toY = y => oy - y * sy;

          ctx.strokeStyle = C.muted; ctx.lineWidth = 1.5;
          ctx.beginPath(); ctx.moveTo(ox, oy); ctx.lineTo(w - 40, oy); ctx.moveTo(ox, oy); ctx.lineTo(ox, 28); ctx.stroke();

          // My Line + squared residual boxes
          const yA = st.mySlope * 0.5 + st.myIntercept;
          const yB = st.mySlope * 6.5 + st.myIntercept;
          ctx.strokeStyle = C.red; ctx.lineWidth = 2.5;
          ctx.beginPath(); ctx.moveTo(toX(0.5), toY(yA)); ctx.lineTo(toX(6.5), toY(yB)); ctx.stroke();

          st.scatterPts.forEach(p => {
            const pred = st.mySlope * p.x + st.myIntercept;
            const px = toX(p.x);
            const py = toY(p.y);
            const ly = toY(pred);
            const sidePx = Math.abs(py - ly);
            ctx.fillStyle = C.amber + '30'; ctx.strokeStyle = C.amber; ctx.lineWidth = 1.2;
            ctx.fillRect(px, Math.min(py, ly), sidePx, sidePx);
            ctx.strokeRect(px, Math.min(py, ly), sidePx, sidePx);
            ctx.fillStyle = C.blue;
            ctx.beginPath(); ctx.arc(px, py, 5, 0, Math.PI * 2); ctx.fill();
          });

          if (st.showBestFit) {
            ctx.save();
            ctx.strokeStyle = C.green; ctx.setLineDash([5, 4]); ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(toX(0.5), toY(evalData.ols.m * 0.5 + evalData.ols.c));
            ctx.lineTo(toX(6.5), toY(evalData.ols.m * 6.5 + evalData.ols.c));
            ctx.stroke();
            ctx.restore();
          }

          // Slope/Intercept handles on My Line
          const h1x = toX(1); const h1y = toY(st.mySlope * 1 + st.myIntercept);
          const h2x = toX(6); const h2y = toY(st.mySlope * 6 + st.myIntercept);
          [
            { id: 'h1', x: h1x, y: h1y },
            { id: 'h2', x: h2x, y: h2y }
          ].forEach(hd => {
            ctx.fillStyle = C.red;
            ctx.beginPath(); ctx.arc(hd.x, hd.y, 7.5, 0, Math.PI * 2); ctx.fill();
            activeHandles.push({
              id: hd.id,
              x: hd.x,
              y: hd.y,
              r: 20,
              onDrag(_, ny) {
                const newY = clamp(roundTo((oy - ny) / sy, 2), 0, 9);
                const y1 = hd.id === 'h1' ? newY : st.mySlope * 1 + st.myIntercept;
                const y2 = hd.id === 'h2' ? newY : st.mySlope * 6 + st.myIntercept;
                st.mySlope = (y2 - y1) / 5;
                st.myIntercept = y1 - st.mySlope;
                if (evalCh14(st).fitGoal) SoundEngine.playLevelChime();
              }
            });
          });
          readoutHtml = `My line: <b>y = ${fmtNum(st.mySlope)}x + ${fmtNum(st.myIntercept)}</b> · Sum of squared residuals = <b>${fmtNum(evalData.mySSR)}</b>`;
        }
      } else if (chNum === 17 || chNum === 18) {
        evalData = evalCalcState(st);
        const x0 = 56;
        const x1 = w - 40;
        const toX = x => x0 + (x / 3.0) * (x1 - x0);
        const fromX = px => clamp(roundTo(((px - x0) / (x1 - x0)) * 3.0, 2), 0.1, 2.95);

        const panels = [
          { lbl: 'f(x)', yMid: 64, sc: 14, col: C.blue, key: 'f' },
          { lbl: "f'(x)", yMid: 152, sc: 14, col: C.red, key: 'fp' },
          { lbl: '∫f(t)dt', yMid: 242, sc: 12, col: C.amber, key: 'F' }
        ];

        panels.forEach(pn => {
          ctx.strokeStyle = C.muted; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(x0, pn.yMid); ctx.lineTo(x1, pn.yMid); ctx.stroke();
          ctx.fillStyle = pn.col;
          ctx.fillText(pn.lbl, 10, pn.yMid + 4);

          if (pn.key === 'fp' && st.predictEnabled && !st.predictRevealed) {
            ctx.fillStyle = C.muted;
            ctx.fillText('Drag red dots to sketch f′(x), then Reveal', x0 + 8, pn.yMid - 34);
          } else {
            ctx.strokeStyle = pn.col; ctx.lineWidth = 2.2;
            ctx.beginPath();
            let penDown = false;
            for (let u = 0; u <= 3.0; u += 0.04) {
              const res = evalCalcFunction(st.curveKind, u);
              const val = res[pn.key];
              if (!Number.isFinite(val)) { penDown = false; continue; }
              const px = toX(u);
              const py = clamp(pn.yMid - val * pn.sc, pn.yMid - 34, pn.yMid + 34);
              if (!penDown) { ctx.moveTo(px, py); penDown = true; } else { ctx.lineTo(px, py); }
            }
            ctx.stroke();
          }

          if (pn.key === 'f' && chNum === 18) {
            // Net signed area shading up to refX
            for (let u = 0; u < st.refX; u += 0.06) {
              const yv = evalCalcFunction(st.curveKind, u).f;
              const px = toX(u);
              const bh = clamp(yv * pn.sc, -34, 34);
              ctx.fillStyle = (yv >= 0 ? C.blue : C.red) + '32';
              ctx.fillRect(px, yv >= 0 ? pn.yMid - bh : pn.yMid, 6, Math.abs(bh));
            }
          }
        });

        // Predict nodes on panel 2
        if (st.predictEnabled) {
          st.predictNodes.forEach((nd, idx) => {
            const px = toX(nd.x);
            const py = clamp(152 - nd.y * 14, 118, 186);
            ctx.fillStyle = C.red;
            ctx.beginPath(); ctx.arc(px, py, 6, 0, Math.PI * 2); ctx.fill();
            activeHandles.push({
              id: `pnode-${idx}`,
              x: px,
              y: py,
              r: 18,
              onDrag(_, ny) { nd.y = clamp(roundTo((152 - ny) / 14, 1), -2.5, 2.5); }
            });
          });
        }

        // Synchronized vertical reference line scrubber
        const rx = toX(st.refX);
        ctx.strokeStyle = C.green; ctx.lineWidth = 2.4;
        ctx.beginPath(); ctx.moveTo(rx, 20); ctx.lineTo(rx, h - 18); ctx.stroke();
        ctx.fillStyle = C.green;
        ctx.beginPath(); ctx.arc(rx, 24, 8, 0, Math.PI * 2); ctx.fill();
        activeHandles.push({
          id: 'refX',
          x: rx,
          y: 140,
          r: 26,
          onDrag(nx) {
            const prevDefined = evalCalcFunction(st.curveKind, st.refX).definedDeriv;
            st.refX = fromX(nx);
            st.interacted = true;
            st.minRefX = Math.min(typeof st.minRefX === 'number' ? st.minRefX : st.refX, st.refX);
            st.maxRefX = Math.max(typeof st.maxRefX === 'number' ? st.maxRefX : st.refX, st.refX);
            const nowDefined = evalCalcFunction(st.curveKind, st.refX).definedDeriv;
            if (prevDefined && !nowDefined) SoundEngine.playCuspJump();
          }
        });

        const fpStr = evalData.val.definedDeriv ? fmtNum(evalData.val.fp) : 'jumps!';
        readoutHtml = `At <b>x = ${fmtNum(st.refX)}</b>: f = <b>${fmtNum(evalData.val.f)}</b> · slope f′ = <b>${fpStr}</b> · net area = <b>${fmtNum(evalData.val.F)}</b>`;
      }

      if (window.highlightedRole) {
        const ch = currentChapterObj();
        const mappings = (ch.intuitionToFormula && ch.intuitionToFormula.termMappings) || [];
        const matched = mappings.find(m => m.colorRole === window.highlightedRole);
        if (matched) {
          const roleCol = matched.colorRole === 'red' ? C.red : (matched.colorRole === 'blue' ? C.blue : (matched.colorRole === 'amber' ? C.amber : C.green));
          ctx.strokeStyle = roleCol;
          ctx.lineWidth = 3;
          ctx.strokeRect(6, 6, w - 12, h - 12);
        }
      }

      ctx.restore();
      const lr = document.getElementById('live-readout');
      if (lr) {
        lr.dataset.originalHtml = readoutHtml;
        lr.innerHTML = readoutHtml;
      }
      return evalData;
    }

    // Bind direct canvas pointer dragging (including multi-touch two-hand support!)
    function bindCanvasPointers() {
      const canvas = document.getElementById('sim-canvas');
      if (!canvas || canvas.dataset.phetBound) return;
      canvas.dataset.phetBound = '1';
      canvas.style.touchAction = 'none';

      const canvasPos = e => {
        const rect = canvas.getBoundingClientRect();
        return {
          x: e.clientX - rect.left,
          y: e.clientY - rect.top
        };
      };

      canvas.addEventListener('pointerdown', e => {
        const pos = canvasPos(e);
        let best = null;
        let bestDist = Infinity;
        for (const hnd of activeHandles) {
          const d = Math.hypot(pos.x - hnd.x, pos.y - hnd.y);
          if (d <= hnd.r && d < bestDist) {
            best = hnd;
            bestDist = d;
          }
        }
        if (best) {
          session.pointers.set(e.pointerId, best.id);
          canvas.setPointerCapture?.(e.pointerId);
          recordInteraction();
        }
      });

      canvas.addEventListener('pointermove', e => {
        const targetId = session.pointers.get(e.pointerId);
        if (!targetId) return;
        const pos = canvasPos(e);
        const hnd = activeHandles.find(h => h.id === targetId);
        if (hnd && typeof hnd.onDrag === 'function') {
          hnd.onDrag(pos.x, pos.y);
          if (typeof window.drawSandbox === 'function') window.drawSandbox();
        }
      });

      const release = e => {
        session.pointers.delete(e.pointerId);
      };
      canvas.addEventListener('pointerup', release);
      canvas.addEventListener('pointercancel', release);
    }

    // Wrap drawSandbox & renderChapter smoothly without breaking existing behavior
    const origDraw = window.drawSandbox;
    const origRender = window.renderChapter;

    // Compute readoutHTML cleanly without mutating slider state on redraw, and skip wasted canvas draw when SVG owns stage
    function applySliderToLabState(chNum, key, numVal) {
      const st = getOrCreateLabState(chNum);
      if (chNum === 4) {
        if (key === 'a') st.x = clamp(Math.round(numVal), 2, 7);
        if (key === 'b') st.p = st.mode === 'area-generic' ? clamp(Math.round(numVal), -5, 5) : clamp(Math.round(numVal), 1, 6);
        if (key === 'c') st.q = st.mode === 'area-generic' ? clamp(Math.round(numVal), -5, 5) : clamp(Math.round(numVal), 1, 6);
      } else if (chNum === 7 && st.mode === 'function-machine' && key === 'a') {
        st.testInput = clamp(Math.round(numVal), -4, 8);
      }
    }

    function computeReadoutHtmlForChapter(chNum, st) {
      const ev = evalChapterData(chNum, st);
      if (chNum === 1) {
        if (st.mode === 'classic-turns') return '';
        const u = st.context === 'temp' ? '°C' : (st.context === 'money' ? ' ₹' : '');
        return `Start <b>A = ${fmtNum(st.a)}${u}</b> · End <b>B = ${fmtNum(st.b)}${u}</b> · Directed <b>${fmtNum(ev.directed)}</b> · Distance <b>${fmtNum(ev.distance)}</b>`;
      }
      if (chNum === 2 && st.mode === 'double-line') {
        return `Unit rate (at 1) = <b>${fmtNum(ev.unitRatio)}</b> · At ${fmtNum(st.probeScale)} units → <b>${fmtNum(ev.topAtProbe)}</b>`;
      }
      if (chNum === 3 && st.mode !== 'compound-growth') {
        return st.mode === 'ratio-tuner'
          ? `Left = <b>${fmtNum(st.left)}</b> · Right = <b>${fmtNum(st.right)}</b> · Target <b>${st.targetLeft}:${st.targetRight}</b> · ${ev.inProportion ? '<b>In tune!</b>' : 'Adjust to tune'}`
          : `Tray A = <b>${st.compareTargetLeft}:${st.compareTargetRight}</b> · Tray B = <b>${st.compareUserLeft}:${st.compareUserRight}</b>${st.compareRevealed && st.comparePrediction ? (ev.goalReached ? ' · <b>Prediction matched!</b>' : ' · Check unit rate') : ''}`;
      }
      if (chNum === 4) {
        if (st.mode === 'area-factor') {
          return `Factoring <b>${ev.puzzle.label}</b> · Your edges: <b>(x ${st.guessP >= 0 ? '+' : '−'} ${Math.abs(st.guessP)})(x ${st.guessQ >= 0 ? '+' : '−'} ${Math.abs(st.guessQ)})</b>`;
        }
        return `Area = <b>${formatSignedPoly(ev.linearSum, ev.pq)}</b> (at x=${ev.x}: total = <b>${ev.total}</b>)`;
      }
      if (chNum === 5) {
        const eqSign = ev.balanced ? '=' : (ev.diff > 0 ? '>' : '<');
        return ev.isolated
          ? `<b>Solved! x = ${ev.solvedValue}</b> · ${st.lastMoveLabel}`
          : `<b>${formatPanExpr(st.leftX, st.leftOnes)} ${eqSign} ${formatPanExpr(st.rightX, st.rightOnes)}</b> · ${ev.balanced ? 'Balanced' : 'Tilted'} · Lock ${st.symLock ? 'On' : 'Off'}`;
      }
      if (chNum === 7) {
        if (st.mode === 'graph-probe') {
          return `${ev.vertical ? `x = ${fmtNum(st.p1.x)}` : `<b>y = ${fmtNum(ev.m)}x + ${fmtNum(ev.c)}</b>`} · Probe (${fmtNum(st.probe.x)}, ${fmtNum(st.probe.y)}) ${ev.probeOnLine ? 'on line' : 'off line'}`;
        }
        const shownIds = st.mysteryMode && st.mysteryRevealed ? st.mysterySecret : [st.op1, st.op2];
        const op1Obj = CH07_OPS.find(o => o.id === shownIds[0]) || CH07_OPS[0];
        const op2Obj = CH07_OPS.find(o => o.id === shownIds[1]) || CH07_OPS[0];
        const suffix = st.mysteryMode ? (st.mysteryRevealed ? ` · Rule: ${op1Obj.label} then ${op2Obj.label}` : ' (guess the hidden blocks!)') : '';
        return `Input <b>${st.testInput}</b> → Output <b>${fmtNum(ev.outVal)}</b>${suffix}`;
      }
      if (chNum === 13 && st.mode === 'live-sampler') {
        return `Samples = <b>${ev.count}</b> (n=${st.sampleN}) · Expected SE = <b>${fmtNum(ev.theoreticalSE)}</b> · Observed spread = <b>${fmtNum(ev.observedSE)}</b>`;
      }
      if (chNum === 14 && st.mode !== 'histogram') {
        if (st.mode === 'level-out') return `Total = ${ev.totalSum} across ${st.dots.length} bars · Levelled Mean = <b>${fmtNum(ev.meanVal)}</b>`;
        if (st.mode === 'best-fit') return `Your total square error = <b>${fmtNum(ev.mySSR)}</b> · Best possible = <b>${fmtNum(ev.bestSSR)}</b>`;
        return `Data [${st.dots.join(', ')}] · Fulcrum = <b>${fmtNum(st.fulcrumX)}</b> · ${ev.fulcrumBalanced ? '<b>Balanced on mean!</b>' : `Tip (torque = ${fmtNum(ev.torque)})`}`;
      }
      if (chNum === 17 || chNum === 18) {
        const fpStr = ev.val.definedDeriv ? fmtNum(ev.val.fp) : 'jumps!';
        return `At <b>x = ${fmtNum(st.refX)}</b>: f = <b>${fmtNum(ev.val.f)}</b> · slope f′ = <b>${fpStr}</b> · net area = <b>${fmtNum(ev.val.F)}</b>`;
      }
      return '';
    }

    window.drawSandbox = function wrappedDrawSandbox() {
      const ch = currentChapterObj();
      const chNum = ch.number || 0;
      const st = getOrCreateLabState(chNum);
      const params = currentParamsObject();
      [['param-a', 'val-a'], ['param-b', 'val-b'], ['param-c', 'val-c']].forEach(([inpId, valId]) => {
        const inp = document.getElementById(inpId);
        const valEl = document.getElementById(valId);
        if (inp && valEl) valEl.textContent = inp.value + (inp.dataset.unit || '');
      });
      const useCustom = shouldUseCustomCanvas(chNum, st);
      const usesSliders = !useCustom || (chNum === 4 && st.mode !== 'area-factor') || (chNum === 7 && st.mode === 'function-machine');
      document.querySelectorAll('#widget-stage-card .slider-row').forEach(r => {
        r.hidden = !usesSliders;
        r.style.display = usesSliders ? '' : 'none';
      });
      let evalData = {};
      const svgOwnsCanvas = Boolean(window.__kymAtelierSvgOwner);

      if (useCustom && !svgOwnsCanvas) {
        evalData = drawCustomChapter(chNum, st, params) || {};
      } else if (useCustom && svgOwnsCanvas) {
        evalData = evalChapterData(chNum, st);
        const html = computeReadoutHtmlForChapter(chNum, st);
        const lr = document.getElementById('live-readout');
        if (lr && html) {
          lr.dataset.originalHtml = html;
          lr.innerHTML = html;
        }
      } else if (typeof origDraw === 'function') {
        origDraw();
        evalData = evalChapterData(chNum, st);
        const lr = document.getElementById('live-readout');
        if (lr) lr.dataset.originalHtml = lr.innerHTML;
        if (chNum === 20) {
          const det = params.a * params.c - params.b * params.b;
          if (Math.abs(det) < 0.12) SoundEngine.playCollapse();
        }
      }

      const readoutPlain = stripHtml(document.getElementById('live-readout')?.dataset.originalHtml || document.getElementById('live-readout')?.innerHTML || '');
      const goalReached = Boolean(evalData.goalReached || st.goalDone);
      const voicing = buildVoicingForChapter(chNum, st, params, evalData, readoutPlain);

      syncStepVisibility(chNum, goalReached, voicing);

      if (goalReached && session.lastGoalNotifiedChapter !== chNum) {
        session.lastGoalNotifiedChapter = chNum;
        postBridge({
          type: 'goalReached',
          chapterNumber: chNum,
          detail: voicing.context
        });
      }

      const telemetryPayload = {
        type: 'stageState',
        chapterNumber: chNum,
        mode: st.mode || 'default',
        params,
        readoutPlain,
        voicing,
        goalReached,
        goalDetail: goalReached ? voicing.context : null,
        interactionCount: session.interactionCount
      };
      const telemetrySig = JSON.stringify(telemetryPayload);
      if (session.lastTelemetrySig !== telemetrySig) {
        session.lastTelemetrySig = telemetrySig;
        postBridge(telemetryPayload);
      }

      const readoutHtml = document.getElementById('live-readout')?.dataset.originalHtml
        || document.getElementById('live-readout')?.innerHTML || '';
      lastStageContext = {
        chNum,
        ch,
        st,
        params,
        evalData,
        readoutPlain,
        readoutHtml,
        step: session.step,
        goalReached,
        voicing,
        isDark: document.documentElement.getAttribute('data-theme') === 'dark',
        quirk: document.documentElement.getAttribute('data-quirk') || 'slightly-quirky',
        medium: document.documentElement.getAttribute('data-medium') || 'paper-ink'
      };
      stageListeners.forEach(fn => {
        try { fn(lastStageContext); } catch (err) { console.warn('Stage listener error:', err); }
      });
    };

    window.renderChapter = function wrappedRenderChapter() {
      if (typeof origRender === 'function') origRender();
      const ch = currentChapterObj();
      const chNum = ch.number || 0;
      configureSlidersForState(chNum, getOrCreateLabState(chNum));
      renderChapterToolbar(chNum);
      renderSnapshotStrip(chNum);
      window.drawSandbox();
    };

    // Slider input also counts as real interaction, syncs Ch 4/7 state, and redraws
    ['param-a', 'param-b', 'param-c'].forEach(id => {
      const el = document.getElementById(id);
      if (el) {
        const key = id.slice(-1);
        el.addEventListener('input', () => {
          const chNum = currentChapterObj().number || 0;
          applySliderToLabState(chNum, key, parseFloat(el.value));
          recordInteraction();
          SoundEngine.playDetent(1);
          window.drawSandbox();
        });
      }
    });
    window.addEventListener('resize', () => window.drawSandbox());

    // Global exposed API for PatternedWorldWebStageBridge
    window.setStageStep = function setStageStep(step) {
      if (!step) return;
      const valid = ['openPlay', 'cutAway', 'symbolic', 'challenge'];
      if (!valid.includes(step) || session.step === step) return;
      session.step = step;
      const lr = document.getElementById('live-readout');
      if (lr && step !== 'openPlay' && lr.dataset.originalHtml) {
        lr.innerHTML = lr.dataset.originalHtml;
      }
      window.drawSandbox();
    };

    window.configureStagePreset = function configureStagePreset(preset) {
      if (!preset || typeof preset !== 'object') return;
      if (typeof preset.chapterNumber === 'number' && typeof window.selectChapter === 'function') {
        window.selectChapter(preset.chapterNumber);
      }
      const ch = currentChapterObj();
      const chNum = ch.number || 0;
      const st = getOrCreateLabState(chNum);
      if (preset.mode) st.mode = preset.mode;
      if (preset.step) session.step = preset.step;
      if (preset.challengePrompt) session.customChallengePrompt = preset.challengePrompt;
      session.lockedControls = Array.isArray(preset.lockedControls) ? preset.lockedControls : [];

      configureSlidersForState(chNum, st);

      if (preset.params && typeof preset.params === 'object') {
        ['a', 'b', 'c'].forEach(k => {
          if (typeof preset.params[k] === 'number') syncSliderValue(k, preset.params[k]);
        });
        if (chNum === 1) {
          if (typeof preset.params.a === 'number') st.a = preset.params.a;
          if (typeof preset.params.b === 'number') st.b = preset.params.b;
        } else if (chNum === 2) {
          if (typeof preset.params.a === 'number') st.topUnit = preset.params.a;
          if (typeof preset.params.b === 'number') st.bottomUnit = preset.params.b;
        } else if (chNum === 3) {
          if (typeof preset.params.a === 'number') st.left = preset.params.a;
          if (typeof preset.params.b === 'number') st.right = preset.params.b;
        } else if (chNum === 4) {
          if (typeof preset.params.a === 'number') st.x = Math.round(preset.params.a);
          if (typeof preset.params.b === 'number') st.p = Math.round(preset.params.b);
          if (typeof preset.params.c === 'number') st.q = Math.round(preset.params.c);
          configureSlidersForState(chNum, st);
        } else if (chNum === 5 && typeof preset.params.a === 'number') {
          st.leftX = Math.round(preset.params.a);
          st.leftOnes = Math.round(preset.params.b ?? 0);
          st.rightX = Math.round(preset.params.c ?? 0);
          st.rightOnes = Math.round(preset.params.d ?? 10);
          const denom = st.leftX - st.rightX;
          if (denom !== 0) st.hiddenX = (st.rightOnes - st.leftOnes) / denom;
        } else if (chNum === 7) {
          if (st.mode === 'function-machine') {
            if (typeof preset.params.a === 'number') st.testInput = Math.round(clamp(preset.params.a, -4, 8));
            syncSliderValue('a', st.testInput);
          } else if (typeof preset.params.a === 'number' || typeof preset.params.b === 'number') {
            const slope = typeof preset.params.a === 'number' ? preset.params.a : 2;
            const intercept = typeof preset.params.b === 'number' ? preset.params.b : 1;
            const runStep = typeof preset.params.c === 'number' ? Math.max(1, preset.params.c) : 2;
            st.p1 = { x: 0, y: intercept };
            st.p2 = { x: runStep, y: intercept + slope * runStep };
          }
        } else if (chNum === 13 && typeof preset.params.b === 'number') {
          st.sampleN = Math.round(clamp(preset.params.b, 4, 64));
        } else if (chNum === 14 && typeof preset.params.c === 'number') {
          syncSliderValue('c', clamp(preset.params.c, 10, 30));
        } else if (chNum === 17 || chNum === 18) {
          if (typeof preset.params.a === 'number') {
            st.refX = clamp(preset.params.a, 0.25, 2.75);
            st.minRefX = st.refX;
            st.maxRefX = st.refX;
          }
        }
      }
      ['a', 'b', 'c'].forEach(k => {
        const el = document.getElementById(`param-${k}`);
        if (el) el.disabled = session.lockedControls.includes(k);
      });
      renderChapterToolbar(chNum);
      window.drawSandbox();
    };

    window.resetActiveLab = function resetActiveLab() {
      const ch = currentChapterObj();
      const chNum = ch.number || 0;
      resetChapterLabState(chNum);
      session.customChallengePrompt = null;
      session.lockedControls = [];
      session.lastGoalNotifiedChapter = null;
      if (typeof window.applyChapterSliders === 'function') window.applyChapterSliders(chNum);
      configureSlidersForState(chNum, getOrCreateLabState(chNum));
      ['a', 'b', 'c'].forEach(k => {
        const el = document.getElementById(`param-${k}`);
        if (el) el.disabled = false;
      });
      SoundEngine.playDetent(-1);
      renderChapterToolbar(chNum);
      window.drawSandbox();
    };

    window.captureStageSnapshot = function captureStageSnapshot() {
      const ch = currentChapterObj();
      const chNum = ch.number || 0;
      const st = getOrCreateLabState(chNum);
      const params = currentParamsObject();
      const evalData = evalChapterData(chNum, st);
      const readoutPlain = stripHtml(document.getElementById('live-readout')?.dataset.originalHtml || document.getElementById('live-readout')?.innerHTML || '');
      const voicing = buildVoicingForChapter(chNum, st, params, evalData, readoutPlain);
      let dataUrl = '';
      let pngDataUrl = '';
      let pendingSvgUrl = '';
      try {
        const svgHost = document.getElementById('atelier-svg-host');
        const svgEl = svgHost && !svgHost.hidden ? svgHost.querySelector('svg') : null;
        if (svgEl && typeof XMLSerializer !== 'undefined') {
          const xml = new XMLSerializer().serializeToString(svgEl);
          const bytes = new TextEncoder().encode(xml);
          let bin = '';
          for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
          dataUrl = 'data:image/svg+xml;base64,' + btoa(bin);
          pendingSvgUrl = dataUrl;
        } else {
          const canvas = document.getElementById('sim-canvas');
          if (canvas && typeof canvas.toDataURL === 'function') {
            dataUrl = canvas.toDataURL('image/png');
            pngDataUrl = dataUrl;
          }
        }
      } catch (err) {
        console.warn('Snapshot capture warning:', err);
      }

      const clonedState = JSON.parse(JSON.stringify(st));
      const snap = {
        id: `snap-ch${chNum}-${Date.now()}`,
        chapterNumber: chNum,
        title: `Ch ${chNum} · ${ch.title || 'Snapshot'}`,
        summary: readoutPlain || voicing.object,
        contextSentence: voicing.context,
        params,
        labState: clonedState,
        dataUrl,
        pngDataUrl
      };
      if (pendingSvgUrl && typeof Image !== 'undefined' && typeof document !== 'undefined') {
        const img = new Image();
        img.onload = () => {
          try {
            const c = document.createElement('canvas');
            c.width = 560;
            c.height = 290;
            const cx = c.getContext('2d');
            if (cx) {
              cx.drawImage(img, 0, 0, 560, 290);
              snap.pngDataUrl = c.toDataURL('image/png');
              postBridge({
                type: 'pinSnapshot',
                id: snap.id,
                chapterNumber: snap.chapterNumber,
                title: snap.title,
                summary: snap.summary,
                contextSentence: snap.contextSentence,
                params: snap.params,
                pngDataUrl: snap.pngDataUrl
              });
            }
          } catch (err) {
            console.warn('SVG->PNG conversion failed:', err);
          }
        };
        img.src = pendingSvgUrl;
      }
      const sameCh = session.snapshots.filter(s => s.chapterNumber === chNum);
      if (sameCh.length >= 4) {
        const oldest = sameCh[0];
        session.snapshots = session.snapshots.filter(s => s.id !== oldest.id);
      }
      session.snapshots.push(snap);
      if (chNum === 13 && st.sampleN <= 4 && st.samples.length >= 5) st.snapshotAtSmallN = true;
      SoundEngine.playBoop(2);
      renderSnapshotStrip(chNum);
      postBridge({
        type: 'pinSnapshot',
        id: snap.id,
        chapterNumber: snap.chapterNumber,
        title: snap.title,
        summary: snap.summary,
        contextSentence: snap.contextSentence,
        params: snap.params,
        pngDataUrl: snap.pngDataUrl || ''
      });
      return snap;
    };

    // Wire utility bar buttons
    const btnSound = document.getElementById('btn-sound');
    if (btnSound) {
      btnSound.addEventListener('click', () => {
        const on = SoundEngine.toggle();
        btnSound.setAttribute('aria-pressed', on ? 'true' : 'false');
        btnSound.textContent = on ? 'Sound: On' : 'Sound';
      });
    }
    const btnSnap = document.getElementById('btn-snapshot');
    if (btnSnap) btnSnap.addEventListener('click', () => window.captureStageSnapshot());
    const btnReset = document.getElementById('btn-reset-lab');
    if (btnReset) btnReset.addEventListener('click', () => window.resetActiveLab());

    window.__kymPhetStage = {
      getContext() {
        if (lastStageContext) return lastStageContext;
        const ch = currentChapterObj();
        const chNum = ch.number || 0;
        const st = getOrCreateLabState(chNum);
        return {
          chNum,
          ch,
          st,
          params: currentParamsObject(),
          evalData: evalChapterData(chNum, st),
          readoutPlain: stripHtml(document.getElementById('live-readout')?.dataset.originalHtml || document.getElementById('live-readout')?.innerHTML || ''),
          readoutHtml: document.getElementById('live-readout')?.dataset.originalHtml || '',
          step: session.step,
          goalReached: false,
          voicing: null,
          isDark: document.documentElement.getAttribute('data-theme') === 'dark',
          quirk: document.documentElement.getAttribute('data-quirk') || 'slightly-quirky',
          medium: document.documentElement.getAttribute('data-medium') || 'paper-ink'
        };
      },
      onUpdate(fn) {
        if (typeof fn !== 'function') return () => {};
        stageListeners.add(fn);
        if (lastStageContext) {
          try { fn(lastStageContext); } catch (err) { console.warn('Stage listener error:', err); }
        }
        return () => stageListeners.delete(fn);
      },
      recordInteraction,
      redraw: () => window.drawSandbox(),
      handleTool: (tool) => handleToolClick(currentChapterObj().number || 0, tool),
      setSliderParam(key, value) {
        const el = document.getElementById(`param-${key}`);
        if (!el) return false;
        el.value = value;
        applySliderToLabState(currentChapterObj().number || 0, key, parseFloat(value));
        recordInteraction();
        SoundEngine.playDetent(1);
        window.drawSandbox();
        return true;
      },
      syncSliderValue,
      applySliderToLabState,
      formatSignedPoly,
      escapeHtml,
      getThemeColors,
      SoundEngine,
      evalChapterData,
      formatPanExpr,
      evalCalcFunction
    };

    if (typeof MutationObserver !== 'undefined') {
      let observingRedraw = false;
      const rootObs = new MutationObserver(() => {
        if (observingRedraw) return;
        observingRedraw = true;
        try { window.drawSandbox(); } finally { observingRedraw = false; }
      });
      rootObs.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['data-theme', 'data-quirk', 'data-medium']
      });
    }

    bindCanvasPointers();
    // Initial render sync
    const initCh = currentChapterObj();
    renderChapterToolbar(initCh.number || 0);
    renderSnapshotStrip(initCh.number || 0);
    window.drawSandbox();
    if (typeof CustomEvent !== 'undefined') {
      window.dispatchEvent(new CustomEvent('kymPhetStageReady'));
    }
  }

  if (typeof window !== 'undefined' && typeof document !== 'undefined') {
    if (document.readyState !== 'loading' || document.getElementById('sim-canvas')) {
      installBrowserRuntime();
    } else {
      document.addEventListener('DOMContentLoaded', installBrowserRuntime);
    }
  }

  const exportedApi = {
    createRng,
    gcd,
    escapeHtml,
    formatSignedPoly,
    stripHtml,
    evalChapterData,
    createCh01State, evalCh01,
    createCh02State, evalCh02,
    createCh03State, evalCh03,
    createCh04State, evalCh04, CH04_PUZZLES,
    createCh05State, applyCh05Op, undoCh05, evalCh05, formatPanExpr, CH05_PUZZLES,
    createCh07State, evalCh07, CH07_OPS,
    createCh13State, drawSamplesCh13, evalCh13,
    createCh14State, evalCh14, computeMedian, computeQuartiles, computeOLS,
    createCalcState, evalCalcFunction, evalCalcState,
    buildVoicingForChapter
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = exportedApi;
  }
  globalScope.KymPhetLabs = exportedApi;
})(typeof globalThis !== 'undefined' ? globalThis : window);
