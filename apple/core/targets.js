// Optional calorie and macro targets (GymFree addition, not in openGym). Every formula and
// threshold is apple/research/NUTRITION.md §12 ("Algorithm spec"), step by step; step numbers
// are in the comments. Nothing here is a meal plan: it is a daily target and a split. The
// answers live in the profile as `gfNutrition`, so backups carry them and openGym ignores them.
import { need } from './actions.js'
import { todayISO } from '../../frontend/src/lib/format.js'

const LB = 0.45359237
const round10 = x => Math.round(x / 10) * 10
const round = x => Math.round(x)

/* ------------------------------ step 0: gate ------------------------------ */

/**
 * Whether targets may be shown. `stop`: never (under 18, pregnant, eating-disorder history or a
 * screen score of 2+, losing at BMI under 18.5). `clinician`: maintenance only until the user
 * confirms they have checked with their clinician.
 */
export function gate(p) {
  const bmi = p.weight / (p.height / 100) ** 2
  if (p.age < 18) return { level: 'stop', reason: 'age' }
  if (p.pregnant) return { level: 'stop', reason: 'pregnant' }
  if (p.eatingDisorder || (p.scoff || 0) >= 2) return { level: 'stop', reason: 'ed' }
  if (p.goal === 'lose' && bmi < 18.5) return { level: 'stop', reason: 'underweight' }
  const clinician = p.breastfeeding || p.diabetesMeds || p.kidney || p.chronic || p.weightLossMeds ||
    (p.age >= 65 && p.frail) || bmi >= 40 || (bmi >= 35 && p.comorbidity)
  if (clinician && !p.clinicianOk) return { level: 'clinician', reason: p.kidney ? 'kidney' : bmi >= 35 ? 'bmi' : 'condition' }
  return { level: 'ok', reason: null }
}

/* ------------------------------ steps 1–2: energy ------------------------------ */

/** Mifflin–St Jeor resting energy (step 1). `sex`: 'male' | 'female' (equation choice). */
export function ree({ weight: W, height: H, age: A, sex }) {
  return 10 * W + 6.25 * H - 5 * A + (sex === 'male' ? 5 : -161)
}

/** Activity-minutes-equivalent per day → NASEM category (step 2; NUTRITION.md §3.1). */
export function activityCategory({ job = 0, moderateMin = 0, vigorousMin = 0, steps = 0 }) {
  const jobMin = { sitting: 0, feet: 45, manual: 90 }[job] ?? Number(job) ?? 0
  const ame = jobMin + (moderateMin + 2 * vigorousMin) / 7 + Math.max(0, (steps || 0) - 5000) / 100
  const category = ame < 35 ? 'inactive' : ame < 100 ? 'low' : ame < 185 ? 'active' : 'very'
  return { ame: Math.round(ame), category }
}

const NASEM = {
  male: { inactive: [753.07, 6.50, 14.10], low: [581.47, 8.30, 14.94], active: [1004.82, 6.52, 15.91], very: [-517.88, 15.61, 19.11] },
  female: { inactive: [584.90, 5.72, 11.71], low: [575.77, 6.60, 12.14], active: [710.25, 6.54, 12.34], very: [511.83, 9.07, 12.56] },
}

/** Total energy, National Academies 2023 doubly-labelled-water equations (step 2). */
export function tee({ weight: W, height: H, age: A, sex }, category) {
  const [c, h, w] = NASEM[sex === 'male' ? 'male' : 'female'][category]
  return c - (sex === 'male' ? 10.83 : 7.01) * A + h * H + w * W
}

/* ------------------------------ steps 3–7: the target ------------------------------ */

/**
 * The daily target for a profile:
 *   { age, sex, height (cm), weight (kg), job, moderateMin, vigorousMin, steps,
 *     goal: 'lose' | 'maintain' | 'gain', rate (%/week), experience: 'novice' | 'intermediate' | 'advanced',
 *     waist (cm), keepMuscle, fatShare: 0.225 | 0.30 | 0.40, proteinGkg, teeOverride }
 * Returns kcal, protein/fat/carb grams, fibre, and the notes to show with them.
 */
