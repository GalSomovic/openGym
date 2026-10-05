// openGym's catalogue with GymFree's additions appended: extras.js (hand-written) and
// extras-dvids.js (generated from public-domain US military demo videos).
import { EXDB as BASE } from '../../frontend/src/lib/exercises-data.js'
import { EXTRAS } from './extras.js'
import { EXTRAS_DVIDS } from './extras-dvids.js'

export const EXDB = [...BASE, ...EXTRAS, ...EXTRAS_DVIDS]
