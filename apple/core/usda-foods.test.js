// Sanity checks on the bundled USDA food database (apple/mediatools/usda_foods.py output).
import { describe, it, expect } from 'vitest'
import { readFileSync, statSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const path = fileURLToPath(new URL('../App/GymFree/Food/usda-foods.json', import.meta.url))
const db = JSON.parse(readFileSync(path, 'utf8'))
const F = Object.fromEntries(db.fields.map((k, i) => [k, i]))
const byName = new Map(db.foods.map(r => [r[F.name], r]))
const food = name => {
  const r = byName.get(name)
  expect(r, name).toBeDefined()
  return Object.fromEntries(db.fields.map((k, i) => [k, r[i]]))
}

describe('USDA food database', () => {
  it('credits its source and stays small', () => {
    expect(db.credit).toBe('U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.')
    expect(db.licence).toMatch(/CC0/)
    expect(db.releases['SR Legacy']).toBe('2018-04')
    expect(db.releases['Foundation Foods']).toMatch(/^\d{4}-\d{2}-\d{2}$/)
    expect(statSync(path).size).toBeLessThan(3e6)
    expect(db.foods.length).toBeGreaterThan(7000)
    expect(db.fields).toEqual(['fdcId', 'name', 'category', 'kcal', 'p', 'f', 'c', 'fiber', 'common', 'portions'])
  })

  it('has the right values for well-known foods', () => {
    const rice = food('Rice, white, long-grain, regular, enriched, cooked')
    expect(rice.kcal).toBeCloseTo(130, -1)
    expect(rice.portions).toContainEqual(['1 cup', 158])
    const chicken = food('Chicken, breast, meat only, cooked, roasted')
    expect(chicken.kcal).toBeCloseTo(165, -1)
    expect(chicken.p).toBeCloseTo(31, 0)
    const egg = food('Egg, whole, raw, fresh')
    expect(egg.kcal).toBeCloseTo(143, -1)
    expect(egg.portions).toContainEqual(['1 large', 50])
    expect(food('Oil, olive, salad or cooking').f).toBeGreaterThan(99)
  })

  it('stores available carbohydrate (fibre taken out) and fibre separately', () => {
    // USDA oats: carbohydrate by difference 66.3 g, fibre 10.6 g
    const oats = food('Oats')
    expect(oats.fiber).toBeCloseTo(10.6, 1)
    expect(oats.c).toBeCloseTo(66.3 - 10.6, 0)
  })

  it('every row is well formed and energy roughly matches the macros', () => {
    const ids = new Set()
    let off = 0
    for (const r of db.foods) {
      const [id, name, cat, kcal, p, f, c, fiber, common, portions] = r
      expect(ids.has(id)).toBe(false); ids.add(id)
      expect(name.length).toBeGreaterThan(1)
      expect(name).not.toMatch(/Food Distribution Program|broilers or fryers|  /)
      expect(db.categories[cat]).toBeDefined()
      for (const x of [kcal, p, f, c, fiber, common]) expect(x).toBeGreaterThanOrEqual(0)
      expect(p + f + c + fiber).toBeLessThanOrEqual(101)
      for (const [label, g] of portions) { expect(label).toMatch(/^\S+ \S/); expect(g).toBeGreaterThan(0) }
      // Atwater: 4·P + 9·F + 4·C + 2·fibre, within 20% or 15 kcal (alcohol, polyols, and organic acids differ)
      const est = 4 * p + 9 * f + 4 * c + 2 * fiber
      if (Math.abs(est - kcal) > Math.max(15, 0.2 * kcal)) off++
    }
    expect(off / db.foods.length).toBeLessThan(0.02)
  })

  it('lists everyday foods for search ranking', () => {
    const common = db.foods.filter(r => r[F.common] > 0)
    expect(common.length).toBeGreaterThan(60)
    expect(food('Chicken, breast, meat only, cooked, roasted').common).toBeGreaterThan(0)
  })
})
