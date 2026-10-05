// Exercises GymFree adds to openGym's catalogue: popular calisthenics movements the catalogue
// lacks. Same shape as frontend/src/lib/exercises-data.js; ids start with `gf-` so they never
// collide. They have GymFree's own animation and no ExerciseDB media.
export const EXTRAS = [
  {
    id: 'gf-squat', n: 'bodyweight squat', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves', 'core'],
    st: [
      'Stand with your feet about shoulder-width apart, toes turned out slightly.',
      'Push your hips back and bend your knees, keeping your chest up and your heels on the floor; reach your arms forward for balance.',
      'Lower until your thighs are at least parallel to the floor, knees tracking over your toes.',
      'Drive through your whole foot to stand back up, squeezing your glutes at the top.',
    ],
  },
  {
    id: 'gf-plank', n: 'plank', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'core',
    sm: ['obliques', 'lower back', 'shoulders', 'glutes'],
    st: [
      'Rest on your forearms with your elbows directly under your shoulders.',
      'Step your feet back so your body forms a straight line from head to heels.',
      'Brace your abs and squeeze your glutes; do not let your hips sag or pike up.',
      'Breathe steadily and hold for the set time.',
    ],
  },
  {
    id: 'gf-bulgarian-split-squat', n: 'bulgarian split squat', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'adductors', 'core'],
    st: [
      'Stand a stride in front of a bench and rest the top of your back foot on it.',
      'Keep your chest up and lower straight down until your front thigh is about parallel to the floor.',
      'Keep your front knee over your foot and most of your weight on the front leg.',
      'Drive through the front heel to stand back up. Finish all reps, then switch legs.',
    ],
  },
  {
    id: 'gf-reverse-lunge', n: 'reverse lunge', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves', 'core'],
    st: [
      'Stand tall with your feet hip-width apart.',
      'Step one foot back and lower until both knees bend to about 90 degrees, the back knee just above the floor.',
      'Keep your torso upright and your front knee over your ankle.',
      'Push through the front heel to bring the back foot forward and stand. Alternate legs.',
    ],
  },
  {
    id: 'gf-wall-sit', n: 'wall sit', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves'],
    st: [
      'Stand with your back against a wall and your feet about two feet in front of you.',
      'Slide down the wall until your thighs are parallel to the floor and your knees are over your ankles.',
      'Keep your back flat against the wall and your weight in your heels.',
      'Hold for the set time, breathing steadily, then slide back up.',
    ],
  },
  {
    id: 'gf-step-up', n: 'step-up', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves'],
    st: [
      'Stand facing a sturdy box or step about knee height.',
      'Place one whole foot on the box and drive through that heel to stand up on it.',
      'Bring the other foot up, standing tall at the top.',
      'Step back down with the trailing leg first, then the lead leg. Repeat, then switch the lead leg.',
    ],
  },
  {
    id: 'gf-dead-hang', n: 'dead hang', bp: 'back', eq: 'body weight', tg: 'forearms', mg: 'lats',
    sm: ['lats', 'shoulders', 'grip muscles'],
    st: [
      'Grip a pull-up bar overhand, hands about shoulder-width apart.',
      'Hang with your arms straight and your feet off the floor.',
      'Keep your shoulders active, not shrugged up to your ears, and your body still.',
      'Hold for the set time, then step down.',
    ],
  },
  {
    id: 'gf-negative-pull-up', n: 'negative pull-up', bp: 'back', eq: 'body weight', tg: 'lats', mg: 'biceps',
    sm: ['biceps', 'upper back', 'forearms'],
    st: [
      'Jump or step up so your chin is above the bar, holding it overhand.',
      'Hold the top for a moment, chest up.',
      'Lower yourself as slowly as you can, taking three to five seconds, until your arms are straight.',
      'Step down, reset and repeat.',
    ],
  },
  {
    id: 'gf-toes-to-bar', n: 'toes to bar', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'hip flexors',
    sm: ['hip flexors', 'lats', 'obliques', 'forearms'],
    st: [
      'Hang from a pull-up bar with straight arms.',
      'Brace your abs and lift your straight legs, pressing the bar down with straight arms.',
      'Bring your toes up to touch the bar between your hands.',
      'Lower your legs under control without swinging.',
    ],
  },
  {
    id: 'gf-jumping-jack', n: 'jumping jack', bp: 'cardio', eq: 'body weight', tg: 'cardiovascular system', mg: 'calves',
    sm: ['calves', 'shoulders', 'hip flexors', 'glutes'],
    st: [
      'Stand tall with your feet together and your arms by your sides.',
      'Jump your feet out wider than your shoulders while swinging your arms out and up overhead.',
      'Jump back to the start, feet together and arms down.',
      'Keep a steady rhythm and land softly on the balls of your feet.',
    ],
  },
  {
    id: 'gf-high-knees', n: 'high knees', bp: 'cardio', eq: 'body weight', tg: 'cardiovascular system', mg: 'hip flexors',
    sm: ['hip flexors', 'quads', 'calves', 'core'],
    st: [
      'Stand tall with your feet hip-width apart.',
      'Run on the spot, driving each knee up to hip height.',
      'Pump your arms in time with your legs and stay on the balls of your feet.',
      'Keep your chest up and your core tight for the set time.',
    ],
  },
  {
    id: 'gf-pike-push-up', n: 'pike push-up', bp: 'shoulders', eq: 'body weight', tg: 'delts', mg: 'triceps',
    sm: ['triceps', 'upper chest', 'traps', 'core'],
    st: [
      'Start in a push-up position, then walk your feet in and lift your hips high so your body forms an upside-down V.',
      'Keep your legs as straight as you can and your head between your arms.',
      'Bend your elbows to lower the top of your head toward the floor, a little ahead of your hands.',
      'Press back up to straight arms. Keep the hips high throughout.',
    ],
  },
  {
    id: 'gf-lying-leg-raise', n: 'lying leg raise', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'hip flexors',
    sm: ['hip flexors', 'lower abs', 'obliques'],
    st: [
      'Lie on your back with your legs straight and your hands by your sides or under your hips.',
      'Press your lower back into the floor and lift your straight legs until they point at the ceiling.',
      'Lower them slowly until they hover just above the floor, without arching your back.',
      'Repeat for the set number of reps.',
    ],
  },
  {
    id: 'gf-hollow-hold', n: 'hollow body hold', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'hip flexors',
    sm: ['hip flexors', 'obliques', 'lower abs'],
    st: [
      'Lie on your back with your arms straight overhead and your legs together.',
      'Press your lower back into the floor and lift your shoulders, arms and legs a few inches off it.',
      'Your body forms a shallow curve like a banana; keep the lower back down the whole time.',
      'Hold for the set time, breathing steadily.',
    ],
  },
  {
    id: 'gf-bird-dog', n: 'bird dog', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'lower back',
    sm: ['lower back', 'glutes', 'shoulders'],
    st: [
      'Kneel on all fours, hands under your shoulders and knees under your hips.',
      'Brace your core and reach one arm forward while extending the opposite leg straight back.',
      'Hold for a moment with your back flat and your hips level.',
      'Return to all fours and switch sides.',
    ],
  },
  {
    id: 'gf-hand-release-push-up', n: 'hand-release push-up', bp: 'chest', eq: 'body weight', tg: 'pectorals', mg: 'triceps',
    sm: ['triceps', 'shoulders', 'upper back', 'core'],
    st: [
      'Start in a high plank, hands under your shoulders and your body in a straight line.',
      'Lower all the way until your chest, hips and thighs touch the floor.',
      'Lift your hands off the floor and reach your arms out to the sides into a T, then bring them back under your shoulders.',
      'Push back up to the plank as one straight line. That is one rep.',
    ],
  },
  {
    id: 'gf-side-plank', n: 'side plank', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'obliques',
    sm: ['obliques', 'glutes', 'shoulders'],
    st: [
      'Lie on your side with your legs straight and stacked, propped on your forearm with the elbow under your shoulder.',
      'Lift your hips so your body forms a straight line from head to feet.',
      'Keep your hips high and your top hand on your hip or reaching up.',
      'Hold for the set time, then switch sides.',
    ],
  },
  {
    id: 'gf-v-up', n: 'v-up', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'hip flexors',
    sm: ['hip flexors', 'lower abs', 'obliques'],
    st: [
      'Lie on your back with your arms straight overhead and your legs straight.',
      'In one movement, lift your legs and upper body and reach your hands toward your toes, balancing on your seat.',
      'Lower back down with control without letting your feet or shoulders rest on the floor.',
      'Repeat for the set number of reps.',
    ],
  },
  {
    id: 'gf-bicycle-crunch', n: 'bicycle crunch', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'obliques',
    sm: ['obliques', 'hip flexors'],
    st: [
      'Lie on your back with your hands lightly behind your head and your shoulders lifted.',
      'Bring one knee toward your chest while extending the other leg low.',
      'Rotate your torso to bring the opposite elbow toward the bent knee.',
      'Switch sides in a smooth pedalling motion.',
    ],
  },
  {
    id: 'gf-superman', n: 'superman', bp: 'back', eq: 'body weight', tg: 'spine', mg: 'lower back',
    sm: ['glutes', 'hamstrings', 'upper back', 'shoulders'],
    st: [
      'Lie face down with your arms straight overhead and your legs straight.',
      'Squeeze your glutes and lift one straight leg and the opposite arm a few inches off the floor.',
      'Hold for a moment, lower with control, then lift the other leg and arm; keep alternating.',
      'Keep your hips on the floor and your neck long. Easier: rest your forehead on your hands and lift one leg at a time. Harder: lift both arms and both legs together.',
    ],
  },
  {
    id: 'gf-sit-to-stand', n: 'sit to stand', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'quads',
    sm: ['glutes', 'core'],
    st: [
      'Sit near the front of a sturdy chair with your feet flat and hip-width apart, arms crossed or reaching forward.',
      'Lean your chest forward and stand up by pushing through your whole feet, without using your hands if you can.',
      'Stand fully tall, then sit back down slowly and with control.',
      'Use your hands on the armrests at first if you need to; aim to need them less over the weeks.',
    ],
  },
  {
    id: 'gf-tandem-stance', n: 'tandem stance', bp: 'lower legs', eq: 'body weight', tg: 'calves', mg: 'balance',
    sm: ['ankles', 'core'],
    st: [
      'Stand next to a counter or wall you can touch for support.',
      'Place one foot directly in front of the other, heel touching toes, as if on a tightrope.',
      'Hold steady for the set time, looking ahead, touching the support only if you need to.',
      'Switch which foot is in front and repeat.',
    ],
  },
  {
    id: 'gf-single-leg-stance', n: 'single-leg stance', bp: 'lower legs', eq: 'body weight', tg: 'calves', mg: 'balance',
    sm: ['glutes', 'ankles', 'core'],
    st: [
      'Stand next to a counter or wall you can touch for support.',
      'Shift your weight onto one foot and lift the other a little off the floor.',
      'Hold steady for the set time; use a fingertip on the support if you wobble.',
      'Switch legs. Harder: let go of the support, or turn your head slowly side to side.',
    ],
  },
  {
    id: 'gf-heel-to-toe-walk', n: 'heel-to-toe walk', bp: 'lower legs', eq: 'body weight', tg: 'calves', mg: 'balance',
    sm: ['ankles', 'core'],
    st: [
      'Stand at one end of a hallway or next to a counter, so you can reach a support.',
      'Walk forward placing the heel of each foot directly in front of the toes of the other.',
      'Look ahead rather than at your feet, and keep a steady, slow pace.',
      'Walk 10 to 20 steps, turn carefully and walk back.',
    ],
  },
  // Outdoor cardio that GPS tracking logs (activity.js); also usable as plain cardio entries.
  {
    id: 'gf-walk', n: 'walking', bp: 'cardio', eq: 'body weight', tg: 'cardiovascular system', mg: 'calves',
    sm: ['quads', 'hamstrings', 'glutes', 'calves'],
    st: [
      'Walk tall with your head up, shoulders relaxed and your arms swinging naturally.',
      'Land on your heel and roll through to push off from your toes.',
      'For a brisk walk, pick a pace where you can talk but not sing.',
    ],
  },
  {
    id: 'gf-cycling', n: 'cycling', bp: 'cardio', eq: 'bicycle', tg: 'cardiovascular system', mg: 'quads',
    sm: ['quads', 'glutes', 'hamstrings', 'calves'],
    st: [
      'Set the saddle so your knee is only slightly bent at the bottom of each pedal stroke.',
      'Keep a light grip on the bars, your elbows soft and your back long.',
      'Pedal in smooth circles and shift gears to keep a steady cadence on hills.',
      'Wear a helmet and follow the rules of the road.',
    ],
  },
]
