import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as P from './plan.js'
import * as PL from './planner.js'
import * as I from './insights.js'
import * as SET from './settings.js'
import { STRETCHES, isStretch, stretchConfig } from './stretches.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import { musclesOf } from '../../frontend/src/lib/muscles.js'

const st = () => JSON.parse(A.exportState())
const routine = id => st().routines.find(r => r.id === id)
beforeEach(() => A.load(null))

const reps = (id, sets = 3, more = {}) => ({ sets, reps: 10, weight: 0, mode: 'reps', ...more })
/** A routine with `[id, sets, extra]` exercises, scheduled on `days`. */
function make(name, list, days = []) {
  const rid = P.addRoutine(name)
  for (const [id, sets, more] of list) P.addRoutineExercise(rid, id, reps(id, sets, more))
  for (const d of days) P.addRoutineToDay(d, rid)
  return rid
}
const ids = list => list.map(e => e.id).sort()

describe('routine time', () => {
  it('is nothing for an empty routine', () => {
    expect(I.durationOf({ ex: [] }).sec).toBe(0)
  })
  it('adds reps × 3 s, set-up, rest between sets and a 5 min warm-up', () => {
    const rid = make('One', [['0025', 3, { restSec: 90 }]])
    // 3 × (10 × 3 + 15) work, 2 rests of 90 (none after the last set), 300 s warm-up
    expect(I.durationOf(routine(rid))).toMatchObject({ work: 135, rest: 180, warmup: 300, sec: 615, min: 10 })
  })
  it('uses the profile rest when the exercise has none', () => {
    A.patch({ restSec: 120 })
    const rid = make('One', [['0025', 2]])
    expect(I.durationOf(routine(rid)).rest).toBe(120)
  })
  it('counts holds, cardio and warm-up sets', () => {
    expect(I.durationOf({ ex: [{ id: 'gf-plank', sets: 2, mode: 'time', sec: 30, restSec: 60 }] }).sec).toBe(2 * 35 + 60 + 300)
    // Cardio first is its own warm-up.
    const cardio = Object.values(EXIDX).find(e => e.bp === 'cardio').id
    expect(I.durationOf({ ex: [{ id: cardio, sets: 1, min: 20 }] }).sec).toBe(1200)
    const plain = I.durationOf({ ex: [{ id: '0025', sets: 3, reps: 10, restSec: 90 }] }).sec
    const warm = I.durationOf({ ex: [{ id: '0025', sets: 3, reps: 10, restSec: 90, warmupSets: 2 }] }).sec
    expect(warm - plain).toBe(2 * (6 * 3 + 15 + 90))
  })
  it('a superset rests once a round, as long as its longest rest', () => {
    const a = { id: '0025', sets: 3, reps: 10, mode: 'reps', restSec: 60 }
    const b = { id: '0861', sets: 3, reps: 10, mode: 'reps', restSec: 90 }
    const apart = I.durationOf({ ex: [a, b] })
    const together = I.durationOf({ ex: [{ ...a, sg: 'x' }, { ...b, sg: 'x' }] })
    // 3 rounds of 45 + 10 + 45 s, then 2 rests of 90 s
    expect(together).toMatchObject({ work: 300, rest: 180 })
    expect(together.sec).toBeLessThan(apart.sec)
  })
  it('the week adds up every planned day', () => {
    const rid = make('A', [['0025', 3], ['0861', 3]], [1, 4])
    const one = I.durationOf(routine(rid)).sec
    expect(I.weekSummary()).toEqual({ min: Math.round(2 * one / 60), sessions: 2, days: [1, 4] })
    expect(I.routineSummaries()[rid].min).toBe(Math.round(one / 60))
  })
  it('the presets come out close to the session length TRAINING.md §14 gives them', () => {
    for (const p of PL.presetList(['gym'])) {
      for (const r of p.plan.routines) {
        const min = I.durationOf(r).min
        expect(min, `${p.id} ${r.name}`).toBeGreaterThanOrEqual(p.minutes * 0.55)
        expect(min, `${p.id} ${r.name}`).toBeLessThanOrEqual(p.minutes * 1.25)
      }
    }
  })
})

