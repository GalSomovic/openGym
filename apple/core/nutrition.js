// Optional food log (GymFree addition, not in openGym): foods by what their label says per
// 100 g, entries by the weight eaten. No meal plans, no network calls: the user types a label
// once (or picks a food from the bundled USDA database, which only fills in the per-100 g values),
// saves it, and logs grams. Stored in the profile as `gfFoods` and `gfFoodLog`, so backups carry
// it and openGym ignores it. `src` (e.g. "usda:168878") records where bundled values came from.
import { need } from './actions.js'

const KCAL = { p: 4, c: 4, f: 9 }
const round1 = x => Math.round(x * 10) / 10

/** Energy from macros (Atwater factors) when a label gives grams but no calories. */
export function kcalFromMacros({ p = 0, f = 0, c = 0 } = {}) {
  return KCAL.p * p + KCAL.f * f + KCAL.c * c
}

/** Clean per-100 g values: numbers, never negative, calories derived when missing. */
export function normalizePer100(per100 = {}) {
  const num = v => (Number.isFinite(+v) && +v > 0 ? +v : 0)
  const out = { p: num(per100.p), f: num(per100.f), c: num(per100.c) }
  if (per100.fiber != null) out.fiber = num(per100.fiber)
  out.kcal = per100.kcal != null && per100.kcal !== '' ? num(per100.kcal) : round1(kcalFromMacros(out))
  return out
}

/** What `grams` of a food with these per-100 g values contains. */
export function nutrientsFor(per100, grams) {
  const n = normalizePer100(per100)
  const k = (Number.isFinite(+grams) && +grams > 0 ? +grams : 0) / 100
  const out = { kcal: round1(n.kcal * k), p: round1(n.p * k), f: round1(n.f * k), c: round1(n.c * k) }
  if (n.fiber != null) out.fiber = round1(n.fiber * k)
  return out
}

function foods(S) { return (S.gfFoods = Array.isArray(S.gfFoods) ? S.gfFoods : []) }
function log(S) { return (S.gfFoodLog = S.gfFoodLog && typeof S.gfFoodLog === 'object' ? S.gfFoodLog : {}) }
const newId = p => p + Date.now().toString(36) + Math.random().toString(36).slice(2, 6)

/** Saved foods, most recently used first. */
export function savedFoods() {
  return foods(need()).slice().sort((a, b) => (b.used || 0) - (a.used || 0))
}

/**
 * Saves (or updates, with `id`) a food by its per-100 g label. A food from the bundled database
 * (`src`) is saved once: picking it again updates that saved food instead of adding a copy.
 */
export function saveFood({ id, name, per100, src }) {
  const S = need()
  const list = foods(S)
  const clean = { name: String(name || '').trim() || 'Food', per100: normalizePer100(per100) }
  if (src) clean.src = String(src)
  const existing = (id && list.find(x => x.id === id)) || (src && list.find(x => x.src === String(src)))
  if (existing) { Object.assign(existing, clean); return existing }
  const food = { id: newId('food'), ...clean, used: 0 }
  list.push(food)
  return food
}

export function deleteFood(id) {
  const S = need()
  S.gfFoods = foods(S).filter(x => x.id !== id)
  return true
}

/**
 * Logs what was eaten on a day: a saved food (`foodId`) or a one-off label (`name`, `per100`),
 * and the grams. `save: true` also keeps a one-off label as a saved food.
 */
export function logFood(iso, { foodId, name, per100, grams, save, src }) {
  const S = need()
  let food = foodId ? foods(S).find(x => x.id === foodId) : null
  if (!food && save) food = saveFood({ name, per100, src })
  const label = food ? food.per100 : normalizePer100(per100)
  const entry = { id: newId('fe'), name: food ? food.name : String(name || '').trim() || 'Food', grams: +grams || 0, per100: label }
  if (src || food?.src) entry.src = String(src || food.src)
  if (food) {
    entry.foodId = food.id
    // Strictly increasing, so two foods logged in the same millisecond still sort by order.
    food.used = Math.max(Date.now(), ...foods(S).map(x => (x.used || 0) + 1))
  }
  ;(log(S)[iso] = log(S)[iso] || []).push(entry)
  return dayFood(iso)
}

export function updateEntry(iso, entryId, { grams }) {
  const e = (log(need())[iso] || []).find(x => x.id === entryId)
  if (e && grams != null) e.grams = +grams || 0
  return dayFood(iso)
}

export function removeEntry(iso, entryId) {
  const S = need()
  const day = (log(S)[iso] || []).filter(x => x.id !== entryId)
  if (day.length) log(S)[iso] = day
  else delete log(S)[iso]
  return dayFood(iso)
}

/** A day's entries with what each contains, and the day's totals. */
export function dayFood(iso) {
  const entries = (log(need())[iso] || []).map(e => ({ ...e, amount: nutrientsFor(e.per100, e.grams) }))
  const total = { kcal: 0, p: 0, f: 0, c: 0 }
  for (const e of entries) for (const k of Object.keys(total)) total[k] += e.amount[k]
  for (const k of Object.keys(total)) total[k] = round1(total[k])
  return { iso, entries, total }
}

/** Daily totals for a range of days (oldest first), for the weekly view and adaptive targets. */
export function foodHistory(isos) {
  return isos.map(iso => {
    const d = dayFood(iso)
    return { iso, total: d.total, logged: d.entries.length > 0 }
  })
}
