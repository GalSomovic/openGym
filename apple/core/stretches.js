// Cool-down stretches (GymFree addition, not in openGym). TRAINING.md §10: static stretching
// does not prevent injury and, held 60 s or more per muscle, lowers performance for a while
// afterwards, so it is never put before lifting; after the session it is optional and harmless.
// GymFree only ever offers it as a suggestion at the end of a routine.
import { EXIDX } from '../../frontend/src/lib/exercises.js'

// Muscle (the body map's slugs, lib/muscles.js) → stretches for it, best first. The `gf-` ones
// are DVIDS demo videos (extras-dvids.js) and come first; ExerciseDB stretches fill the gaps.
// `side`: done one side at a time, so the hold is planned once per side.
// Everything here is body weight: a cool-down should never need equipment.
export const STRETCHES = {
  chest: [{ id: 'gf-long-arm-chest-stretch', side: true }, { id: '1271' }],
  deltoids: [{ id: 'gf-cross-body-shoulder-stretch', side: true }, { id: '0669', side: true }],
  trapezius: [{ id: '1365' }, { id: 'gf-cross-body-shoulder-stretch', side: true }],
  'upper-back': [{ id: 'gf-childs-pose' }, { id: '1346', side: true }, { id: '1365' }],
  serratus: [{ id: 'gf-childs-pose' }],
  biceps: [{ id: 'gf-long-arm-chest-stretch', side: true }],
  triceps: [{ id: '0643', side: true }, { id: '0817', side: true }],
  forearm: [{ id: 'gf-kneeling-wrist-stretch' }],
  abs: [{ id: '1366' }],
  obliques: [{ id: 'gf-standing-side-bend', side: true }, { id: '0794', side: true }],
  'lower-back': [{ id: 'gf-childs-pose' }, { id: 'gf-supine-knee-to-chest', side: true }],
  gluteal: [{ id: 'gf-figure-4-stretch', side: true }, { id: '1424', side: true }],
  quadriceps: [{ id: 'gf-standing-quad-stretch', side: true }, { id: 'gf-couch-stretch', side: true }],
  hamstring: [{ id: 'gf-passive-strap-hamstring-stretch', side: true }, { id: '1511', side: true }],
  adductors: [{ id: 'gf-sumo-squat-stretch' }, { id: '1494' }],
  'hip-flexors': [{ id: 'gf-half-kneeling-hip-flexor-stretch', side: true }, { id: 'gf-couch-stretch', side: true }],
  calves: [{ id: '1377', side: true }, { id: '1398', side: true }],
  tibialis: [{ id: 'gf-seated-tibialis-stretch', side: true }],
}

const LISTED = new Set(Object.values(STRETCHES).flat().map(c => c.id))
const SIDED = new Set(Object.values(STRETCHES).flat().filter(c => c.side).map(c => c.id))

/**
 * Whether an exercise is a stretch rather than training: the list above, plus anything in the
 * catalogue named "… stretch" (but not a loaded lunge or a bridge that only mentions one).
 * Stretches carry no training load, so the muscle maps and set counts leave them out.
 */
export function isStretch(id) {
  if (LISTED.has(id)) return true
  const n = EXIDX[id]?.n || ''
  return /\bstretch\b/i.test(n) && !/weighted|bridge/i.test(n)
}

// Engineering defaults (§10 gives no hold length for a cool-down): one 30 s hold per side, or a
// single 45 s hold, both under the 60 s/muscle at which §10's performance cost appears; a 10 s
// rest is time to switch sides.
const HOLD_SIDE = 30
const HOLD_BOTH = 45

/** The routine slot for a stretch: a timed hold, once per side when it is one-sided. */
export function stretchConfig(id) {
  const side = SIDED.has(id)
  return side
    ? { sets: 2, mode: 'time', sec: HOLD_SIDE, weight: 0, bodyweight: true, restSec: 10, note: 'One hold per side' }
    : { sets: 1, mode: 'time', sec: HOLD_BOTH, weight: 0, bodyweight: true, restSec: 10 }
}

// Stretch → every muscle it is listed for, so one stretch covers them all (the long-arm chest
// stretch does chest and biceps).
const COVERS = {}
for (const [m, list] of Object.entries(STRETCHES)) for (const c of list) (COVERS[c.id] ||= []).push(m)

/**
 * Up to `count` stretches for `muscles` (most-worked first), one per muscle not already covered
 * by a stretch picked before, never repeating a stretch or one in `exclude`. `ok(id)` can veto
 * one (for example, equipment). Returns exercise ids.
 */
export function pickStretches(muscles, count = 3, exclude = [], ok = () => true) {
  const out = []
  const covered = new Set()
  const skip = new Set(exclude)
  const usable = c => !!EXIDX[c.id] && !skip.has(c.id) && !out.includes(c.id) && ok(c.id)
  for (const m of muscles) {
    if (out.length >= count) break
    if (covered.has(m)) continue
    const c = (STRETCHES[m] || []).find(usable)
    if (c) { out.push(c.id); (COVERS[c.id] || []).forEach(x => covered.add(x)) }
  }
  return out
}
