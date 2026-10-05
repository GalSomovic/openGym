// Plates you own and how each exercise loads (openGym sheets.jsx PlateInventorySheet,
// BarWeightEditor), headless, on openGym's frontend/src/lib/plates.js and bar.js.
import { need } from './actions.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import { PLATE_SIZES, ownsPlates, pairsOf, withPlatePairs, withStandardPlates, loadKindFor, withLoadKind, baseWeightFor } from '../../frontend/src/lib/plates.js'
import { usesBar, isNoBar, hasBarOverride, defaultBarWeight } from '../../frontend/src/lib/bar.js'

/** The plate list for the profile's unit: [{ w, n }] for every standard size, and whether it is your own. */
export function inventory() {
  const S = need()
  const unit = S.unit === 'lb' ? 'lb' : 'kg'
  return { unit, own: ownsPlates(S), plates: PLATE_SIZES[unit].map(w => ({ w, n: pairsOf(S, w) })) }
}

export function setPairs(w, n) {
  const S = need()
  S.plates = withPlatePairs(S, w, n)
  return inventory()
}

export function resetPlates() {
  const S = need()
  S.plates = withStandardPlates(S)
  return inventory()
}

/** An exercise's loading: kind (pairs / single / none), bar or base weight, "no bar", defaults. */
export function loading(exId, cfg = null) {
  const S = need()
  const ex = EXIDX[exId]
  if (!ex) return null
  const ctx = { ...(cfg || {}), id: exId }
  return {
    kind: loadKindFor(S, ctx), equipmentKind: loadKindFor(null, ctx),
    bar: usesBar(ex), noBar: usesBar(ex) && isNoBar(S, exId), explicit: hasBarOverride(S, exId),
    base: baseWeightFor(S, ex), defaultBar: defaultBarWeight(ex.eq, S.unit), unit: S.unit || 'kg',
  }
}

/** Sets how the exercise loads; picking what its equipment implies goes back to following it. */
export function setKind(exId, kind, cfg = null) {
  const S = need()
  const ctx = { ...(cfg || {}), id: exId }
  S.loadKind = withLoadKind(S.loadKind, exId, kind === loadKindFor(null, ctx) ? null : kind)
  return loading(exId, cfg)
}

/** The bar's (or machine's) own weight; 0 or less goes back to the default. */
export function setBase(exId, value) {
  const S = need()
  S.barWeights = S.barWeights || {}
  const n = Math.max(0, Math.round((value || 0) * 100) / 100)
  if (n > 0) S.barWeights[exId] = n
  else delete S.barWeights[exId]
  return loading(exId)
}

/** "No bar": the logged weight is all plates (a stored 0, unlike no entry at all). */
export function setNoBar(exId, on) {
  const S = need()
  S.barWeights = S.barWeights || {}
  if (on) S.barWeights[exId] = 0
  else delete S.barWeights[exId]
  return loading(exId)
}
