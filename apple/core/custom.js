// Your own exercises (openGym sheets.jsx CustomExForm / deleteCustomEx), headless. Stored in
// `customEx` exactly as openGym stores them, so backups move between the two apps. Photos and
// videos (openGym's custom media) are not handled here yet.
import { need, patch } from './actions.js'
import { BODYPARTS, allExercises, EXIDX } from '../../frontend/src/lib/exercises.js'
import { ALL_EQUIPMENT } from '../../frontend/src/lib/equipment.js'
import { MUSCLES, MUSCLE_NAME, inMuscleOrder, exerciseMuscleSnapshot } from '../../frontend/src/lib/muscles.js'
import { cleanupSg } from '../../frontend/src/lib/history.js'
import { uid } from '../../frontend/src/lib/format.js'

/** What the form offers: body parts, equipment, muscles with their display names. */
export function options() {
  return { bodyParts: BODYPARTS, equipment: ALL_EQUIPMENT, muscles: MUSCLES.map(id => ({ id, name: MUSCLE_NAME[id] || id })) }
}

/** A custom exercise as stored, or null. */
export function get(id) {
  return (need().customEx || []).find(x => x.id === id) || null
}

/**
 * Creates or (with `id`) edits a custom exercise. Same rules as openGym: a name, a body part and
 * equipment are required, names are unique, muscles are kept in the body map's order, and the
 * one-word target stays the first primary picked. Returns { id } or { error }.
 */
export function save({ id, n, bp, eq, desc = '', primaries = [], secondaries = [] }) {
  const S = need()
  const name = String(n || '').trim()
  if (!name) return { error: 'name' }
  if (!bp) return { error: 'bodyPart' }
  if (!eq) return { error: 'equipment' }
  const dup = allExercises(S).find(e => e.n.toLowerCase() === name.toLowerCase() && e.id !== id)
  if (dup) return { error: 'duplicate', name: dup.n }
  const prim = bp === 'cardio' ? ['cardiovascular system'] : inMuscleOrder(primaries)
  const sm = inMuscleOrder(secondaries.filter(m => !prim.includes(m)))
  const existing = id && get(id)
  const tg = existing && prim.includes(existing.tg) ? existing.tg : (primaries.find(m => prim.includes(m)) || prim[0] || '')
  const fields = { n: name, bp, desc: String(desc || '').trim().slice(0, 1000), tg, sm, muscleGroups: [...prim, ...sm], primaries: prim, secondaries: sm, eq }
  const list = [...(S.customEx || [])]
  if (existing) Object.assign(list.find(x => x.id === id), fields)
  else list.push({ id: (id = 'c' + uid()), ...fields, custom: true })
  patch({ customEx: list })            // re-registers the custom catalogue
  return { id }
}

/** Deletes a custom exercise: out of routines and favourites; logged workouts keep their sets and name. */
export function remove(id) {
  const S = need()
  const ex = get(id)
  if (!ex) return false
  if (S.active?.entries.some(e => e.id === id)) return { error: 'active' }
  const snapshot = exerciseMuscleSnapshot(ex)
  S.workouts.forEach(w => w.entries.forEach(e => {
    if (e.id !== id) return
    e.n = ex.n
    if (!e.muscleSnapshot || !Object.keys(e.muscleSnapshot).length) e.muscleSnapshot = snapshot
  }))
  S.routines.forEach(r => { r.ex = r.ex.filter(e => e.id !== id); cleanupSg(r.ex) })
  delete (S.exWeights || {})[id]
  S.favEx = (S.favEx || []).filter(x => x !== id)
  patch({ customEx: (S.customEx || []).filter(x => x.id !== id) })
  return !EXIDX[id] || true
}
