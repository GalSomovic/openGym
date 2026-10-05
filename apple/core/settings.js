// Settings that change the profile (views/Settings.jsx), headless.
import { need } from './actions.js'
import { ALL_EQUIPMENT, activeProfile, newProfile, exAvailable } from '../../frontend/src/lib/equipment.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import { effortOf } from '../../frontend/src/lib/history.js'
import { speedUnitOf } from '../../frontend/src/lib/speed.js'
import { weekStartOf } from '../../frontend/src/lib/format.js'

/** Body weight is always available (lib/equipment.js), so it is never a choice. */
const ALWAYS = 'body weight'
const MINE = 'eq-mine'

/**
 * The equipment you have, as openGym's equipment profiles (S.equipProfiles): `all` is every
 * kind in the catalogue, most common first; `selected` what the active profile owns (all of it
 * when filtering is off).
 */
export function equipment() {
  const S = need()
  const choices = ALL_EQUIPMENT.filter(e => e !== ALWAYS)
  const p = activeProfile(S)
  return { all: choices, selected: p ? choices.filter(e => (p.equipment || []).includes(e)) : choices, filterOn: !!p, profile: p ? p.name : null }
}

/**
 * Sets what you own. Everything selected turns the filter off, so new equipment in a later
 * catalogue is never hidden by default; anything less keeps one profile and filters by it.
 */
export function setEquipment(selected, name = 'My equipment') {
  const S = need()
  const choices = ALL_EQUIPMENT.filter(e => e !== ALWAYS)
  const owned = choices.filter(e => selected.includes(e))
  S.equipProfiles = Array.isArray(S.equipProfiles) ? S.equipProfiles : []
  if (owned.length === choices.length) {
    S.equipFilterOn = false
    return equipment()
  }
  let p = S.equipProfiles.find(x => x.id === S.activeEquipId) || S.equipProfiles.find(x => x.id === MINE)
  if (!p) {
    p = { ...newProfile(name), id: MINE }
    S.equipProfiles.push(p)
  }
  p.equipment = owned
  S.activeEquipId = p.id
  S.equipFilterOn = true
  return equipment()
}

/** The exercises of a routine that need equipment you do not have, by index. */
export function missingEquipment(rid) {
  const S = need()
  const p = activeProfile(S)
  const r = S.routines.find(x => x.id === rid)
  if (!p || !r) return []
  return r.ex.map((e, i) => (EXIDX[e.id] && !exAvailable(S, EXIDX[e.id]) ? i : -1)).filter(i => i >= 0)
}

/**
 * The General and During a workout settings, read the way openGym's Settings screen reads them:
 * an absent or legacy value shows as what it means (speed follows the weight unit until chosen,
 * effort from the old showRir switch, the plan unless "last" was picked).
 */
export function prefs() {
  const S = need()
  return {
    unit: S.unit === 'lb' ? 'lb' : 'kg', speedUnit: speedUnitOf(S), wdec: S.wdec === 2 ? 2 : 1,
    weekStart: weekStartOf(S), effort: effortOf(S), startFrom: S.startFrom === 'last' ? 'last' : 'plan',
    restSec: Number.isFinite(S.restSec) ? S.restSec : 90, restPauseSec: S.restPauseSec || 15,
    timedSetOvertime: !!S.timedSetOvertime, keepAwake: S.keepAwake !== false, weighIn: S.weighIn !== false,
    sound: !!S.sound, vibrate: S.vibrate !== false,
  }
}

/** Effort per set: 'none', 'rir' or 'rpe'. The legacy showRir switch goes with it, as in openGym. */
export function setEffort(kind) {
  const S = need()
  S.effort = kind === 'rir' || kind === 'rpe' ? kind : 'none'
  delete S.showRir
  return prefs()
}
