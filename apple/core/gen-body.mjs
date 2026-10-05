// The body maps' geometry for the native app: openGym's lib/body-paths.js (outlines converted
// from MuscleMap by Melih Colpan, MIT — see NOTICE.md) written out as plain JSON, which the
// OpenGymCore package bundles and Swift parses once (BodyGeometry.swift). It stays out of
// engine.js: ~90 KB of path strings the engine never reads. Which parts are muscles and what
// they are called comes from the engine (stats.bodyInfo), so this file is geometry only.
import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import paths from '../../frontend/src/lib/body-paths.js'

const here = path.dirname(fileURLToPath(import.meta.url))
const out = path.resolve(here, '../OpenGymCore/Sources/OpenGymCore/Resources/body-paths.json')
writeFileSync(out, JSON.stringify(paths))