describe('routine difficulty', () => {
  it('has no label without lifting', () => {
    expect(I.difficultyOf({ ex: [] }).level).toBe(null)
    expect(I.difficultyOf({ ex: [{ id: 'gf-childs-pose', ...stretchConfig('gf-childs-pose') }] }).level).toBe(null)
  })
  it('labels by sets and time', () => {
    expect(I.difficultyOf({ ex: [{ id: '0025', ...reps('0025', 3) }, { id: '0861', ...reps('0861', 3) }] }))
      .toMatchObject({ level: 'light', sets: 6, tooLittle: false, tooMuch: false })
    const moderate = ['0043', '0025', '0861', '0085', '0334'].map(id => ({ id, ...reps(id, 3) }))
    expect(I.difficultyOf({ ex: moderate }).level).toBe('moderate')
    const big = ['0043', '0025', '0861', '0085', '0334', '0294', '0430', '1372', '0586', '2330'].map(id => ({ id, ...reps(id, 4) }))
    expect(I.difficultyOf({ ex: big })).toMatchObject({ level: 'veryHard', tooMuch: true, sets: 40, exercises: 10 })
  })
  it('too much when a muscle passes 10 sets in one session (§2.2)', () => {
    const chest = ['0025', '0289', '0047', '0662'].map(id => ({ id, ...reps(id, 4) }))
    const d = I.difficultyOf({ ex: chest })
    expect(d.tooMuch).toBe(true)
    expect(d.over[0].muscle).toBe('chest')
    expect(['hard', 'veryHard']).toContain(d.level)
  })
  it('too little under 6 hard sets', () => {
    expect(I.difficultyOf({ ex: [{ id: '0025', ...reps('0025', 3) }] }).tooLittle).toBe(true)
  })
  it('no evidence-based preset session is too much or too little', () => {
    for (const p of PL.presetList(['gym'])) for (const r of p.plan.routines) {
      const d = I.difficultyOf(r)
      expect(d.tooMuch || d.tooLittle, `${p.id} ${r.name} ${JSON.stringify(d)}`).toBe(false)
    }
  })
})