export function computeTargets(p) {
  const g = gate(p)
  if (g.level === 'stop') return { gate: g }
  const W = p.weight, H = p.height
  const bmi = W / (H / 100) ** 2
  const whtr = p.waist ? p.waist / H : null
  const R = ree(p)
  const act = activityCategory(p)
  const T = p.teeOverride || tee(p, act.category)
  const notes = []
  let goal = g.level === 'clinician' ? 'maintain' : p.goal || 'maintain'
  if (g.level === 'clinician') notes.push('clinician')

  // Step 3
  let target = T, rate = 0
  if (goal === 'lose') {
    const lean = bmi < 25 || p.keepMuscle
    let maxRate = lean ? 0.7 : 1.0
    if (p.age >= 65) maxRate = 0.5
    rate = Math.min(p.rate || 0.5, maxRate)
    if ((p.rate || 0.5) > maxRate) notes.push('rateCapped')
    const cap = Math.min(0.25 * T, 1000, lean ? 500 : Infinity)
    target = T - Math.min(1100 * rate / 100 * W, cap)
  } else if (goal === 'gain') {
    if (bmi >= 27 || (whtr && whtr >= 0.5)) notes.push('recomp')
    rate = { novice: 0.25, intermediate: 0.15, advanced: 0.10 }[p.experience || 'novice']
    const surplus = Math.min(Math.max(1100 * rate / 100 * W, 0.05 * T), 0.15 * T)
    target = T + surplus
  }

  // Step 4: floors (never below 1,200; women 1,200 / men 1,500, and not below resting energy)
  const floor = Math.max(p.sex === 'male' ? 1500 : 1200, R)
  if (target < floor) {
    target = floor
    rate = Math.max(0, (T - target) / (1100 * W) * 100)
    notes.push('floor')
  }

  // Step 5: protein (BMI 30+: the weight at BMI 25 is the basis)
  const basisW = bmi < 30 ? W : 25 * (H / 100) ** 2
  let gkg = p.proteinGkg || 1.6
  if (p.age >= 65) gkg = Math.max(1.2, gkg)
  gkg = Math.min(2.2, Math.max(1.2, gkg))
  let P = p.kidney ? null : gkg * basisW
  if (p.kidney) notes.push('kidneyProtein')

  // Step 6: fat (share of energy, never below 20% or 0.5 g/kg)
  const share = p.fatShare || 0.30
  let F = Math.max(share * target / 9, 0.20 * target / 9, 0.5 * basisW)

  // Step 7: carbs are the rest; protect a sensible minimum by easing protein, then fat
  let C = (target - 4 * (P || 0) - 9 * F) / 4
  if (C < 50 && P) {
    P = Math.max(1.6 * basisW, (target - 9 * F - 4 * 50) / 4)
    C = (target - 4 * P - 9 * F) / 4
  }
  if (C < 50) {
    F = Math.max(0.20 * target / 9, (target - 4 * (P || 0) - 4 * 50) / 9)
    C = (target - 4 * (P || 0) - 9 * F) / 4
  }
  if (C < 130) notes.push('lowCarb')

  return {
    gate: g, bmi: Math.round(bmi * 10) / 10, whtr: whtr && Math.round(whtr * 100) / 100,
    ree: round10(R), tee: round10(T), category: act.category, ame: act.ame,
    goal, rate: Math.round(rate * 100) / 100, kgPerWeek: Math.round(rate / 100 * W * 100) / 100,
    kcal: round10(target), protein: P == null ? null : round(P), fat: round(F), carbs: round(Math.max(0, C)),
    fibre: round(Math.max(25, 14 * target / 1000)),
    proteinInfo: p.kidney ? round(0.8 * W) : null,
    notes,
  }
}

/* ------------------------------ step 9: weekly correction ------------------------------ */

const dayMs = 864e5
const isoDays = (a, b) => Math.round((Date.parse(b) - Date.parse(a)) / dayMs)

/**
 * The adaptive correction (step 9): from the last 21 days of logged food and weigh-ins, an
 * observed TEE, moved halfway toward and at most 200 kcal from the current one. Returns null
 * when there is not enough data (or it is implausible), with the reason.
 */
