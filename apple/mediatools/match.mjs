// Proposes openGym catalogue ids for source exercises by name (reviewed by hand afterwards).
// node match.mjs wger.json > wger-match.tsv
import { readFileSync } from 'node:fs'
import { EXDB } from '../../frontend/src/lib/exercises-data.js'
import { EXTRAS } from '../core/extras.js'

const CAT = [...EXDB, ...EXTRAS]
const norm = s => (s || '').toLowerCase()
  .replace(/push[\s-]?ups?/g, 'push-up').replace(/pull[\s-]?ups?/g, 'pull-up').replace(/chin[\s-]?ups?/g, 'chin-up')
  .replace(/sit[\s-]?ups?/g, 'sit-up').replace(/press[\s-]?ups?/g, 'push-up').replace(/\bdips\b/g, 'dip')
  .replace(/squats\b/g, 'squat').replace(/lunges\b/g, 'lunge').replace(/crunches\b/g, 'crunch').replace(/raises\b/g, 'raise')
  .replace(/rows\b/g, 'row').replace(/curls\b/g, 'curl').replace(/presses\b/g, 'press').replace(/dumbbells?/g, 'dumbbell')
  .replace(/[()]/g, ' ').replace(/\s+/g, ' ').trim()
const toks = s => new Set(norm(s).split(/[^a-z0-9-]+/).filter(w => w && !['the', 'with', 'on', 'a', 'of', 'and', 'male', 'female', 'v', '2'].includes(w)))
function score(a, b) {
  const A = toks(a), B = toks(b)
  if (!A.size || !B.size) return 0
  let inter = 0
  for (const w of A) if (B.has(w)) inter++
  const j = inter / (A.size + B.size - inter)
  return j + (norm(a) === norm(b) ? 1 : 0)
}
const src = JSON.parse(readFileSync(process.argv[2], 'utf8'))
for (const s of src) {
  const ranked = CAT.map(e => [score(s.name, e.n), e]).sort((x, y) => y[0] - x[0]).slice(0, 3)
  console.log([s.id, s.name, s.equipment?.join('/') || '', ...ranked.map(([sc, e]) => `${e.id}:${e.n}[${e.eq}]=${sc.toFixed(2)}`)].join('\t'))
}
