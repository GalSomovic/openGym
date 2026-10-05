import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as N from './nutrition.js'

beforeEach(() => A.load(null))

describe('food math', () => {
  it('scales a per-100 g label to the grams eaten', () => {
    // 1 kg of something with 20 g protein, 10 g fat, 30 g carbs per 100 g
    expect(N.nutrientsFor({ p: 20, f: 10, c: 30 }, 1000)).toEqual({ kcal: 2900, p: 200, f: 100, c: 300 })
    expect(N.nutrientsFor({ kcal: 120, p: 3.3, f: 1.1, c: 21 }, 250)).toEqual({ kcal: 300, p: 8.3, f: 2.8, c: 52.5 })
  })
  it('derives calories from macros only when the label has none', () => {
    expect(N.normalizePer100({ p: 10, f: 0, c: 0 }).kcal).toBe(40)
    expect(N.normalizePer100({ kcal: 55, p: 10 }).kcal).toBe(55)
    expect(N.normalizePer100({ p: -3, f: 'x' })).toMatchObject({ p: 0, f: 0 })
  })
})

describe('food log', () => {
  it('logs one-off and saved foods and totals the day', () => {
    const rice = N.saveFood({ name: 'Rice, cooked', per100: { kcal: 130, p: 2.7, f: 0.3, c: 28 } })
    N.logFood('2026-10-05', { foodId: rice.id, grams: 200 })
    const day = N.logFood('2026-10-05', { name: 'Chicken breast', per100: { p: 31, f: 3.6, c: 0 }, grams: 150, save: true })
    expect(day.entries).toHaveLength(2)
    expect(day.total.p).toBeCloseTo(5.4 + 46.5, 1)
    expect(N.savedFoods()).toHaveLength(2)
    expect(N.savedFoods()[0].name).toBe('Chicken breast')
  })
  it('edits and removes entries; an emptied day disappears', () => {
    const d = N.logFood('2026-10-05', { name: 'Oats', per100: { p: 13, f: 7, c: 60 }, grams: 50 })
    N.updateEntry('2026-10-05', d.entries[0].id, { grams: 100 })
    expect(N.dayFood('2026-10-05').total.p).toBe(13)
    N.removeEntry('2026-10-05', d.entries[0].id)
    expect(A.pick('gfFoodLog').gfFoodLog).toEqual({})
  })
  it('is kept in the profile and survives a reload', () => {
    N.logFood('2026-10-05', { name: 'Egg', per100: { kcal: 143, p: 12.6, f: 9.5, c: 0.7 }, grams: 120 })
    const json = A.exportState()
    A.load(json)
    expect(N.dayFood('2026-10-05').total.kcal).toBe(171.6)
  })
})