export function adapt({ teeNow, teeEquation, weighIns, intake, today }) {
  const end = today, start = new Date(Date.parse(today) - 21 * dayMs).toISOString().slice(0, 10)
  const win = weighIns.filter(x => x.d >= start && x.d < end)
  const days = intake.filter(x => x.iso >= start && x.iso < end)
  const complete = days.filter(x => x.complete)
  if (win.length < 10) return { ok: false, reason: 'weighIns' }
  if (complete.length < 16) return { ok: false, reason: 'logging' }
  // Drop weigh-ins more than 2.5 kg from the median
  const sorted = win.map(x => x.w).sort((a, b) => a - b)
  const median = sorted[Math.floor(sorted.length / 2)]
  const pts = win.filter(x => Math.abs(x.w - median) <= 2.5).map(x => [isoDays(start, x.d), x.w])
  const n = pts.length, sx = pts.reduce((t, [x]) => t + x, 0), sy = pts.reduce((t, [, y]) => t + y, 0)
  const sxx = pts.reduce((t, [x]) => t + x * x, 0), sxy = pts.reduce((t, [x, y]) => t + x * y, 0)
  const slope = (n * sxy - sx * sy) / (n * sxx - sx * sx)
  const trendW = sy / n + slope * (20 - sx / n)
  const mean = complete.reduce((t, x) => t + x.kcal, 0) / complete.length
  const observed = mean - slope * 7700
  if (observed < 0.65 * teeEquation || observed > 1.35 * teeEquation) return { ok: false, reason: 'implausible', observed: round10(observed) }
  const step = Math.max(-200, Math.min(200, 0.5 * (observed - teeNow)))
  return { ok: true, tee: round10(teeNow + step), observed: round10(observed), slopePerWeek: Math.round(slope * 7 * 100) / 100, trendWeight: Math.round(trendW * 10) / 10 }
}

/* ------------------------------ the profile ------------------------------ */

function kg(S, w) { return S.unit === 'lb' ? w * LB : w }

/** The latest weigh-in in kg, or null. */
export function latestWeightKg() {
  const S = need()
  const list = (S.bodyweight || []).filter(b => b?.d && Number(b.w) > 0)
  return list.length ? Math.round(kg(S, Number(list[list.length - 1].w)) * 10) / 10 : null
}

/** The saved answers, or null when the feature has not been set up. */
export function profile() {
  return need().gfNutrition || null
}

/** Saves the answers (weight taken from the latest weigh-in when not given) and returns targets. */
export function saveProfile(p) {
  const S = need()
  const prev = S.gfNutrition || {}
  S.gfNutrition = { ...prev, ...p, enabled: true, updated: Date.now() }
  if (!S.gfNutrition.weight) S.gfNutrition.weight = latestWeightKg()
  return currentTargets()
}

export function disable() {
  const S = need()
  if (S.gfNutrition) S.gfNutrition.enabled = false
  return true
}

/** Today's targets from the saved answers, with the latest weight and any adaptive TEE. */
export function currentTargets() {
  const p = profile()
  if (!p || !p.enabled) return null
  const w = latestWeightKg() || p.weight
  return computeTargets({ ...p, weight: w, teeOverride: p.teeAdapted || null })
}

/**
 * Runs the weekly correction if a week has passed since the last one (call on opening the
 * food screen). Daily logs count as complete when the user said so or logged 3+ entries.
 */
export function weeklyCheck(today = todayISO()) {
  const S = need()
  const p = S.gfNutrition
  if (!p?.enabled) return null
  if (p.lastAdapt && isoDays(p.lastAdapt, today) < 7) return { ok: false, reason: 'notYet' }
  if (!p.started) { p.started = today; return { ok: false, reason: 'started' } }
  if (isoDays(p.started, today) < 14) return { ok: false, reason: 'tooSoon' }
  const base = computeTargets({ ...p, weight: latestWeightKg() || p.weight, teeOverride: null })
  if (!base.tee) return null
  const log = S.gfFoodLog || {}
  const intake = Object.entries(log).map(([iso, entries]) => ({
    iso, kcal: entries.reduce((t, e) => t + (e.per100?.kcal || 0) * (e.grams || 0) / 100, 0),
    complete: (S.gfFoodDone || {})[iso] === true || entries.length >= 3,
  }))
  const weighIns = (S.bodyweight || []).filter(b => b?.d && Number(b.w) > 0).map(b => ({ d: b.d, w: kg(S, Number(b.w)) }))
  const r = adapt({ teeNow: p.teeAdapted || base.tee, teeEquation: base.tee, weighIns, intake, today })
  p.lastAdapt = today
  if (r.ok) p.teeAdapted = r.tee
  return r
}

/** Marks a day's log as complete (or not), for the weekly correction. */
export function setDayComplete(iso, done) {
  const S = need()
  S.gfFoodDone = S.gfFoodDone || {}
  if (done) S.gfFoodDone[iso] = true
  else delete S.gfFoodDone[iso]
  return true
}
