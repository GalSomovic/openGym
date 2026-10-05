import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as T from './targets.js'

beforeEach(() => A.load(null))

// NUTRITION.md §12 worked examples
const manA = { age: 35, sex: 'male', height: 180, weight: 95, job: 'sitting', moderateMin: 180, goal: 'lose', rate: 0.5 }
const womanB = { age: 28, sex: 'female', height: 165, weight: 60, job: 'sitting', vigorousMin: 300, steps: 9000, goal: 'gain', experience: 'novice' }

describe('targets (NUTRITION.md worked examples)', () => {
  it('example A: 95 kg sedentary man losing weight', () => {
    const t = T.computeTargets(manA)
    expect(t.category).toBe('inactive')
    expect(t.ree).toBe(1910)
    expect(t.tee).toBe(2880)
    expect(t.kcal).toBe(2360)
    expect(t.protein).toBe(152)
    expect(t.fat).toBe(79)
    expect(t.carbs).toBeGreaterThanOrEqual(258)
    expect(t.carbs).toBeLessThanOrEqual(262)
    expect(t.fibre).toBe(33)
  })
  it('example B: 60 kg active woman building muscle', () => {
    const t = T.computeTargets(womanB)
    expect(t.category).toBe('active')
    expect(t.tee).toBe(2330)
    expect(t.kcal).toBe(2500)
    expect(t.protein).toBe(96)
    expect(t.fat).toBe(83)
  })
  it('example C: under 18 gets no targets', () => {
    expect(T.computeTargets({ ...womanB, age: 17 }).gate.level).toBe('stop')
    expect(T.computeTargets({ ...womanB, age: 17 }).kcal).toBeUndefined()
  })
})

describe('safety', () => {
  it('stops for pregnancy, eating-disorder history, and losing while underweight', () => {
    expect(T.gate({ ...womanB, pregnant: true }).level).toBe('stop')
    expect(T.gate({ ...womanB, eatingDisorder: true }).level).toBe('stop')
    expect(T.gate({ ...womanB, scoff: 2 }).level).toBe('stop')
    expect(T.gate({ ...womanB, weight: 48, goal: 'lose' }).level).toBe('stop')
  })
  it('a clinician-first condition keeps maintenance until confirmed', () => {
    const t = T.computeTargets({ ...manA, diabetesMeds: true })
    expect(t.goal).toBe('maintain')
    expect(t.kcal).toBe(t.tee)
    expect(T.computeTargets({ ...manA, diabetesMeds: true, clinicianOk: true }).goal).toBe('lose')
  })
  it('never goes under the floor, however fast the asked rate', () => {
    const small = { age: 40, sex: 'female', height: 155, weight: 70, job: 'sitting', goal: 'lose', rate: 1.0 }
    const t = T.computeTargets(small)
    expect(t.kcal).toBeGreaterThanOrEqual(1200)
    expect(t.kcal).toBeGreaterThanOrEqual(t.ree - 10)
  })
  it('caps the rate for lean people and over-65s', () => {
    expect(T.computeTargets({ ...manA, weight: 72, rate: 1.0 }).rate).toBeLessThanOrEqual(0.7)
    expect(T.computeTargets({ ...manA, age: 70, rate: 1.0 }).rate).toBeLessThanOrEqual(0.5)
  })
  it('kidney disease: no protein target, information only', () => {
    const t = T.computeTargets({ ...manA, kidney: true, clinicianOk: true })
    expect(t.protein).toBeNull()
    expect(t.proteinInfo).toBe(76)
  })
  it('obesity uses the weight at BMI 25 for protein', () => {
    const t = T.computeTargets({ ...manA, weight: 130 })
    expect(t.protein).toBe(Math.round(1.6 * 25 * 1.8 * 1.8))
  })
})

describe('weekly correction', () => {
  it('moves halfway toward the observed TEE, at most 200 kcal (worked example A, week 5)', () => {
    const today = '2026-02-05'
    const day = i => new Date(Date.parse(today) - (21 - i) * 864e5).toISOString().slice(0, 10)
    const weighIns = Array.from({ length: 21 }, (_, i) => ({ d: day(i), w: 95 - 0.05 * i }))
    const intake = Array.from({ length: 21 }, (_, i) => ({ iso: day(i), kcal: 2300, complete: true }))
    const r = T.adapt({ teeNow: 2884, teeEquation: 2884, weighIns, intake, today })
    expect(r.ok).toBe(true)
    expect(r.observed).toBe(2690)
    expect(r.tee).toBe(2780)
  })
  it('needs enough weigh-ins and logged days', () => {
    expect(T.adapt({ teeNow: 2500, teeEquation: 2500, weighIns: [], intake: [], today: '2026-02-05' }).reason).toBe('weighIns')
  })
  it('saves answers in the profile and reads the latest weigh-in', () => {
    A.patch({ bodyweight: [{ d: '2026-10-01', w: 96 }, { d: '2026-10-05', w: 95 }] })
    const t = T.saveProfile({ age: 35, sex: 'male', height: 180, job: 'sitting', moderateMin: 180, goal: 'lose', rate: 0.5 })
    expect(t.kcal).toBe(2360)
    A.load(A.exportState())
    expect(T.currentTargets().kcal).toBe(2360)
  })
})
