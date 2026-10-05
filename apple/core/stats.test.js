import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as St from './stats.js'

// 0025 barbell bench press, 0032 barbell deadlift, 0652 push-up.
const NOW = new Date('2026-10-05T12:00:00').getTime()
const at = (iso, hh = 18) => new Date(`${iso}T${String(hh).padStart(2, '0')}:00:00`).getTime()
let seq = 0
/** A finished workout record in openGym's shape: `ex` maps an exercise id to its sets. */
function workout(iso, ex, min = 45) {
  const start = at(iso)
  return {
    id: 'w' + (++seq), d: iso, start, end: start + min * 60000, name: 'Session',
    entries: Object.entries(ex).map(([id, sets]) => ({
      id, target: { id, sets: sets.length, reps: 5, weight: sets[0].w || 0 },
      sets: sets.map(s => ({ done: true, ...s })),
    })),
  }
}
const st = () => JSON.parse(A.exportState())

function fresh(extra = {}) {
  seq = 0
  A.load(JSON.stringify({
    workouts: [
      workout('2026-09-07', { '0025': [{ w: 60, r: 5, rir: 3 }, { w: 60, r: 5, rir: 2 }], '0032': [{ w: 100, r: 5 }] }),
      workout('2026-09-14', { '0025': [{ w: 62.5, r: 5, rir: 2 }, { w: 62.5, r: 5, rir: 2 }] }, 60),
      workout('2026-09-21', { '0025': [{ w: 65, r: 5, rir: 1 }, { w: 65, r: 4, rir: 0 }], '0652': [{ w: 0, r: 15 }] }),
      workout('2026-10-02', { '0025': [{ w: 62.5, r: 8, rir: 1 }], '0032': [{ w: 110, r: 3 }] }, 30),
    ],
    bodyweight: [
      { d: '2026-09-10', w: 80, t: at('2026-09-10', 8) },
      { d: '2026-10-04', w: 78.5, t: at('2026-10-04', 8) },
    ],
    ...extra,
  }))
}

describe('overview', () => {
  beforeEach(() => fresh())

  it('counts workouts, this month and the streak, and the 30-day weight change', () => {
    const o = St.overview(NOW, '2026-10-05')
    expect(o.workouts).toBe(4)
    expect(o.month).toBe(1)
    expect(o.streak).toBeGreaterThanOrEqual(1)
    expect(o.weight).toBe('-1.5 kg')
    expect(o.tone).toBe('plain')                 // no goal set
    expect(o.recent).toHaveLength(4)
    expect(o.recent[0].d).toBe('2026-10-02')     // newest first
    expect(o.hasEffort).toBe(true)
    expect(o.heatmapMetric).toBe('time')
  })

  it('colours the weight change against the goal and reads lb', () => {
    fresh({ targetW: 75, unit: 'lb' })
    const o = St.overview(NOW, '2026-10-05')
    expect(o.tone).toBe('good')
    expect(o.weight).toBe('-1.5 lb')
    fresh({ targetW: 85 })
    expect(St.overview(NOW, '2026-10-05').tone).toBe('bad')
  })

  it('shows a dash with fewer than two weigh-ins in 30 days', () => {
    fresh({ bodyweight: [] })
    expect(St.overview(NOW, '2026-10-05').weight).toBe('—')
    expect(St.overview(NOW, '2026-10-05').tone).toBe('neutral')
  })
})

describe('exercise progress', () => {
  beforeEach(() => fresh())

  it('lists logged exercises strongest first, with their latest figure, and searches them', () => {
    const list = St.progressExercises()
    expect(list.map(e => e.id)).toEqual(['0032', '0025', '0652'])
    expect(list[0].value).toBe('110 kg')
    expect(list[2].value).toBe('15 reps')        // a push-up's figure is its reps
    expect(St.progressExercises('bench').map(e => e.id)).toEqual(['0025'])
    expect(St.firstProgressExercise()).toBe('0032')
  })

  it('charts the top set, the estimated 1RM (Epley, capped at 12 reps) and effort', () => {
    const p = St.exerciseProgress('0025')
    expect(p.mode).toBe('reps')
    expect(p.unit).toBe('kg')
    expect(p.top.map(x => x.y)).toEqual([60, 62.5, 65, 62.5])
    // 62.5 × 8 → 62.5 · (1 + 8/30) = 79.2, the best estimate
    expect(p.e1rm.map(x => x.y)).toEqual([70, 72.9, 75.8, 79.2])
    expect(p.best.top).toBe('65 kg')
    expect(p.best.e1rm).toBe('79.2 kg')
    expect(p.e1rmNote).toContain('62.5 kg × 8')
    expect(p.metrics.map(m => m.value)).toEqual(['top', 'e1rm', 'effort'])
    expect(p.effort.map(x => x.y)).toEqual([2.5, 2, 0.5, 1])
    expect(p.invertEffort).toBe(true)
    expect(p.top[2].m).toBeCloseTo(1 - 0.5 / 4)  // nearly to failure: a nearly full dot
    expect(p.top[2].note).toBe('RIR 0.5')
    expect(p.recent).toHaveLength(4)
    expect(p.recent[0].sets).toContain('62.5×8')
    expect(p.bestSet.text).toContain('65×5')
    expect(p.bestSet.d).toBe('2026-09-21')
  })

  it('reads effort in RPE when the profile does', () => {
    fresh({ effort: 'rpe' })
    const p = St.exerciseProgress('0025')
    expect(p.scale).toBe('RPE')
    expect(p.effort.map(x => x.y)).toEqual([7.5, 8, 9.5, 9])
    expect(p.invertEffort).toBe(false)
  })

  it('plots reps for an exercise never loaded, and gives it no 1RM', () => {
    const p = St.exerciseProgress('0652')
    expect(p.unit).toBe('reps')
    expect(p.top.map(x => x.y)).toEqual([15])
    expect(p.metrics.map(m => m.value)).toEqual(['top'])
  })

  it('feeds the in-workout history sheet with its curve and sessions', () => {
    const h = St.historySheet('0025')
    expect(h.total).toBe(4)
    expect(h.points.map(p => p.y)).toEqual([60, 62.5, 65, 62.5])
    expect(h.e1rm).toHaveLength(4)
    expect(h.best).toBe('65 kg')
    expect(h.e1rmBest).toBe('79.2 kg')
    expect(h.sessions[0].date).toBeTruthy()
    expect(h.sessions.find(s => s.pr).value).toBe('65 kg')
    expect(St.historySheet('0001').total).toBe(0)
  })
})

