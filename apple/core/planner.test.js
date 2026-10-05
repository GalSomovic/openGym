import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as PL from './planner.js'
import * as L from './library.js'

beforeEach(() => A.load(null))

const allIds = plan => plan.routines.flatMap(r => r.ex.map(e => e.id))

describe('planner', () => {
  it('only uses exercises that exist in the catalogue', () => {
    const cat = new Set(L.catalogue().map(e => e.id))
    for (const eq of [['gym'], ['db', 'bench'], ['band'], [], ['bar', 'table']])
      for (const goal of ['health', 'muscle', 'strength', 'fatloss', 'balance'])
        for (const experience of ['none', 'intermediate', 'advanced'])
          for (const days of [2, 3, 4, 5, 6]) {
            const plan = PL.generatePlan({ goal, experience, days, equipment: eq })
            for (const id of allIds(plan)) expect(cat.has(id), `${id} in ${plan.preset}`).toBe(true)
            expect(plan.routines.every(r => r.ex.length >= 3), plan.preset).toBe(true)
          }
  })
  it('a bodyweight-only plan needs no equipment', () => {
    const plan = PL.generatePlan({ goal: 'muscle', experience: 'novice', days: 3, equipment: [] })
    const cat = Object.fromEntries(L.catalogue().map(e => [e.id, e]))
    expect(plan.preset).toBe('P04')
    expect(allIds(plan).every(id => cat[id].eq === 'body weight')).toBe(true)
  })
  it('picks the split from days and level (§13.2)', () => {
    expect(PL.generatePlan({ goal: 'muscle', experience: 'novice', days: 3, equipment: ['gym'] }).preset).toBe('P02')
    expect(PL.generatePlan({ goal: 'muscle', experience: 'intermediate', days: 4, equipment: ['gym'] }).preset).toBe('P06')
    expect(PL.generatePlan({ goal: 'muscle', experience: 'advanced', days: 6, equipment: ['gym'] }).preset).toBe('P09')
    expect(PL.generatePlan({ goal: 'strength', experience: 'novice', days: 3, equipment: ['gym'] }).preset).toBe('P08')
    expect(PL.generatePlan({ goal: 'health', experience: 'none', days: 2 }).preset).toBe('P01')
    expect(PL.generatePlan({ goal: 'muscle', experience: 'none', ageBand: '75+' }).preset).toBe('P11')
  })
  it('caps novices at 4 strength days', () => {
    const plan = PL.generatePlan({ goal: 'muscle', experience: 'none', days: 6, equipment: ['gym'] })
    expect(plan.schedule.length).toBeLessThanOrEqual(4)
  })
  it('trains every main movement at least twice a week on full body', () => {
    const plan = PL.generatePlan({ goal: 'muscle', experience: 'novice', days: 3, equipment: ['gym'] })
    expect(plan.schedule.map(s => s.day)).toEqual([1, 3, 5])
    expect(plan.routines.every(r => r.prog === 'double' && r.ex.every(e => e.mode === 'time' || e.repsMin < e.reps))).toBe(true)
  })
  it('fits short sessions with fewer sets', () => {
    const long = PL.generatePlan({ goal: 'muscle', experience: 'novice', days: 3, minutes: 60, equipment: ['gym'] })
    const short = PL.generatePlan({ goal: 'muscle', experience: 'novice', days: 3, minutes: 25, equipment: ['gym'] })
    const sets = p => p.routines[0].ex.reduce((t, e) => t + e.sets, 0)
    expect(sets(short)).toBeLessThan(sets(long))
  })
  it('symptoms keep the plan light and say to see a doctor', () => {
    const plan = PL.generatePlan({ goal: 'muscle', experience: 'advanced', days: 5, symptoms: true, equipment: ['gym'] })
    expect(plan.safety.level).toBe('stop')
    expect(['P01', 'P11']).toContain(plan.preset)
    expect(plan.routines.every(r => r.ex.every(e => e.sets <= 2))).toBe(true)
  })
  it('applies as ordinary routines on the chosen weekdays', () => {
    const plan = PL.generatePlan({ goal: 'muscle', experience: 'novice', days: 3, weekdays: [2, 4, 6], equipment: ['db', 'bench'] })
    expect(PL.planConflicts(plan)).toEqual([])
    const ids = PL.applyPlan(plan)
    const s = A.pick(['routines', 'week'])
    expect(s.routines.filter(r => ids.includes(r.id))).toHaveLength(2)
    expect([s.week[2], s.week[4], s.week[6]].every(d => ids.includes(d[0]))).toBe(true)
    expect(PL.planConflicts(plan)).toEqual([2, 4, 6])
  })
  it('lists presets for browsing, filled for the equipment', () => {
    const list = PL.presetList([])
    expect(list.length).toBeGreaterThanOrEqual(6)
    expect(list.every(x => x.plan.routines.length)).toBe(true)
  })
})