describe('difficulty suggestions', () => {
  const longDay = () => make('Everything', [['0043', 4], ['0025', 4], ['0861', 4], ['0085', 4], ['0334', 3],
    ['0294', 3], ['0430', 3], ['1372', 3], ['0586', 3], ['2330', 4]], [1])

  it('a split keeps every exercise and goes on a free day', () => {
    const rid = longDay()
    P.toggleSupersetLink(rid, 6)   // biceps + triceps superset
    const before = routine(rid).ex
    const sug = I.routineInsights(rid).suggestions.find(x => x.type === 'split')
    expect(sug.by).toBe('upperLower')
    expect([...sug.keep, ...sug.move].sort((a, b) => a - b)).toEqual(before.map((_, i) => i))
    const twin = I.applySuggestion(sug)
    const after = [...routine(rid).ex, ...routine(twin).ex]
    expect(ids(after)).toEqual(ids(before))
    // The superset stayed whole, on one side.
    const sg = before[6].sg
    const holders = [routine(rid), routine(twin)].filter(r => r.ex.some(e => e.sg === sg))
    expect(holders.length).toBe(1)
    expect(holders[0].ex.filter(e => e.sg === sg).length).toBe(2)
    expect(st().week[sug.day]).toEqual([twin])
    expect([0, 2, 6]).not.toContain(sug.day)   // not the day before or after Monday's
    expect(I.difficultyOf(routine(rid)).score).toBeLessThan(3)
  })
  it('an all-upper routine splits into halves', () => {
    const rid = make('Arms day', [['0025', 4], ['0289', 3], ['0861', 4], ['2330', 4], ['0334', 4], ['0294', 4], ['0430', 4], ['0047', 3], ['0652', 3]])
    const sug = I.routineInsights(rid).suggestions.find(x => x.type === 'split')
    expect(sug.by).toBe('halves')
    const before = routine(rid).ex
    const twin = I.applySuggestion(sug, 'Arms day 2')
    expect(routine(twin).name).toBe('Arms day 2')
    expect(ids([...routine(rid).ex, ...routine(twin).ex])).toEqual(ids(before))
    expect(sug.day).toBe(null)   // not on the week, so the new one isn't either
  })
  it('drops a set from the exercise on the over-worked muscle', () => {
    const rid = make('Chest', [['0025', 4], ['0289', 4], ['0047', 4], ['0662', 3]])
    const sug = I.routineInsights(rid).suggestions.find(x => x.type === 'dropSet')
    expect(sug.muscle).toBe('chest')
    expect(musclesOf(EXIDX[sug.exId]).chest).toBe(1)
    I.applySuggestion(sug)
    expect(routine(rid).ex[sug.index].sets).toBe(sug.to)
    // A stale suggestion does nothing.
    P.removeRoutineExercise(rid, sug.index)
    expect(I.applySuggestion(sug)).toBe(null)
  })
  it('too little: a set more each, or an exercise for a missing muscle', () => {
    const rid = make('Tiny', [['0025', 2], ['0861', 2]])
    const { suggestions } = I.routineInsights(rid)
    const more = suggestions.find(x => x.type === 'addSets')
    const add = suggestions.find(x => x.type === 'addExercise')
    expect(['deltoids', 'biceps', 'triceps']).toContain(add.muscle)   // an upper-body routine gets an upper-body muscle
    I.applySuggestion(more)
    expect(routine(rid).ex.map(e => e.sets)).toEqual([3, 3])
    I.applySuggestion(add)
    expect(routine(rid).ex.length).toBe(3)
    expect(I.difficultyOf(routine(rid)).tooLittle).toBe(false)
  })
  it('a dismissed kind stays hidden for that routine', () => {
    const rid = longDay()
    expect(I.routineInsights(rid).suggestions.length).toBeGreaterThan(0)
    I.dismissInsight(rid, 'tooMuch')
    expect(I.routineInsights(rid).suggestions).toEqual([])
    expect(st().gfDismissed[rid]).toEqual(['tooMuch'])
    I.dismissInsight(rid, 'cooldown')
    expect(I.routineInsights(rid).cooldown).toBe(null)
    // Deleted routines are pruned.
    const other = make('Other', [['0025', 3]])
    I.dismissInsight(other, 'cooldown')
    P.deleteRoutine(rid)
    I.dismissInsight(other, 'tooLittle')
    expect(Object.keys(st().gfDismissed)).toEqual([other])
  })
})