describe('1RM calculator', () => {
  beforeEach(() => fresh())

  it('opens on the best set from the log and reads it back for 1–12 reps', () => {
    const o = St.oneRM('0025')
    expect(o.available).toBe(true)
    expect([o.w, o.r]).toEqual([62.5, 8])
    expect(o.estimate).toBe(79.2)
    expect(o.fromLog.value).toBe('79.2 kg')
    expect(o.table).toHaveLength(12)
    expect(o.table[0]).toMatchObject({ reps: 1, w: 79.2, pct: 100 })
    expect(o.table[9].w).toBeCloseTo(79.2 / (1 + 10 / 30), 1)
  })

  it('refuses more than 12 reps and has no 1RM for cardio or assistance', () => {
    const o = St.oneRM('0025', 100, 15)
    expect(o.estimate).toBe(null)
    expect(o.estimateText).toBe('—')
    expect(o.table).toEqual([])
    expect(o.note).toContain('12')
    expect(St.oneRM('0025', 100, 1).estimate).toBe(100)
    const fresh0 = St.oneRM('0047')              // never logged: 20 × 5
    expect([fresh0.w, fresh0.r, fresh0.fromLog]).toEqual([20, 5, null])
  })
})

describe('heatmap', () => {
  beforeEach(() => fresh())

  it('lays out 53 weeks ending this week, shaded by minutes', () => {
    const h = St.heatmap(null, NOW)
    expect(h.metric).toBe('time')
    expect(h.weeks).toHaveLength(53)
    expect(h.weeks.every(w => w.days.length === 7)).toBe(true)
    const days = h.weeks.flatMap(w => w.days)
    expect(days.find(d => d.today).iso).toBe('2026-10-05')
    expect(days.find(d => d.iso === '2026-10-02').level).toBe(1)   // the shortest session
    expect(days.find(d => d.iso === '2026-09-14').level).toBe(4)   // the longest
    expect(days.find(d => d.iso === '2026-09-14').tip).toContain('60 min')
    expect(days.find(d => d.iso === '2026-09-15').level).toBe(0)
    expect(days.filter(d => d.future).length).toBe(6)              // Monday-start week
    expect(h.dayLabels[0]).toBe('Mon')
    expect(h.weeks.some(w => w.month === 'Oct')).toBe(true)
  })

  it('switches to volume and remembers it in the profile', () => {
    St.setHeatmapMetric('vol')
    expect(st().heatmapMetric).toBe('vol')
    const h = St.heatmap(null, NOW)
    expect(h.metric).toBe('vol')
    expect(h.less).toBe('Less volume')
    const days = h.weeks.flatMap(w => w.days)
    expect(days.find(d => d.iso === '2026-09-07').level).toBe(4)   // bench and deadlift
    St.setHeatmapMetric('nonsense')
    expect(st().heatmapMetric).toBe('time')
  })

  it('starts the week on Sunday when the profile does', () => {
    fresh({ weekStart: 0 })
    const h = St.heatmap(null, NOW)
    expect(h.dayLabels[1]).toBe('Mon')
    expect(h.weeks[52].days[0].iso).toBe('2026-10-04')
  })
})

