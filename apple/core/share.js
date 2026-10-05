// Share a plan (openGym Plan → Share your plan, sheets.jsx PlanTools/PlanImport): a small file of
// routines only, imported by MERGING; and the printable week. All logic is openGym's
// frontend/src/lib/plan-share.js.
import { need } from './actions.js'
import { buildPlanBundle, parsePlan, mergePlan, planPrintHTML } from '../../frontend/src/lib/plan-share.js'

/** The plan file (JSON text), or null when no routine has an exercise. */
export function exportPlan(name = '') {
  const S = need()
  if (!(S.routines || []).some(r => r.ex && r.ex.length)) return null
  return JSON.stringify(buildPlanBundle(S, name), null, 2)
}

let pending = null

/** Reads a plan file and keeps it for `importPlan`: { name, routineCount, exerciseCount, scheduledDays, dropped }. */
export function previewPlan(text) {
  pending = parsePlan(text, need().unit || 'kg')
  const { name, routineCount, exerciseCount, scheduledDays, dropped } = pending
  return { name: name || '', routineCount, exerciseCount, scheduledDays: scheduledDays || 0, dropped: dropped || 0 }
}

/** Adds the previewed plan's routines; `schedule` also replaces the weekly assignments. */
export function importPlan(schedule = false) {
  if (!pending) return false
  mergePlan(need(), pending, { schedule })
  pending = null
  return true
}

/** The printable week as HTML (one page per plan, exercises never split across pages). */
export function printHTML(owner = '') {
  return planPrintHTML(need(), owner)
}
