import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as W from './workout.js'
import * as P from './plan.js'

const ex = (o) => ({ id: 'r1', name: 'Push', emoji: 'dumbbell', ex: [o] })
const st = () => JSON.parse(A.exportState())
function start(cfg, extra = {}) {
  A.load(JSON.stringify({ routines: [ex(cfg)], ...extra }))
  A.beginWorkout(['r1'])
}

describe('entry view', () => {
  it('describes a weighted exercise: columns, plan line, best', () => {
    start({ id: '0025', sets: 3, reps: 5, weight: 60 })
    const v = W.entryView(0)
    expect(v.mode).toBe('reps')
    expect(v.cols[0]).toMatchObject({ f: 'w', hd: 'Weight (kg)' })
    expect(v.cols[1]).toMatchObject({ f: 'r', hd: 'Reps' })
    expect(v.cols[2]).toBeNull()
    expect(v.planLine).toMatch(/^Plan: 3 × 5/)
    expect(v.rows.map(r => r.num)).toEqual([1, 2, 3])
    expect(v.refText).toBeNull()
  })
  it('drops the weight column for bodyweight and shows effort when the profile logs it', () => {
    start({ id: '0001', sets: 2, reps: 15, weight: 0 }, { effort: 'rpe' })
    const v = W.entryView(0)
    expect(v.bw).toBe(true)
    expect(v.cols[0].f).toBe('r')
    expect(v.cols[1]).toBeNull()
    expect(v.cols[2]).toMatchObject({ f: 'rpe', hd: 'RPE' })
  })
  it('shows last time after a finished session, and the best set on request', () => {
    start({ id: '0025', sets: 1, reps: 5, weight: 60 })
    A.toggleSet(0, 0); A.finishWorkout()
    A.beginWorkout(['r1'])
    expect(W.entryView(0).refText).toMatch(/^Last time \(.+\): 60×5$/)
    W.toggleLogRef()
    expect(W.entryView(0).refText).toMatch(/^Best set/)
  })
  it('says how the plates go on', () => {
    start({ id: '0025', sets: 2, reps: 5, weight: 60 })
    const v = W.entryView(0)
    expect(v.plateLines['0'].text).toMatch(/per side/)
    expect(v.plateLines['1']).toBeUndefined()   // the same stack is shown once
  })
})

describe('set edits', () => {
  it('step weights on the load grid and carry them forward', () => {
    start({ id: '0025', sets: 3, reps: 5, weight: 60 })
    W.bump(0, 0, 'w', 1)
    const w = st().active.entries[0].sets.map(s => s.w)
    expect(w[0]).toBeGreaterThan(60)
    expect(w[1]).toBe(w[0])
    W.bump(0, 0, 'r', -1)
    expect(st().active.entries[0].sets[0].r).toBe(4)
  })
  it('steps effort along its scale from empty', () => {
    start({ id: '0025', sets: 1, reps: 5, weight: 60 }, { effort: 'rpe' })
    W.bump(0, 0, 'rpe', 1)
    expect(st().active.entries[0].sets[0].rpe).toBe(6)
    W.bump(0, 0, 'rpe', -1)
    expect(st().active.entries[0].sets[0].rpe).toBeUndefined()
  })
  it('add, edit and remove drops and bursts', () => {
    start({ id: '0025', sets: 1, reps: 8, weight: 60 })
    W.addDrop(0, 0)
    let row = st().active.entries[0].sets[0]
    expect(row.type).toBe('dropset')
    expect(row.drops[0].w).toBeLessThan(60)
    W.bumpDrop(0, 0, 0, 'r', 1)
    expect(st().active.entries[0].sets[0].drops[0].r).toBe(9)
    W.removeDrop(0, 0, 0)
    A.addSet(0)
    W.addBurst(0, 1)
    row = st().active.entries[0].sets[1]
    expect(row.type).toBe('restpause')
    expect(row.r).toBe(8 + row.clusters[0].r)
    W.setBurst(0, 1, 0, 1)
    expect(st().active.entries[0].sets[1].r).toBe(9)
  })
  it('log each side of a per-side set', () => {
    start({ id: '0025', sets: 1, reps: 10, weight: 20, side: true, mode: 'reps' })
    expect(W.entryView(0).rows[0].side).toBe(true)
    W.setSideValue(0, 0, 'L', 'r', 6)
    expect(st().active.entries[0].sets[0].sides.L.r).toBe(6)
    const out = A.toggleSet(0, 0, 'L')
    expect(out.checked).toBe(false)              // one side is not the whole set
    expect(A.toggleSet(0, 0, 'R').complete).toBe(true)
  })
  it('rebuild the rows from new settings and keep what was logged', () => {
    start({ id: '0025', sets: 3, reps: 5, weight: 60 })
    A.toggleSet(0, 0)
    const { config } = W.progressionStart(0)
    expect(config.sets).toBe(3)
    W.applyProgressionSettings(0, { ...config, sets: 5, reps: 3 })
    const sets = st().active.entries[0].sets
    expect(sets).toHaveLength(5)
    expect(sets[0].done).toBe(true)
    expect(sets[1].r).toBe(3)
  })
})