describe('cool-down stretches', () => {
  it('every listed stretch is in the catalogue and needs no equipment', () => {
    for (const [muscle, list] of Object.entries(STRETCHES)) for (const c of list) {
      expect(EXIDX[c.id], `${muscle} ${c.id}`).toBeTruthy()
      expect(EXIDX[c.id].eq).toBe('body weight')
      expect(isStretch(c.id)).toBe(true)
    }
    expect(isStretch('0025')).toBe(false)
    expect(isStretch('3645')).toBe(false)   // single leg bridge with outstretched leg
  })
  it('stretches the muscles the routine works, at the end, as timed holds', () => {
    const rid = make('Legs', [['0043', 3], ['0085', 3], ['0586', 3], ['1372', 3]])
    const map = P.routineMuscles(rid)
    const cd = I.routineInsights(rid).cooldown
    expect(cd.ex.length).toBeGreaterThanOrEqual(2)
    expect(cd.ex.length).toBeLessThanOrEqual(4)
    for (const e of cd.ex) {
      expect(EXIDX[e.id]).toBeTruthy()
      expect(e.mode).toBe('time')
      expect(e.sec).toBeGreaterThanOrEqual(30)
      expect(e.sec).toBeLessThanOrEqual(45)
      const stretched = Object.entries(STRETCHES).filter(([, l]) => l.some(c => c.id === e.id)).map(([m]) => m)
      expect(stretched.some(m => map.worked.includes(m)), e.id).toBe(true)
    }
    // No two stretches for the same muscle.
    const firstMuscle = id => Object.entries(STRETCHES).filter(([, l]) => l.some(c => c.id === id)).map(([m]) => m)
    const all = cd.ex.flatMap(e => firstMuscle(e.id))
    expect(new Set(all).size).toBe(all.length)
    // DVIDS demo videos first.
    expect(cd.ex.some(e => e.id.startsWith('gf-'))).toBe(true)
    I.applySuggestion(cd)
    const ex = routine(rid).ex
    expect(ex.slice(-cd.ex.length).map(e => e.id)).toEqual(cd.ex.map(e => e.id))
    // Stretches are not training: the map and the difficulty ignore them, and no second offer.
    expect(P.routineMuscles(rid)).toEqual(map)
    expect(I.difficultyOf(routine(rid)).sets).toBe(12)
    expect(I.routineInsights(rid).cooldown).toBe(null)
  })
  it('one-sided stretches hold once per side', () => {
    expect(stretchConfig('gf-figure-4-stretch')).toMatchObject({ sets: 2, sec: 30 })
    expect(stretchConfig('gf-childs-pose')).toMatchObject({ sets: 1, sec: 45 })
  })
  it('none for a routine without lifting', () => {
    const cardio = Object.values(EXIDX).find(e => e.bp === 'cardio').id
    const rid = P.addRoutine('Run')
    P.addRoutineExercise(rid, cardio)
    expect(I.routineInsights(rid).cooldown).toBe(null)
  })
})

