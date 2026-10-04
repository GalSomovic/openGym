// openGym's catalogue with GymFree's additions appended (see extras.js).
import { EXDB as BASE } from '../../frontend/src/lib/exercises-data.js'
import { EXTRAS } from './extras.js'

export const EXDB = [...BASE, ...EXTRAS]