describe('effort', () => {
  beforeEach(() => fresh())

  it('averages the rated sets, counts the hard ones and the coverage', () => {
    const e = St.effortCard(0)
    expect(e.rated).toBe(7)
    expect(e.average).toBe('1.6 RIR')            // (3+2+2+2+1+0+1) / 7
    expect(e.hard).toBe('100%')
    expect(e.coverage).toBe('7 of 10 finished sets rated')
    expect(e.weeks.map(w => w.y)).toEqual([2.5, 2, 0.5])          // a week of one rated set is left out
    expect(e.bins.map(b => b.n)).toEqual([1, 2, 3, 1, 0])
    expect(e.bins[0].label).toBe('RIR 0')
    expect(e.off).toBeTruthy()                   // effort is off by default
  })

  it('windows by days and labels RPE hardest first', () => {
    fresh({ effort: 'rpe' })
    const e = St.effortCard(30)
    expect(e.scale).toBe('RPE')
    expect(e.off).toBe(null)
    expect(e.bins[0].label).toBe('RPE 10')
    expect(e.bins[4].label).toBe('RPE ≤ 6')
  })
})

describe('structural balance', () => {
  beforeEach(() => fresh())

  it('scores the chosen table and switches tables', () => {
    const b = St.balance()
    expect(b.template).toBe('poliquin')
    expect(b.templates.map(x => x.id)).toEqual(expect.arrayContaining(['poliquin', 'thibaudeauPowerlifting', 'atg']))
    expect(b.rows.length).toBeGreaterThan(3)
    expect(b.rows.every(r => typeof r.statusLabel === 'string' && r.value.includes('/'))).toBe(true)
    St.setBalanceTemplate('atg')
    expect(St.balance().template).toBe('atg')
    expect(() => St.setBalanceTemplate('constructor')).toThrow()
  })

  it('points a lift at another exercise and back', () => {
    const role = St.balance().rows[0].role
    St.setBalanceExercise(role, '0025', 7)
    const row = St.balance().rows.find(r => r.role === role)
    expect(row.custom).toBe(true)
    expect(row.exerciseId).toBe('0025')
    St.setBalanceExercise(role, null, 8)
    expect(St.balance().rows.find(r => r.role === role).custom).toBe(false)
  })
})

describe('muscle maps', () => {
  beforeEach(() => fresh())

  it('names the muscles and the silhouette parts, and follows the body setting', () => {
    const b = St.bodyInfo()
    expect(b.body).toBe('male')
    expect(b.muscles[0]).toEqual({ slug: 'trapezius', name: 'Traps' })
    expect(b.inert).toContain('head')
    fresh({ body: 'female' })
    expect(St.bodyInfo().body).toBe('female')
    expect(St.muscleBalance({}, NOW, '2026-10-05').body).toBe('female')
  })

  it('shades sets per muscle in a window, and only hard sets on request', () => {
    const all = St.muscleBalance({ win: 0 }, NOW, '2026-10-05')
    expect(all.palette).toBe('balance')
    expect(all.levels.chest).toBe(4)                     // bench is the most-trained
    expect(all.levels.hamstring).toBeGreaterThan(0)      // the deadlifts
    expect(Object.values(all.levels).filter(l => l === 0).length).toBe(all.missed.length)
    expect(all.top[0].slug).toBe('chest')
    expect(all.missed.length).toBeGreaterThan(0)
    expect(all.hardShown).toBe(true)
    const hard = St.muscleBalance({ win: 0, hard: true }, NOW, '2026-10-05')
    expect(hard.hard).toBe(true)
    expect(hard.subtitle).toBe('by hard sets')
    // The deadlifts and push-ups were never rated, so the muscles only they trained drop out.
    const shaded = m => Object.values(m.levels).filter(Boolean).length
    expect(shaded(hard)).toBeLessThan(shaded(all))
    const week = St.muscleBalance({ win: 7 }, NOW, '2026-10-05')   // Mon 5 Oct: nothing yet
    expect(week.empty).toBeTruthy()
    const month = St.muscleBalance({ win: 30, selected: 'chest' }, NOW, '2026-10-05')
    expect(month.selectedValue).toMatch(/sets/)
  })

  it('shows fatigue on fixed bands and names a muscle’s state', () => {
    const f = St.muscleBalance({ view: 'fatigue', selected: 'chest' }, NOW)
    expect(f.palette).toBe('fatigue')
    expect(f.legend.map(l => l.level)).toEqual([4, 2, 0])
    expect(['Ready', 'Recovering', 'Fatigued']).toContain(f.selectedValue)
    const fresh0 = St.muscleBalance({ view: 'fatigue', selected: 'chest' }, at('2026-10-02', 20))
    expect(fresh0.levels.chest).toBeGreaterThan(f.levels.chest)   // right after the session
  })

  it('shows retained strength and a muscle’s exercises with their estimated 1RM', () => {
    const s = St.muscleBalance({ view: 'strength', selected: 'chest' }, NOW)
    expect(s.palette).toBe('strength')
    expect(s.levels.chest).toBe(4)                       // trained three days ago: full
    expect(s.exercises[0].id).toBe('0025')
    expect(s.exercises[0].estimate).toContain('79.2 kg')
    expect(s.exercises[0].role).toBe('primary')
    expect(s.exercises[0].name).toBe('Barbell Bench Press')
    expect(s.hint).toBe(null)
    const later = St.muscleBalance({ view: 'strength' }, NOW + 60 * 86400000)
    expect(later.levels.chest).toBeLessThan(4)
    expect(later.detrained.map(d => d.slug)).toContain('chest')
    expect(later.hint).toBe('Tap a muscle to see its exercises.')
  })
})