describe('improve my plan', () => {
  const upperOnly = () => make('Upper', [['0025', 3], ['0861', 3], ['0334', 3], ['2330', 3]], [1, 4])

  it('flags under-trained, over-trained and once-a-week muscles (§2.1–2.3)', () => {
    upperOnly()
    const lows = I.improvePlan().checks.filter(c => c.issue === 'low').map(c => c.muscle)
    expect(lows).toEqual(expect.arrayContaining(['quadriceps', 'hamstring', 'gluteal']))
    expect(lows).not.toContain('chest')
    A.load(null)
    make('Chest', [['0025', 4], ['0289', 4], ['0047', 2]], [1, 3, 5])
    expect(I.improvePlan().checks.find(c => c.muscle === 'chest').issue).toBe('high')
    A.load(null)
    make('Full', [['0043', 4], ['0025', 4], ['0861', 4], ['0085', 4], ['0334', 3]], [1])
    expect(I.improvePlan().checks.find(c => c.muscle === 'chest')).toMatchObject({ issue: 'once', days: 1 })
  })
  it('a new routine for the gaps goes on two free days, spread out', () => {
    upperOnly()
    const sug = I.improvePlan().suggestions.find(x => x.type === 'addRoutine')
    expect(sug.ex.length).toBeGreaterThanOrEqual(2)
    expect(sug.ex.length).toBeLessThanOrEqual(3)
    expect(sug.focus).toBe('lower')
    expect(sug.days.length).toBe(2)
    for (const d of sug.days) expect([1, 4]).not.toContain(d)
    const n = st().routines.length
    const rid = I.applySuggestion(sug, 'Legs')
    expect(st().routines.length).toBe(n + 1)
    expect(routine(rid)).toMatchObject({ name: 'Legs', prog: 'double' })
    for (const d of sug.days) expect(st().week[d]).toEqual([rid])
    // The gap it was for is smaller now.
    const after = I.improvePlan().checks.filter(c => c.issue === 'low').map(c => c.muscle)
    expect(after.length).toBeLessThan(3)
  })
  it('exercises for a gap go into the routine that already trains that part of the body', () => {
    const legs = make('Leg day', [['0043', 3], ['1372', 3]], [2])
    upperOnly()
    const sug = I.improvePlan().suggestions.find(x => x.type === 'appendExercises' && x.muscle === 'hamstring')
    expect(sug.rid).toBe(legs)
    expect(sug.routineName).toBe('Leg day')
    expect(sug.ex.length).toBe(2)
    I.applySuggestion(sug)
    expect(routine(legs).ex.length).toBe(4)
  })
  it('only uses equipment from Settings', () => {
    const eqOk = allowed => s => s.ex.every(e => allowed.includes(EXIDX[e.id].eq))
    for (const [have, allowed] of [[[], ['body weight']], [['dumbbell'], ['dumbbell', 'body weight']],
      [['band'], ['band', 'body weight']]]) {
      A.load(null)
      SET.setEquipment(have)
      upperOnly()
      const { suggestions, equipment } = I.improvePlan()
      expect(suggestions.length, have.join()).toBeGreaterThan(0)
      expect(equipment.includes('gym')).toBe(false)
      for (const s of suggestions) expect(eqOk(allowed)(s), `${have} ${JSON.stringify(s.ex.map(e => e.id))}`).toBe(true)
      // The routine fixes too.
      const tiny = make('Tiny', [['0662', 2], ['0493', 2]])
      for (const s of I.routineInsights(tiny).suggestions.filter(x => x.ex)) expect(eqOk(allowed)(s)).toBe(true)
      for (const e of I.routineInsights(tiny).cooldown.ex) expect(EXIDX[e.id].eq).toBe('body weight')
    }
  })
  it('a single gap, like core, gets a short routine of its own', () => {
    P.loadStarterPlan('ppl')
    const sug = I.improvePlan().suggestions.find(x => x.type === 'addRoutine')
    expect(sug).toMatchObject({ focus: 'core', muscles: ['abs'] })
    expect(sug.ex.length).toBe(3)
    expect(new Set(sug.ex.map(e => e.id)).size).toBe(3)
    expect(sug.minutes).toBeLessThanOrEqual(20)
    expect(sug.days.length).toBe(2)
    for (const d of sug.days) expect([1, 3, 5]).not.toContain(d)
  })
  it('a starter push day over the per-muscle cap is offered a set less, not a split', () => {
    P.loadStarterPlan('ppl')
    const push = st().routines[0]
    const { difficulty, suggestions } = I.routineInsights(push.id)
    expect(difficulty.tooMuch).toBe(true)
    expect(suggestions.map(x => x.type)).toEqual(['dropSet'])
  })
  it('nothing to say about an empty week', () => {
    make('Unplanned', [['0025', 3]])
    expect(I.improvePlan()).toMatchObject({ checks: [], suggestions: [], scheduled: 0 })
  })
  it('a full week has no free day for a new routine', () => {
    const rid = make('Upper', [['0025', 3], ['0861', 3]], [0, 1, 2, 3, 4, 5, 6])
    expect(rid).toBeTruthy()
    expect(I.improvePlan().suggestions.some(x => x.type === 'addRoutine')).toBe(false)
  })
})

describe('equipment and level', () => {
  it('maps Settings equipment onto the planner', () => {
    expect(I.plannerEquipment()).toEqual(['gym', 'db', 'bench', 'band', 'bar', 'table'])
    SET.setEquipment(['dumbbell', 'band'])
    expect(I.plannerEquipment()).toEqual(['db', 'band'])
    SET.setEquipment(['barbell', 'cable', 'dumbbell'])
    expect(I.plannerEquipment()).toEqual(['gym', 'db', 'bench', 'bar'])
  })
  it('the level comes from the plan builder, else the history', () => {
    expect(I.userLevel()).toBe('novice')
    const plan = PL.generatePlan({ goal: 'muscle', experience: 'intermediate', days: 4, equipment: ['gym'] })
    PL.applyPlan(plan)
    expect(I.userLevel()).toBe('intermediate')
  })
})
