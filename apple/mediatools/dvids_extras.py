"""
New GymFree exercises that exist only as DVIDS demos (US Marine Corps TECOM library, AFN Sasebo
"Fitness Workout" series). Each entry: catalogue fields in openGym's shape, and the demo titles.

    python3 dvids_extras.py      writes apple/core/extras-dvids.js

Steps come from the video's own description (public domain) when it has Preparation/Execution
text, rewritten to "you"; otherwise they are written here. Equipment uses openGym's values where
one fits; "sandbag" and "suspension trainer" are new, and recovery tools count as "roller".
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))

# id suffix, name, body part, equipment, target, main muscle, other muscles, steps (None: from the
# description), TECOM titles, Sasebo titles
E = []


def ex(slug, n, bp, eq, tg, mg, sm, st=None, tecom=(), sasebo=()):
    E.append(dict(id="gf-" + slug, n=n, bp=bp, eq=eq, tg=tg, mg=mg, sm=list(sm), st=st,
                  tecom=list(tecom), sasebo=list(sasebo)))


BW, BAND, DB, KB, BB, MB, SB, TRX, ROLL, ROPE = ("body weight", "band", "dumbbell", "kettlebell", "barbell",
                                               "medicine ball", "sandbag", "suspension trainer", "roller", "rope")

# ---------------------------------------------------------------- mobility, stretches
ex("half-kneeling-wall-rotation", "half-kneeling wall rotation", "back", BW, "upper back", "thoracic spine", ["obliques", "chest"], [
    "Kneel on one knee with your side to a wall and your arms straight out in front of you at shoulder height.",
    "Keep your hips square and open the top arm across your body toward the wall behind you, following your hand with your eyes.",
    "Rotate through the upper back only; keep your lower back and hips still.",
    "Return with control and repeat, then switch sides."], tecom=["1/2 Kneeling Wall Rotation Stretch"])
ex("knee-to-wall-ankle-mobilization", "3-way knee to wall", "lower legs", BW, "calves", "ankles", ["soleus"], [
    "Stand in a short split stance facing a wall, front toes a few inches from it.",
    "Keeping the front heel down, drive the front knee forward to touch the wall straight over the toes.",
    "Repeat toward the outside of the foot and then toward the inside.",
    "Move the foot back as your ankle loosens; switch legs."], tecom=["3 Way Knee to Wall"])
ex("90-90-active-hamstring", "90/90 active hamstring stretch", "upper legs", BW, "hamstrings", "hamstrings", ["calves"],
   tecom=["90/90 Active Hamstring"])
ex("arm-circles", "arm circles", "shoulders", BW, "delts", "shoulders", ["upper back"], tecom=["Arm Circles"])
ex("cat-camel", "cat camel", "back", BW, "spine", "lower back", ["upper back", "abs"], [
    "Start on all fours, hands under your shoulders and knees under your hips.",
    "Round your back up toward the ceiling, tucking your chin and pelvis.",
    "Then let your belly drop and lift your chest and tailbone, arching the back.",
    "Move slowly between the two positions with your breath."], tecom=["Cat Camel"])
ex("childs-pose", "child's pose", "back", BW, "lats", "lower back", ["shoulders", "hips"], [
    "Kneel with your big toes together and your knees apart.",
    "Sit your hips back toward your heels and walk your hands forward until your chest drops toward the floor.",
    "Rest your forehead down and reach long through your arms.",
    "Breathe slowly and hold."], tecom=["Child Pose"], sasebo=["Childs Pose Stretch"])
ex("90-90-hip-switch", "90/90 hip switch", "upper legs", BW, "glutes", "hips", ["adductors", "abductors"], [
    "Sit tall with your knees bent and your feet wider than your hips, hands behind you if needed.",
    "Drop both knees to one side so the front leg and back leg each make a 90-degree angle.",
    "Lift the knees and rotate them to the other side.",
    "Keep your chest up and move smoothly side to side."], tecom=["Combination Hip Stretch"])
ex("couch-stretch", "couch stretch", "upper legs", BW, "quads", "hip flexors", ["quads"], [
    "Kneel facing away from a wall, bench or couch and place one shin up against it, knee on a pad.",
    "Step the other foot forward into a lunge.",
    "Squeeze the glute of the back leg and lift your chest tall until you feel a stretch in the front of the hip and thigh.",
    "Hold, then switch legs."], tecom=["Couch Stretch"])
ex("cross-body-shoulder-stretch", "cross-body shoulder stretch", "shoulders", BW, "delts", "rear shoulder", ["upper back"], [
    "Bring one arm straight across your chest.",
    "Hold it above the elbow with the other hand and pull it gently toward you.",
    "Keep the shoulder down, away from your ear.",
    "Hold, then switch arms."], tecom=["Cross Body Stretch"])
ex("figure-4-stretch", "figure 4 stretch", "upper legs", BW, "glutes", "glutes", ["hips", "piriformis"], [
    "Lie on your back with your knees bent.",
    "Cross one ankle over the opposite knee.",
    "Reach through and hold behind the lower thigh, then draw it toward your chest until you feel a stretch in the hip.",
    "Hold, then switch sides."], tecom=["Figure 4 Stretch"], sasebo=["Figure 4 Stretch"])
ex("half-kneeling-ankle-mobilization", "half-kneeling ankle mobilization", "lower legs", BW, "calves", "ankles", ["soleus"],
   tecom=["Forward Lunge for Ankle", "Forward Lunge For Ankle"])
ex("half-kneeling-hip-flexor-rotation", "half-kneeling hip flexor stretch with rotation", "upper legs", BW, "quads", "hip flexors",
   ["obliques"], tecom=["Half Kneeling with Rotation"])
ex("seated-hip-cross-stretch", "seated hip cross stretch", "upper legs", BW, "glutes", "hips", ["lower back"], [
    "Sit with both legs straight.",
    "Cross one foot over the other knee and plant it on the floor.",
    "Hug the bent knee toward your chest and sit tall, turning your chest toward the bent knee.",
    "Hold, then switch sides."], tecom=["Lateral Hip Stretch"])
ex("supine-knee-crossover", "supine knee crossover", "back", BW, "spine", "lower back", ["glutes", "obliques"], [
    "Lie on your back with your arms out to the sides.",
    "Bend one knee and let it fall across your body toward the floor.",
    "Keep both shoulders down and turn your head away from the knee.",
    "Hold, return and switch sides."], tecom=["Knee Cross Over", "Supine Knee Over"], sasebo=["Supine Twist Stretch"])
ex("seated-hip-internal-rotation", "seated hip internal rotation", "upper legs", BW, "glutes", "hips", ["adductors"], [
    "Sit leaning back on your hands with your knees bent and your feet wider than your hips.",
    "Let one knee drop in toward the floor, rotating that hip inward.",
    "Bring it back up and repeat with the other knee.",
    "Keep your feet in place and move slowly."], tecom=["Leaning Back With Hip Internal Rotation"])
ex("passive-strap-hamstring-stretch", "lying hamstring stretch with strap", "upper legs", BW, "hamstrings", "hamstrings", ["calves"], [
    "Lie on your back and loop a strap or towel around one foot.",
    "Straighten that leg up toward the ceiling, keeping the other leg flat.",
    "Use the strap to draw the leg gently toward you until you feel a stretch behind the thigh.",
    "Hold, then switch legs."], tecom=["Passive Strap Stretch"], sasebo=["Hamstring Stretch with Towel"])
ex("seated-tibialis-stretch", "seated tibialis stretch", "lower legs", BW, "calves", "shins", ["ankles"], [
    "Sit with one leg straight and cross the other ankle over that knee.",
    "Hold the top of the crossed foot and pull the toes down and in.",
    "Feel the stretch along the front of the shin.",
    "Hold, then switch sides."], tecom=["Passive Tibialis Stretch"])
ex("kneeling-wrist-stretch", "kneeling wrist stretch", "lower arms", BW, "forearms", "wrist flexors", ["wrist extensors"], [
    "Kneel on all fours and turn your hands so your fingers point back toward your knees.",
    "Keeping your palms flat, gently sit your hips back until you feel a stretch in the forearms.",
    "Rock forward and back slowly, then try with the backs of the hands down.",
    "Stay pain free."], tecom=["Passive Wrist Stretch"])
ex("half-kneeling-hip-flexor-stretch", "half-kneeling hip flexor stretch", "upper legs", BW, "quads", "hip flexors", ["quads", "abs"], [
    "Kneel on one knee holding a broomstick or PVC pipe upright beside you for balance.",
    "Tuck your pelvis under and squeeze the glute of the kneeling leg.",
    "Shift your hips forward until you feel a stretch in the front of the hip; reach the same-side arm overhead to deepen it.",
    "Hold, then switch sides."], tecom=["PVC Half Kneeling Hip Flexor"])
ex("dowel-hip-hinge", "dowel hip hinge", "upper legs", BW, "hamstrings", "hamstrings", ["glutes", "lower back"], [
    "Stand holding a broomstick or PVC pipe in front of your thighs with an overhand grip.",
    "Soften your knees and push your hips back, sliding the stick down your thighs with a flat back.",
    "Go until you feel a stretch in your hamstrings, then drive the hips forward to stand.",
    "Keep your back flat throughout."], tecom=["PVC RDL Stretch"])
ex("standing-quad-stretch", "standing quad stretch", "upper legs", BW, "quads", "quads", ["hip flexors"], [
    "Stand tall and bend one knee, bringing your heel toward your glutes.",
    "Hold the ankle with the same-side hand.",
    "Keep your knees together and push the hip slightly forward until you feel a stretch in the front of the thigh.",
    "Hold, then switch legs."], tecom=["Quad Stretch"])
ex("side-sitting-forward-lean", "side-sitting forward lean", "upper legs", BW, "glutes", "hips", ["lower back"], [
    "Sit with one leg bent in front of you and the other bent behind, both at about 90 degrees.",
    "Sit tall over the front shin.",
    "Hinge forward over the front leg with a long back until you feel a stretch in the hip.",
    "Hold, then switch sides."], tecom=["Side Sitting and Lean Forward Stretch", "Side Sitting Forward Lean"])
ex("slant-board-calf-stretch", "slant board calf stretch", "lower legs", BW, "calves", "calves", ["soleus"], [
    "Stand on a slant board or a step with your heels lower than your toes.",
    "Keep your legs straight and your body tall.",
    "Lean your hips forward slightly until you feel a stretch in the calves.",
    "Hold, then bend the knees a little to stretch lower in the calf."], tecom=["Slant Board Stretch"])
ex("star-stretch", "star stretch", "waist", BW, "abs", "obliques", ["lats", "hips"], [
    "Stand with your feet wide and your arms out to the sides.",
    "Reach one hand down toward the opposite foot while the other arm reaches up.",
    "Return to the star position and repeat to the other side.",
    "Keep your legs straight but not locked."], tecom=["Star Stretch"])
ex("overhead-strap-triceps-stretch", "overhead triceps stretch with strap", "upper arms", BW, "triceps", "triceps", ["lats", "shoulders"], [
    "Hold a strap or towel in one hand and drop it behind your head, elbow pointing up.",
    "Reach the other hand behind your back and grab the strap.",
    "Gently pull down with the lower hand to stretch the top arm.",
    "Hold, then switch sides."], tecom=["Strap Stretch"])
ex("sumo-squat-stretch", "sumo squat stretch", "upper legs", BW, "adductors", "groin", ["hips", "ankles"], [
    "Stand with your feet wider than your shoulders and toes turned out.",
    "Sink into a deep squat with your chest up.",
    "Press your elbows against the inside of your knees to push them out.",
    "Hold, breathing slowly."], tecom=["Sumo Stretch"])
ex("supine-knee-to-chest", "supine knee to chest stretch", "upper legs", BW, "glutes", "glutes", ["lower back"], [
    "Lie on your back with both legs straight.",
    "Pull one knee to your chest with both hands.",
    "Keep the other leg flat on the floor.",
    "Hold, then switch legs."], tecom=["Supine Knee to Chest Stretch"])
ex("supine-leg-over", "supine leg over", "back", BW, "spine", "lower back", ["glutes", "hamstrings"], tecom=["Supine Leg Overs", "Supine Leg Over"])
ex("supine-straight-leg-raise", "supine straight leg raise", "upper legs", BW, "hamstrings", "hamstrings", ["hip flexors"],
   tecom=["Supine Straight Leg Raise"])
ex("t-spine-heel-sit-reach", "t-spine heel sit with reach", "back", BW, "upper back", "thoracic spine", ["lats"], [
    "Kneel and sit your hips back onto your heels, then place one hand on the floor in front of you.",
    "Put the other hand behind your head.",
    "Rotate that elbow up toward the ceiling, following it with your eyes, then bring it down toward the floor arm.",
    "Repeat, then switch sides."], tecom=["T-Spine Heel Sit With Reach"])
ex("t-spine-rib-grab", "t-spine rib grab", "back", BW, "upper back", "thoracic spine", ["obliques"], [
    "Lie on your side with your knees bent up to hip height and your arms straight in front of you.",
    "Hold your top hand on your lower ribs.",
    "Rotate your top shoulder back toward the floor behind you, keeping the knees together.",
    "Return and repeat, then switch sides."], tecom=["T-Spine Rib Grab"])
ex("trunk-circles", "trunk circles", "waist", BW, "abs", "core", ["lower back", "obliques"], tecom=["Trunk Circles"])
ex("trunk-flexion-extension", "trunk flexion and extension", "back", BW, "spine", "lower back", ["abs"], tecom=["Trunk Flexion and Extension"])
ex("trunk-twists", "trunk twists", "waist", BW, "abs", "obliques", ["lower back"], tecom=["Trunk Twists"])
ex("archer-stretch", "archer shoulder stretch", "shoulders", BW, "delts", "shoulders", ["chest", "triceps"], [
    "Hold a band or towel overhead with your hands wide.",
    "Pull one hand down beside your ear like drawing a bow, keeping the other arm straight up.",
    "Return overhead and repeat to the other side.",
    "Keep your ribs down and your chest tall."], sasebo=["Archer Stretch"])
ex("downward-dog", "downward dog", "upper legs", BW, "hamstrings", "hamstrings", ["calves", "shoulders"], [
    "Start on all fours, then tuck your toes and lift your hips up and back.",
    "Straighten your arms and legs as much as you can, making an upside-down V.",
    "Press your heels toward the floor and your chest toward your thighs.",
    "Hold, breathing slowly."], sasebo=["Downward Facing Dog Stretch"])
ex("dragon-stretch", "dragon stretch", "upper legs", BW, "quads", "hip flexors", ["glutes", "adductors"], [
    "From a low lunge, place both hands inside your front foot.",
    "Lower the back knee to the floor and let your hips sink forward and down.",
    "Keep the front knee over the ankle.",
    "Hold, then switch sides."], sasebo=["Dragon Stretch"])
ex("frog-stretch", "frog stretch", "upper legs", BW, "adductors", "groin", ["hips"], [
    "Start on all fours, then slide your knees out wide with your ankles in line with your knees.",
    "Lower onto your forearms.",
    "Gently rock your hips back until you feel a stretch in the inner thighs.",
    "Hold, breathing slowly."], sasebo=["Frog Stretch"])
ex("lizard-stretch", "lizard stretch", "upper legs", BW, "quads", "hip flexors", ["adductors", "glutes"], [
    "From a push-up position, step one foot up outside the same-side hand.",
    "Lower the back knee if you need to.",
    "Sink your hips down and forward; lower onto your forearms to go deeper.",
    "Hold, then switch sides."], sasebo=["Lizard Stretch"])
ex("seated-side-reach-stretch", "seated side reach stretch", "waist", BW, "abs", "obliques", ["lats", "hamstrings"], [
    "Sit with one leg straight out to the side and the other foot tucked against the inner thigh.",
    "Reach the opposite arm up and over toward the straight leg.",
    "Keep your chest open toward the front.",
    "Hold, then switch sides."], sasebo=["QLT Stretch"])
ex("seal-stretch", "seal stretch", "waist", BW, "abs", "abs", ["hip flexors", "lower back"], [
    "Lie face down with your hands under your shoulders.",
    "Press up through straight arms, lifting your chest while your hips stay on the floor.",
    "Keep your shoulders down and look forward.",
    "Hold, then lower with control."], sasebo=["Seal Pose Stretch"])
ex("seated-hamstring-stretch", "seated hamstring stretch", "upper legs", BW, "hamstrings", "hamstrings", ["lower back", "calves"], [
    "Sit with your legs straight in front of you.",
    "Sit tall, then hinge forward from your hips, reaching for your feet.",
    "Keep your back long rather than rounding.",
    "Hold, breathing slowly."], sasebo=["Seated Hamstring Stretch"])
ex("seated-straddle-stretch", "seated straddle stretch", "upper legs", BW, "adductors", "groin", ["hamstrings"], [
    "Sit with your legs straight and as wide as is comfortable.",
    "Sit tall, then walk your hands forward between your legs.",
    "Keep your knees and toes pointing up.",
    "Hold, breathing slowly."], sasebo=["Seated Straddle Stretch"])
ex("thread-the-needle", "thread the needle", "back", BW, "upper back", "thoracic spine", ["shoulders"], [
    "Start on all fours.",
    "Slide one arm under your body along the floor, palm up, lowering that shoulder and the side of your head to the floor.",
    "Hold, then reach the arm up toward the ceiling.",
    "Repeat, then switch sides."], sasebo=["Thread the Needle Stretch"])
ex("prone-twisted-cross", "prone twisted cross", "back", BW, "spine", "lower back", ["hip flexors", "chest"], [
    "Lie face down with your arms out to the sides.",
    "Bend one knee and reach that foot across your body toward the opposite hand.",
    "Let the hip roll open while the shoulders stay as flat as possible.",
    "Return and switch sides."], sasebo=["Twisted Cross"])

ex("long-arm-chest-stretch", "long-arm chest stretch", "chest", BW, "pectorals", "chest", ["biceps", "shoulders"], [
    "Stand beside a post or door frame and place your hand on it at shoulder height behind you, arm straight.",
    "Step forward with the near foot.",
    "Slowly turn your chest away from the arm until you feel a stretch across the chest and front of the arm.",
    "Hold, then switch sides."], tecom=["Long Arm Pull and Rotate"])

# ---------------------------------------------------------------- dynamic warm-up
ex("4-way-bear-crawl", "4-way bear crawl", "cardio", BW, "cardiovascular system", "core", ["shoulders", "quads"], [
    "Get on hands and feet with your knees bent and hovering just off the floor.",
    "Crawl forward a few steps, moving the opposite hand and foot together.",
    "Then crawl sideways, backward and to the other side.",
    "Keep your back flat and your knees low."], tecom=["4 Way Bear Crawl"])
ex("butt-kicks", "butt kicks", "cardio", BW, "cardiovascular system", "hamstrings", ["quads", "calves"], tecom=["Butt-Kickers"])
ex("carioca", "carioca", "cardio", BW, "cardiovascular system", "hips", ["adductors", "abductors"], tecom=["Carioca"])
ex("carioca-knee-drive", "carioca with knee drive", "cardio", BW, "cardiovascular system", "hips", ["hip flexors", "obliques"],
   tecom=["Carioca w/Knee Drive"])
ex("crab-walk", "crab walk", "upper arms", BW, "triceps", "triceps", ["glutes", "shoulders", "core"], tecom=["Crab Walk"])
ex("crossover-lunge", "crossover lunge", "upper legs", BW, "glutes", "glutes", ["quads", "adductors"], tecom=["Cross-over Lunge"])
ex("crossover-walk", "crossover walk", "upper legs", BW, "abductors", "hips", ["glutes"], tecom=["Crossover Walk"])
ex("diagonal-lunge", "diagonal lunge", "upper legs", BW, "quads", "quads", ["glutes", "adductors"], tecom=["Diagonal Lunge"])
ex("fire-hydrants", "fire hydrant", "upper legs", BW, "abductors", "glutes", ["hips", "core"], [
    "Start on all fours, hands under your shoulders and knees under your hips.",
    "Keeping the knee bent, lift one leg out to the side until the thigh is about level with your hip.",
    "Hold briefly without tipping your hips, then lower with control.",
    "Finish the set, then switch sides."], tecom=["Fire Hydrants"], sasebo=["Fire Hydrants"])
ex("frankenstein-walk", "frankenstein walk", "upper legs", BW, "hamstrings", "hamstrings", ["hip flexors"], tecom=["Frankenstein"])
ex("lateral-leg-swing", "lateral leg swing", "upper legs", BW, "adductors", "hips", ["abductors"], tecom=["Frontal Leg Swing"])
ex("front-leg-swing", "front-to-back leg swing", "upper legs", BW, "hamstrings", "hips", ["hip flexors", "glutes"], tecom=["Sagittal Leg Swing"])
ex("groiners", "groiner", "upper legs", BW, "adductors", "hips", ["hip flexors", "shoulders"], tecom=["Groiners"])
ex("heel-toe-raises", "heel and toe raises", "lower legs", BW, "calves", "calves", ["shins"], tecom=["Heel/Toe Raises"])
ex("highland-flings", "highland flings", "upper legs", BW, "glutes", "hips", ["hamstrings"], tecom=["Highland Flings"])
ex("lateral-lunge", "lateral lunge", "upper legs", BW, "adductors", "quads", ["glutes", "adductors"], [
    "Stand with your feet together and your hands at your chest.",
    "Take a big step out to the side, sitting your hips back over the stepping leg while the other leg stays straight.",
    "Keep your chest up and both feet pointing forward.",
    "Push off to return and repeat to the other side."], tecom=["Lateral Lunge"])
ex("lateral-shuffle", "lateral shuffle", "cardio", BW, "cardiovascular system", "hips", ["quads", "calves"], tecom=["Lateral Shuffle"])
ex("standing-side-bend", "standing side bend", "waist", BW, "abs", "obliques", ["lats"], tecom=["Lateral Side Bends"])
ex("lateral-squat-wave", "lateral squat wave", "upper legs", BW, "quads", "quads", ["glutes", "adductors"], tecom=["Lateral Squat Wave"])
ex("lateral-step-squat", "lateral step squat", "upper legs", BW, "quads", "quads", ["glutes", "abductors"], tecom=["Lateral Step Squat"])
ex("long-strider", "long strider", "upper legs", BW, "hamstrings", "hip flexors", ["hamstrings", "glutes"], tecom=["Long Strider"])
ex("lunge-power-skip", "lunge with power skip", "upper legs", BW, "quads", "quads", ["glutes", "calves"], tecom=["Lunge w/Power Skip"])
ex("plank-leg-extension", "plank leg extension", "waist", BW, "abs", "core", ["glutes", "shoulders"], tecom=["Plank Leg Extension"])
ex("plank-hand-raise", "plank with arm lift", "waist", BW, "abs", "core", ["shoulders", "glutes"], [
    "Start in a high plank with your hands under your shoulders and your feet a little apart.",
    "Brace your core and lift one arm straight out in front of you.",
    "Keep your hips level and still, then place the hand down.",
    "Alternate arms."], tecom=["Plank with Hand Raise"], sasebo=["Pillar Bridge with Arm Lift"])
ex("prone-leg-over", "prone leg over", "upper legs", BW, "glutes", "hip flexors", ["lower back", "glutes"], [
    "Lie face down with your arms out to the sides.",
    "Lift one leg and swing it across your body toward the opposite hand, letting the hip rotate.",
    "Return and repeat with the other leg.",
    "Keep your chest as low as you can."], tecom=["Prone Leg Overs"])
ex("scorpion", "scorpion", "upper legs", BW, "glutes", "hip flexors", ["glutes", "lower back"], tecom=["Scorpions", "Scorpion"])
ex("side-slide-arm-swing", "side slide with arm swing", "cardio", BW, "cardiovascular system", "hips", ["shoulders"], tecom=["Side Slide w/Arm Swing"])
ex("single-leg-balance-reach", "single-leg balance reach", "upper legs", BW, "glutes", "glutes", ["hamstrings", "ankles"], tecom=["Single Leg Balance"])
ex("spiderman-crawl", "spiderman crawl", "waist", BW, "abs", "core", ["hips", "shoulders"], tecom=["Spiderman"])
ex("split-jack", "forward split jack", "cardio", BW, "cardiovascular system", "quads", ["calves", "shoulders"], tecom=["Split Jack Forward"])
ex("split-squat-drops", "split squat drops", "upper legs", BW, "quads", "quads", ["glutes"], tecom=["Split Squat Drops"])
ex("squat-to-stand", "squat to stand", "upper legs", BW, "hamstrings", "hips", ["hamstrings", "adductors"], tecom=["Squat to Stand"])
ex("walking-knee-hug", "walking knee hug", "upper legs", BW, "glutes", "glutes", ["hip flexors"], tecom=["Walking Knee Hug"])
ex("walking-leg-cradle", "walking leg cradle", "upper legs", BW, "glutes", "hips", ["glutes"], tecom=["Walking Leg Cradle"])
ex("walking-lunge-elbow-to-instep", "walking lunge with elbow to instep", "upper legs", BW, "quads", "hip flexors", ["groin", "hamstrings"],
   tecom=["Walking Lunge Elbow to Instep"])
ex("walking-lunge-side-reach", "walking lunge with side reach", "upper legs", BW, "quads", "quads", ["obliques", "lats"],
   tecom=["Walking Lunge with Side Reach"])
ex("walking-quad-stretch", "walking quad stretch", "upper legs", BW, "quads", "quads", ["hip flexors"], tecom=["Walking Quad Stretch"])
ex("chair-pistol-squat", "box pistol squat", "upper legs", BW, "quads", "quads", ["glutes", "core"], [
    "Stand in front of a box or chair on one leg, the other leg held straight out in front.",
    "Sit back and down slowly on the standing leg until you touch the seat.",
    "Drive through the whole foot to stand back up without using the other leg.",
    "Finish the set, then switch legs."], sasebo=["Chair Pistol Squat"])
ex("side-plank-hip-dip", "dynamic side plank", "waist", BW, "abs", "obliques", ["shoulders", "glutes"], [
    "Lie on your side propped on your forearm, elbow under your shoulder and feet stacked.",
    "Lift your hips into a straight line from head to feet.",
    "Lower the hips to just above the floor and lift them again.",
    "Finish the set, then switch sides."], sasebo=["Dynamic Pillar Bridge"])
ex("shoot-through", "shoot-through", "upper arms", BW, "triceps", "triceps", ["chest", "shoulders", "core"], [
    "Set two sturdy chairs side by side and support yourself on them with straight arms, feet on the floor in front.",
    "Lower your body between the chairs, then push back up.",
    "From the top, swing your legs back under you into a push-up shape and back through again.",
    "Move with control and keep your shoulders away from your ears."], sasebo=["Shoot Throughs"])

# ---------------------------------------------------------------- power, jumps
ex("box-depth-jump", "depth jump", "upper legs", BW, "quads", "quads", ["glutes", "calves"], tecom=["Box Depth Jump"])
ex("box-jump", "box jump", "upper legs", BW, "quads", "quads", ["glutes", "hamstrings", "calves"], tecom=["Box Jump"])
ex("single-leg-box-tuck-jump", "single-leg box tuck jump", "upper legs", BW, "quads", "quads", ["glutes", "calves"], tecom=["Box Tuck Jump Single Leg"])
ex("lateral-box-jump", "lateral box jump", "upper legs", BW, "quads", "quads", ["glutes", "calves", "abductors"], [
    "Stand beside a low box with your feet hip-width apart.",
    "Dip into a quarter squat and jump sideways onto the box, landing softly with both feet.",
    "Step or jump back down and repeat.",
    "Land with bent knees and switch sides each set."], tecom=["Lateral Box Jump"])
ex("lateral-squat-jump", "lateral squat jump", "upper legs", BW, "quads", "quads", ["glutes", "abductors"], tecom=["Lateral Squat Jump"])
ex("pike-jump", "pike jump", "upper legs", BW, "quads", "hip flexors", ["quads", "abs", "calves"], [
    "Stand with your feet together and your arms by your sides.",
    "Jump straight up and lift your straight legs in front of you, reaching your hands toward your toes.",
    "Return your legs under you and land softly.",
    "Reset and repeat."], tecom=["Pike Jump"])
ex("split-squat-jump-combo", "split squat jump combo", "upper legs", BW, "quads", "quads", ["glutes", "calves"], tecom=["Split Squat Jump Combo"])
ex("triple-extension-jump", "triple extension jump", "upper legs", BW, "glutes", "glutes", ["quads", "calves"], tecom=["Triple Extension"])
ex("traveling-push-up", "traveling push-up", "chest", BW, "pectorals", "chest", ["triceps", "shoulders", "core"], [
    "Start in a push-up position.",
    "Do a push-up, then walk your hands and feet a step to one side.",
    "Do another push-up and keep travelling.",
    "Keep your body straight while you move."], tecom=["Traveling Push Up"])
ex("depth-push-up", "depth push-up", "chest", BW, "pectorals", "chest", ["triceps", "shoulders"], [
    "Set two low blocks or plates shoulder-width apart and start in a push-up with your hands on them.",
    "Lower your chest between the blocks below hand level.",
    "Push up hard, hop your hands to the floor and back onto the blocks.",
    "Keep your body straight and land with soft elbows."], tecom=["Depth Pushup"])
ex("clap-to-chest-push-up", "clap-to-chest push-up", "chest", BW, "pectorals", "chest", ["triceps", "shoulders"], [
    "Start in a push-up position.",
    "Lower and push up explosively so your hands leave the floor.",
    "Clap your hands to your chest and get them back down before you land.",
    "Land with soft elbows and go straight into the next rep."], tecom=["Clap to Chest Pushups"])
ex("single-arm-plyo-push-up", "single-arm plyo push-up", "chest", BW, "pectorals", "chest", ["triceps", "shoulders", "core"], [
    "Start in a push-up with one hand on a medicine ball and the other on the floor.",
    "Lower, then push up explosively and pass over the ball so the other hand lands on it.",
    "Lower again on the new side.",
    "Keep your hips square and move quickly side to side."], tecom=["Single Arm Plyo Pushups"])

# ---------------------------------------------------------------- bands
ex("band-bent-over-row", "band bent-over row", "back", BAND, "upper back", "lats", ["biceps", "rear shoulders"], [
    "Stand on the middle of a band with your feet hip-width apart, holding an end in each hand.",
    "Hinge forward with a flat back and let your arms hang.",
    "Row your elbows back to your sides, squeezing your shoulder blades.",
    "Lower with control."], tecom=["Band Bent Over Rows"])
ex("band-bent-over-lateral-raise", "band bent-over lateral raise", "shoulders", BAND, "delts", "rear shoulders", ["upper back"], [
    "Stand on the middle of a band, holding an end in each hand, and hinge forward with a flat back.",
    "With a slight bend in the elbows, raise your arms out to the sides until they are level with your back.",
    "Squeeze your shoulder blades together, then lower slowly.",
    "Keep your neck long and avoid swinging."], tecom=["Band Bent Over Lateral Raises"])
ex("band-deadlift", "band deadlift", "upper legs", BAND, "glutes", "glutes", ["hamstrings", "lower back"], tecom=["Band Deadlift"])
ex("band-good-morning", "band good morning", "upper legs", BAND, "hamstrings", "hamstrings", ["glutes", "lower back"],
   tecom=["Band Goodmorning", "Band Good Morning"])
ex("band-lat-pulldown", "band lat pulldown", "back", BAND, "lats", "lats", ["biceps", "upper back"], [
    "Anchor a band high and kneel facing it, holding the band with straight arms overhead.",
    "Pull your elbows down to your sides, squeezing your lats and shoulder blades.",
    "Keep your chest up and your torso still.",
    "Return with control."], tecom=["Band Lat Pulldown"])
ex("band-overhead-squat", "band overhead squat", "upper legs", BAND, "quads", "quads", ["glutes", "shoulders", "core"],
   tecom=["Band Overhead Squat"], sasebo=["Banded Overhead Squat"])
ex("band-lateral-raise", "band lateral raise", "shoulders", BAND, "delts", "shoulders", ["traps"], [
    "Stand on the middle of a band, holding an end in each hand at your sides.",
    "With a slight bend in the elbows, raise your arms out to the sides to shoulder height.",
    "Pause, then lower slowly.",
    "Keep your shoulders down and avoid swinging."], tecom=["Band Side Lateral Raise"], sasebo=["Banded Lateral Raise"])
ex("band-standing-chest-press", "band standing chest press", "chest", BAND, "pectorals", "chest", ["triceps", "shoulders"], [
    "Anchor a band behind you at chest height and stand facing away in a split stance, hands at your chest.",
    "Press both hands straight forward until your arms are extended.",
    "Return slowly until your hands are back at your chest.",
    "Keep your core tight and do not lean forward."], tecom=["Band Standing Chest Press"], sasebo=["Banded Bench Press"])
ex("band-biceps-curl", "band biceps curl", "upper arms", BAND, "biceps", "biceps", ["forearms"], [
    "Stand on the middle of a band, holding an end in each hand with palms forward.",
    "Keep your elbows at your sides and curl your hands toward your shoulders.",
    "Squeeze at the top, then lower slowly.",
    "Do not swing your body."], tecom=["Band Standing Curl"])
ex("band-standing-twist", "band standing twist", "waist", BAND, "abs", "obliques", ["core"], [
    "Anchor a band at chest height and stand side-on to it, holding it with both hands at your chest.",
    "Press your arms out straight and rotate your torso away from the anchor.",
    "Return slowly with control.",
    "Finish the set, then face the other way."], tecom=["Band Standing Twist"], sasebo=["Banded Twists for Abdomen"])
ex("band-triceps-kickback", "band triceps kickback", "upper arms", BAND, "triceps", "triceps", [], [
    "Stand on a band and hinge forward with a flat back, elbows bent and pinned at your sides.",
    "Straighten your arms back behind you.",
    "Squeeze the triceps, then return slowly.",
    "Keep the upper arms still."], tecom=["Band Tricep Kickback"])
ex("band-triceps-pushdown", "band triceps pushdown", "upper arms", BAND, "triceps", "triceps", [], [
    "Anchor a band high and hold it with both hands, elbows at your sides and bent.",
    "Push your hands down until your arms are straight.",
    "Squeeze, then let your hands come back up slowly.",
    "Keep your elbows tucked in."], tecom=["Band Tricep Pressdown"])
ex("band-wood-chop-high-to-low", "band high-to-low wood chop", "waist", BAND, "abs", "obliques", ["shoulders", "core"], [
    "Anchor a band high and stand side-on to it, holding it with both hands above the near shoulder.",
    "Pull the band down and across your body toward the opposite hip, rotating your torso and pivoting the back foot.",
    "Return slowly.",
    "Finish the set, then switch sides."], tecom=["Band Truck Twist High To Low"])
ex("band-upright-row", "band upright row", "shoulders", BAND, "delts", "shoulders", ["traps", "biceps"], [
    "Stand on the middle of a band, holding the ends in front of your thighs.",
    "Pull your hands straight up to chest height, leading with your elbows.",
    "Lower slowly.",
    "Keep the band close to your body."], tecom=["Band Upright Row"], sasebo=["Banded Upright Row"])
ex("band-seated-calf-press", "band seated calf press", "lower legs", BAND, "calves", "calves", [], [
    "Sit with your legs straight and loop a band around the ball of one or both feet, holding the ends.",
    "Point your toes away from you against the band.",
    "Return slowly.",
    "Keep your knees straight."], sasebo=["Banded Calf Raises"])
ex("band-standing-fly", "band standing chest fly", "chest", BAND, "pectorals", "chest", ["shoulders"], [
    "Anchor a band behind you at chest height and hold an end in each hand with arms out wide.",
    "With a slight bend in the elbows, bring your hands together in front of your chest.",
    "Return slowly until you feel a stretch across the chest.",
    "Keep your shoulders down."], sasebo=["Banded Fly"])
ex("band-lying-leg-curl", "band lying leg curl", "upper legs", BAND, "hamstrings", "hamstrings", ["calves"], [
    "Anchor a band low and lie face down with it looped around your ankles.",
    "Curl your heels toward your glutes.",
    "Lower slowly.",
    "Keep your hips pressed into the floor."], sasebo=["Banded Knee Flexion"])
ex("band-push-up", "band push-up", "chest", BAND, "pectorals", "chest", ["triceps", "shoulders"], [
    "Wrap a band across your upper back and hold the ends under your hands.",
    "Start in a push-up position.",
    "Lower your chest to the floor and press up against the band.",
    "Keep your body straight."], sasebo=["Banded Push-ups"])
ex("band-romanian-deadlift", "band romanian deadlift", "upper legs", BAND, "hamstrings", "hamstrings", ["glutes", "lower back"], [
    "Stand on the middle of a band, holding the ends in front of your thighs.",
    "Soften your knees and push your hips back, lowering your hands along your legs with a flat back.",
    "Drive your hips forward to stand tall.",
    "Keep the band close to your legs."], sasebo=["Banded Romanian Deadlift"])
ex("band-overhead-triceps-extension", "band overhead triceps extension", "upper arms", BAND, "triceps", "triceps", [], [
    "Stand on one end of a band and hold the other end behind your head, elbow pointing up.",
    "Straighten your arm overhead.",
    "Lower slowly behind your head.",
    "Keep the elbow close to your head."], sasebo=["Banded Tricep Extension"])
ex("band-shoulder-external-rotation", "band shoulder external rotation", "shoulders", BAND, "delts", "rotator cuff", ["upper back"], [
    "Anchor a band at elbow height and stand side-on, holding it in the far hand.",
    "Keep the elbow bent 90 degrees and tucked to your side.",
    "Rotate the forearm out away from your body, then return slowly.",
    "Finish the set, then switch sides."], sasebo=["External Shoulder Rotation"])
ex("band-shoulder-internal-rotation", "band shoulder internal rotation", "shoulders", BAND, "delts", "rotator cuff", ["chest"], [
    "Anchor a band at elbow height and stand side-on, holding it in the near hand.",
    "Keep the elbow bent 90 degrees and tucked to your side.",
    "Rotate the forearm in across your stomach, then return slowly.",
    "Finish the set, then switch sides."], sasebo=["Internal Shoulder Rotation"])
ex("band-lying-pullover", "band lying pullover", "back", BAND, "lats", "lats", ["chest", "triceps"], [
    "Anchor a band low behind your head and lie on your back holding it with straight arms overhead.",
    "Pull your arms over to your thighs, keeping them straight.",
    "Return slowly overhead.",
    "Keep your lower back on the floor."], sasebo=["Lying Pullover"])
ex("mini-band-squat", "mini-band squat", "upper legs", BAND, "glutes", "glutes", ["quads", "abductors"], [
    "Place a mini band just above your knees and stand with your feet shoulder-width apart.",
    "Squat down, pushing your knees out against the band.",
    "Stand back up, keeping the tension.",
    "Keep your chest up."], sasebo=["Mini-Band Squat"])

# ---------------------------------------------------------------- dumbbells, kettlebells, barbells
ex("dumbbell-3-way-shoulder-raise", "dumbbell 3-way shoulder raise", "shoulders", DB, "delts", "shoulders", ["traps"], [
    "Stand with a light dumbbell in each hand.",
    "Raise the dumbbells to the front, then lower; raise to the sides, then lower.",
    "Hinge forward and raise them out to the sides for the rear shoulders.",
    "That is one rep; keep the weights light and controlled."], tecom=["Dumbbell 3 Way Shoulder Raise"])
ex("dumbbell-curtsy-lunge", "dumbbell curtsy lunge", "upper legs", DB, "glutes", "glutes", ["quads", "adductors"], tecom=["Dumbbell Curtsy Lunge"])
ex("dumbbell-lateral-lunge", "dumbbell lateral lunge", "upper legs", DB, "adductors", "quads", ["glutes", "adductors"], tecom=["Dumbbell Lateral Lunge"])
ex("dumbbell-lateral-squat", "dumbbell lateral squat", "upper legs", DB, "adductors", "quads", ["glutes", "adductors"], tecom=["Dumbbell Lateral Squat"])
ex("dumbbell-lunge-to-press", "dumbbell lunge to overhead press", "upper legs", DB, "quads", "quads", ["glutes", "shoulders"],
   tecom=["Dumbbell Lunge to Overhead Press"])
ex("dumbbell-push-up", "dumbbell push-up", "chest", DB, "pectorals", "chest", ["triceps", "shoulders"], [
    "Place two dumbbells shoulder-width apart and hold them in a push-up position.",
    "Lower your chest between the handles.",
    "Push back up to straight arms.",
    "Keep your wrists straight and your body in one line."], tecom=["Dumbbell Pushup"])
ex("dumbbell-push-up-row", "dumbbell push-up with row", "back", DB, "upper back", "lats", ["chest", "triceps", "core"], [
    "Start in a push-up holding two dumbbells, feet a little wider than usual.",
    "Do a push-up.",
    "At the top, row one dumbbell to your hip, lower it, then row the other.",
    "Keep your hips square throughout."], tecom=["Dumbbell Pushup With Row"])
ex("dumbbell-rotational-lunge", "dumbbell rotational lunge", "upper legs", DB, "quads", "quads", ["glutes", "obliques"], [
    "Stand holding one dumbbell with both hands at your chest.",
    "Step back into a lunge and rotate your torso over the front leg.",
    "Turn back to centre and step up.",
    "Alternate legs."], tecom=["Dumbbell Rotational Lunge"])
ex("dumbbell-step-down", "dumbbell single-leg step down", "upper legs", DB, "quads", "quads", ["glutes"], tecom=["Dumbbell Single Leg Step Down"])
ex("dumbbell-bent-over-y-raise", "dumbbell bent-over y raise", "back", DB, "upper back", "lower traps", ["rear shoulders"], [
    "Hold light dumbbells and hinge forward with a flat back, arms hanging.",
    "Raise your arms up and out in a Y shape, thumbs up.",
    "Pause, then lower slowly.",
    "Keep your neck long."], sasebo=["Bent Over Y"])
ex("dumbbell-half-kneeling-press", "half-kneeling dumbbell press", "shoulders", DB, "delts", "shoulders", ["triceps", "core"], [
    "Kneel on one knee holding a dumbbell at the shoulder on the side of the down knee.",
    "Squeeze your glutes and brace your core.",
    "Press the dumbbell straight overhead, then lower to the shoulder.",
    "Finish the set, then switch sides."], sasebo=["Kneeling Overhead Press"])
ex("dumbbell-one-arm-romanian-deadlift", "one-arm dumbbell romanian deadlift", "upper legs", DB, "hamstrings", "hamstrings",
   ["glutes", "core"], [
    "Stand holding a dumbbell in one hand in front of your thigh.",
    "Push your hips back and lower the dumbbell along your leg with a flat back.",
    "Drive your hips forward to stand, resisting the twist.",
    "Finish the set, then switch hands."], sasebo=["One Arm Romanian Deadlift"])
ex("dumbbell-squat-to-press", "dumbbell squat to press", "upper legs", DB, "quads", "quads", ["glutes", "shoulders", "triceps"], [
    "Stand holding dumbbells at your shoulders.",
    "Squat down with your chest up.",
    "Stand up powerfully and press the dumbbells overhead in one movement.",
    "Lower to the shoulders as you go into the next squat."], sasebo=["Squat-to-overhead Press"])
ex("kettlebell-windmill-curl-press", "kettlebell double windmill curl to press", "shoulders", KB, "delts", "shoulders",
   ["obliques", "biceps", "hamstrings"], [
    "Hold a kettlebell overhead in one hand and another hanging in the other hand.",
    "Push your hips out to the side of the overhead bell and hinge down, eyes on the top bell.",
    "At the bottom, curl the low bell, then press it as you stand back up.",
    "Finish the set, then switch sides."], tecom=["Kettlebell Double Windmill Curl To Press"])
ex("kettlebell-lateral-lunge", "kettlebell lateral lunge", "upper legs", KB, "adductors", "quads", ["glutes", "adductors"],
   tecom=["Kettlebell Lateral Lunge"])
ex("kettlebell-overhead-lunge", "kettlebell overhead lunge", "upper legs", KB, "quads", "quads", ["glutes", "shoulders", "core"],
   tecom=["Kettlebell Overhead Lunge"])
ex("kettlebell-overhead-split-squat", "kettlebell overhead split squat", "upper legs", KB, "quads", "quads", ["glutes", "shoulders"],
   tecom=["Kettlebell Overhead Split Squat"])
ex("kettlebell-romanian-deadlift", "kettlebell romanian deadlift", "upper legs", KB, "hamstrings", "hamstrings", ["glutes", "lower back"],
   tecom=["Kettlebell Romanian Deadlift"])
ex("kettlebell-one-arm-swing", "kettlebell one-arm swing", "upper legs", KB, "glutes", "glutes", ["hamstrings", "core", "shoulders"], [
    "Stand with the kettlebell a foot in front of you, feet a little wider than your hips.",
    "Hinge and grab it with one hand, hike it back between your legs.",
    "Snap your hips forward to swing it to chest height, arm straight.",
    "Let it fall back into the next hinge; finish the set and switch hands."], tecom=["Kettlebell Swing (Single Arm)"])
ex("kettlebell-upright-row", "kettlebell upright row", "shoulders", KB, "delts", "shoulders", ["traps"], [
    "Hold a kettlebell by the horns in front of your thighs.",
    "Pull it straight up to chest height, leading with your elbows.",
    "Lower slowly.",
    "Keep the bell close to your body."], tecom=["Kettlebell Upright Row"])
ex("landmine-rotation", "landmine rotation", "waist", BB, "abs", "obliques", ["shoulders", "core"], [
    "Wedge one end of a barbell in a corner or landmine and hold the other end overhead with straight arms.",
    "Rotate the bar down to one hip, pivoting your feet and turning your torso.",
    "Bring it back up over your head and down to the other side.",
    "Keep your arms long and move with control."], tecom=["Landmine Rotation"])
ex("overhead-plate-lunge", "overhead plate lunge", "upper legs", "weighted", "quads", "quads", ["glutes", "shoulders", "core"],
   tecom=["Overhead Plate Lunge"])
ex("barbell-diagonal-lunge", "barbell diagonal lunge", "upper legs", BB, "quads", "quads", ["glutes", "adductors"], tecom=["Barbell Diagonal Lunge"])
ex("barbell-lateral-squat", "barbell lateral squat", "upper legs", BB, "adductors", "quads", ["glutes", "adductors"], tecom=["Barbell Lateral Squat"])
ex("barbell-push-press", "barbell push press", "shoulders", BB, "delts", "shoulders", ["triceps", "quads"], [
    "Hold a barbell in the front rack at your shoulders, hands just wider than shoulder-width.",
    "Dip a few inches by bending your knees, chest up.",
    "Drive up through your legs and press the bar overhead to locked arms.",
    "Lower it back to your shoulders under control."], tecom=["Barbell Push Press"])
ex("barbell-shrug-upright-row", "barbell shrug and upright row", "shoulders", BB, "traps", "traps", ["shoulders"], [
    "Hold a barbell in front of your thighs with an overhand grip.",
    "Shrug your shoulders straight up, then lower.",
    "Pull the bar up to chest height leading with your elbows, then lower.",
    "That is one rep."], tecom=["Barbell Shrug and Upright Row"])
ex("barbell-clean-hang-pull", "barbell hang clean pull", "upper legs", BB, "glutes", "glutes", ["hamstrings", "traps"], tecom=["Clean Hang Pull"])
ex("barbell-clean-high-pull", "barbell clean high pull", "upper legs", BB, "glutes", "glutes", ["hamstrings", "traps", "shoulders"],
   tecom=["Clean High Pull"])
ex("barbell-hang-clean", "barbell hang clean", "upper legs", BB, "glutes", "glutes", ["hamstrings", "traps", "quads"], [
    "Stand holding a barbell at your thighs, hands just outside your legs.",
    "Hinge until the bar is above your knees.",
    "Jump the hips forward, shrug and pull yourself under the bar, catching it on your shoulders with elbows high.",
    "Stand up, then lower the bar to your thighs."], tecom=["Hang Clean"])
ex("barbell-hang-snatch", "barbell hang snatch", "upper legs", BB, "glutes", "glutes", ["hamstrings", "shoulders", "traps"], [
    "Hold a barbell with a wide grip at your thighs.",
    "Hinge until the bar is above your knees.",
    "Drive your hips through and pull yourself under the bar, catching it overhead with locked arms in a partial squat.",
    "Stand up, then lower the bar."], tecom=["Hang Snatch"])
ex("barbell-power-snatch", "barbell power snatch", "upper legs", BB, "glutes", "glutes", ["hamstrings", "shoulders", "traps"], [
    "Stand over the barbell with a wide grip, hips lower than shoulders and back flat.",
    "Push the floor away to lift the bar past your knees, then extend your hips explosively.",
    "Pull under and catch the bar overhead with locked arms in a partial squat.",
    "Stand up and lower the bar."], tecom=["Power Snatch"])
ex("barbell-split-jerk", "barbell split jerk", "shoulders", BB, "delts", "shoulders", ["triceps", "quads"], [
    "Hold the barbell in the front rack at your shoulders.",
    "Dip and drive the bar up, splitting your feet into a lunge as you punch under it.",
    "Catch it overhead on locked arms.",
    "Step the front foot back, then the back foot forward, and lower the bar."], tecom=["Split Jerk"])
ex("snatch-press-under", "snatch press under", "shoulders", BB, "delts", "shoulders", ["triceps", "quads"], [
    "Stand with a light bar or PVC pipe on your back in a wide snatch grip, feet in squat stance.",
    "Press yourself down under the bar into an overhead squat while pushing up on it.",
    "Stand up with the bar overhead.",
    "Use this to practise the catch of the snatch."], tecom=["Press Under"])
ex("snatch-quick-drop", "snatch quick drop", "upper legs", BB, "quads", "quads", ["shoulders", "core"], [
    "Stand with a light bar or PVC pipe on your back in a wide snatch grip.",
    "Drop fast into an overhead squat, punching the bar up to locked arms.",
    "Hold the bottom briefly, then stand up.",
    "Practise speed under the bar."], tecom=["Quick Drop"])
ex("scarecrow", "scarecrow", "shoulders", BW, "delts", "rotator cuff", ["upper back"], [
    "Hold a broomstick or PVC pipe with your elbows out at shoulder height and bent 90 degrees, forearms hanging down.",
    "Rotate your forearms up until they point to the ceiling.",
    "Rotate back down slowly.",
    "Keep your elbows at shoulder height."], tecom=["Scarecrow"])

# ---------------------------------------------------------------- hanging, core, medicine ball
ex("hanging-flutter-kicks", "hanging flutter kicks", "waist", BW, "abs", "hip flexors", ["abs", "forearms"], [
    "Hang from a pull-up bar with straight arms.",
    "Lift your straight legs a little in front of you.",
    "Kick them up and down in small, quick alternating movements.",
    "Keep your body from swinging."], tecom=["Hanging Flutter Kicks"])
ex("hanging-leg-lowers", "hanging leg lowers", "waist", BW, "abs", "abs", ["hip flexors", "forearms"], [
    "Hang from a pull-up bar and raise your legs until they are level with your hips or higher.",
    "Lower them slowly to the bottom.",
    "Raise them again without swinging.",
    "Control the lowering phase."], tecom=["Hanging Leg Lowers"])
ex("hanging-windmill", "hanging windshield wiper", "waist", BW, "abs", "obliques", ["abs", "forearms"], [
    "Hang from a pull-up bar and raise your legs.",
    "Rotate them down to one side and back up.",
    "Then rotate to the other side.",
    "Keep your shoulders steady."], tecom=["Hanging Windmill"])
ex("med-ball-arch-chop", "medicine ball arching chop", "waist", MB, "abs", "abs", ["shoulders", "obliques"], [
    "Hold a medicine ball overhead with straight arms.",
    "Chop it down diagonally toward the outside of one foot, bending the knees.",
    "Lift it back up over the opposite shoulder in an arc.",
    "Alternate sides."], tecom=["Med Ball Arch Chops"])
ex("med-ball-crunch", "medicine ball crunch", "waist", MB, "abs", "abs", [], [
    "Lie on your back with your knees bent, holding a medicine ball straight up over your chest.",
    "Crunch up, reaching the ball toward the ceiling.",
    "Lower slowly.",
    "Keep your neck relaxed."], tecom=["Med Ball Crunch"])
ex("med-ball-figure-8", "medicine ball figure 8", "waist", MB, "abs", "abs", ["obliques", "hip flexors"], [
    "Sit leaning back with your feet off the floor, holding a medicine ball.",
    "Pass the ball under one leg and over the other in a figure 8.",
    "Keep your legs moving and your chest up.",
    "Reverse direction halfway."], tecom=["Med Ball figure 8's"])
ex("med-ball-single-leg-v-up", "medicine ball single-leg v-up", "waist", MB, "abs", "abs", ["hip flexors"], [
    "Lie on your back holding a medicine ball overhead.",
    "Lift one straight leg and your upper body, bringing the ball to your foot.",
    "Lower back down.",
    "Alternate legs."], tecom=["Med Ball Single Leg V Up"])
ex("med-ball-toe-touches", "medicine ball toe touches", "waist", MB, "abs", "abs", [], [
    "Lie on your back with your legs straight up toward the ceiling.",
    "Hold a medicine ball with straight arms over your chest.",
    "Crunch up and touch the ball to your toes.",
    "Lower slowly."], tecom=["Med Ball Toe Touches"])
ex("med-ball-v-up", "medicine ball v-up", "waist", MB, "abs", "abs", ["hip flexors"], [
    "Lie flat holding a medicine ball overhead.",
    "Lift your legs and upper body together and pass the ball to your feet.",
    "Lower down, then come back up to take the ball back in your hands.",
    "Move with control."], tecom=["Med Ball V Up"])
ex("med-ball-wood-chop", "medicine ball wood chopper", "waist", MB, "abs", "obliques", ["shoulders", "quads"], [
    "Hold a medicine ball above one shoulder.",
    "Squat and chop it down across your body to the outside of the opposite knee.",
    "Drive back up to the start.",
    "Finish the set, then switch sides."], tecom=["Med Ball Woodchoppers", "Med Ball Wood Chopper"])
ex("split-squat-med-ball-slam", "split squat with medicine ball slam", "upper legs", MB, "quads", "quads", ["abs", "shoulders"],
   tecom=["Split Squat with Med. Ball Slam"])

# ---------------------------------------------------------------- battle ropes
ex("rope-wave-lateral-lunge", "battle rope wave with lateral lunge", "upper legs", ROPE, "quads", "shoulders", ["quads", "glutes"],
   tecom=["Rope Alternating Wave with Lateral Lunge"])
ex("rope-wave-lunge", "battle rope wave with lunge", "upper legs", ROPE, "quads", "shoulders", ["quads", "glutes"],
   tecom=["Rope Alternating Wave with Lunge"])
ex("rope-wave-split-squat", "battle rope wave with split squat", "upper legs", ROPE, "quads", "shoulders", ["quads", "glutes"],
   tecom=["Rope Alternating Wave with Split Squat"])
ex("rope-side-plank-spiral", "battle rope side plank spiral", "waist", ROPE, "abs", "obliques", ["shoulders"], [
    "Hold one end of a battle rope and set up in a side plank on the other forearm.",
    "Draw circles with the rope, keeping your hips lifted.",
    "Keep your body in one straight line.",
    "Finish the set, then switch sides."], tecom=["Rope Side Plank Spiral"])
ex("rope-side-plank-waves", "battle rope side plank waves", "waist", ROPE, "abs", "obliques", ["shoulders"], [
    "Hold one end of a battle rope and set up in a side plank on the other forearm.",
    "Make quick up-and-down waves with the rope.",
    "Keep your hips lifted and still.",
    "Finish the set, then switch sides."], tecom=["Rope Side Plank Waves"])
ex("rope-kneeling-slam", "battle rope kneeling slam", "shoulders", ROPE, "delts", "shoulders", ["lats", "abs"], [
    "Kneel facing the rope anchor holding an end in each hand.",
    "Lift both ends overhead.",
    "Slam them down as hard as you can.",
    "Repeat quickly without leaning back."], tecom=["Kneeling Rope Throws"])
ex("rope-standing-slam", "battle rope slam", "shoulders", ROPE, "delts", "shoulders", ["lats", "abs", "quads"], [
    "Stand facing the anchor holding an end of the rope in each hand, knees slightly bent.",
    "Raise both ends overhead.",
    "Slam them down hard, dropping into a quarter squat.",
    "Repeat quickly."], tecom=["Standing Rope Throws"])

# ---------------------------------------------------------------- sandbag
ex("sandbag-bent-over-row", "sandbag bent-over row", "back", SB, "upper back", "lats", ["biceps", "rear shoulders"], [
    "Hold a sandbag by the handles and hinge forward with a flat back.",
    "Row the bag to your stomach, squeezing your shoulder blades.",
    "Lower with control.",
    "Keep your back flat throughout."], tecom=["Sandbad Bent Over Rows"])
ex("sandbag-balance-step-lunge", "sandbag balance step lunge", "upper legs", SB, "quads", "quads", ["glutes", "core"],
   tecom=["Sandbag Balance Step Lunge"])
ex("sandbag-bear-hug-squat", "sandbag bear hug squat", "upper legs", SB, "quads", "quads", ["glutes", "core", "upper back"],
   tecom=["Sandbag Bear Hug Squat"])
ex("sandbag-biceps-curl", "sandbag biceps curl", "upper arms", SB, "biceps", "biceps", ["forearms"], [
    "Hold a sandbag by the handles with palms forward and arms straight.",
    "Curl it up to your chest keeping your elbows at your sides.",
    "Lower slowly.",
    "Do not swing."], tecom=["Sandbag Bicep Curl"])
ex("sandbag-clean", "sandbag clean", "upper legs", SB, "glutes", "glutes", ["hamstrings", "traps"], tecom=["Sandbag Clean"])
ex("sandbag-cyclone", "sandbag cyclone", "waist", SB, "abs", "obliques", ["shoulders", "glutes"], [
    "Stand with a sandbag on the floor between your feet, feet wide.",
    "Grab it, lift it and swing it in a circle around your head.",
    "Bring it down on the other side.",
    "Alternate directions."], tecom=["Sandbag Cyclone"])
ex("sandbag-front-lunge", "sandbag front lunge", "upper legs", SB, "quads", "quads", ["glutes"], tecom=["Sandbag Front Lunge"])
ex("sandbag-front-squat", "sandbag front squat", "upper legs", SB, "quads", "quads", ["glutes", "core"], tecom=["Sandbag Front Squat"])
ex("sandbag-good-morning", "sandbag good morning", "upper legs", SB, "hamstrings", "hamstrings", ["glutes", "lower back"],
   tecom=["Sandbag Good Morning", "Sandbag Goodmorning"])
ex("sandbag-kneeling-around-world", "sandbag kneeling around the world", "waist", SB, "abs", "core", ["shoulders"], [
    "Kneel tall holding a sandbag in front of your chest.",
    "Circle it around your head, keeping your hips still.",
    "Bring it back to the front.",
    "Alternate directions."], tecom=["Sandbag Kneeling Aound The World"])
ex("sandbag-lateral-drag", "sandbag lateral drag", "waist", SB, "abs", "core", ["shoulders", "obliques"], [
    "Set up in a high plank with a sandbag beside one hand.",
    "Reach under your body with the other hand and drag the bag across to the far side.",
    "Repeat with the other hand.",
    "Keep your hips still and level."], tecom=["Sandbag Lateral Bag Drag"])
ex("sandbag-lateral-lunge", "sandbag lateral lunge", "upper legs", SB, "adductors", "quads", ["glutes", "adductors"], tecom=["Sandbag Lateral Lunge"])
ex("sandbag-overhead-lateral-lunge", "sandbag overhead lateral lunge", "upper legs", SB, "adductors", "quads", ["glutes", "shoulders"],
   tecom=["Sandbag Overhead Lateral Lunge"])
ex("sandbag-overhead-squat", "sandbag overhead squat", "upper legs", SB, "quads", "quads", ["glutes", "shoulders", "core"],
   tecom=["Sandbag Overhead Squat"])
ex("sandbag-romanian-deadlift", "sandbag romanian deadlift", "upper legs", SB, "hamstrings", "hamstrings", ["glutes", "lower back"],
   tecom=["Sandbag Romanian Deadlift"])
ex("sandbag-rotational-lunge", "sandbag rotational lunge", "upper legs", SB, "quads", "quads", ["glutes", "obliques"],
   tecom=["Sandbag Rotational Lunge"])
ex("sandbag-shoulder-lunge", "sandbag shoulder lunge", "upper legs", SB, "quads", "quads", ["glutes", "core"], tecom=["Sandbag Shoulder Lunge"])
ex("sandbag-shoulder-squat", "sandbag shoulder squat", "upper legs", SB, "quads", "quads", ["glutes", "core"], tecom=["Sandbag Shoulder Squat"])
ex("sandbag-single-grip-row", "sandbag single-grip bent-over row", "back", SB, "upper back", "lats", ["biceps", "core"], [
    "Hold a sandbag by one handle and hinge forward with a flat back.",
    "Row the bag to your hip.",
    "Lower with control and resist twisting.",
    "Finish the set, then switch hands."], tecom=["Sandbag Single Grip Bent Over Row", "Single Grip Vent Over Row"])
ex("sandbag-single-leg-deadlift", "sandbag single-leg deadlift", "upper legs", SB, "hamstrings", "hamstrings", ["glutes", "core"],
   tecom=["Sandbag Single Leg Deadlift"])
ex("sandbag-standing-around-world", "sandbag standing around the world", "waist", SB, "abs", "core", ["shoulders"], [
    "Stand tall holding a sandbag in front of your chest.",
    "Circle it around your head, keeping your hips still.",
    "Bring it back to the front.",
    "Alternate directions."], tecom=["Sandbag Standing Around The World"])
ex("sandbag-suitcase-lunge", "sandbag suitcase lunge", "upper legs", SB, "quads", "quads", ["glutes", "obliques"], tecom=["Sandbag Suitcase Lunge"])

# ---------------------------------------------------------------- recovery (foam roller, ball, stick)
def rolling(slug, n, bp, tg, where, titles, tool="foam roller"):
    ex(slug, n, bp, ROLL, tg, tg, [], [
        f"Place a {tool} under your {where}.",
        "Support yourself with your hands and feet and roll slowly up and down the area.",
        "Pause on tight spots and breathe for a few seconds.",
        "Roll for 30 to 60 seconds; avoid joints and bone."], tecom=titles)


rolling("roll-calf", "foam roll calves", "lower legs", "calves", "calves", ["Roll Calf"])
rolling("roll-forearm", "roll forearms", "lower arms", "forearms", "forearm", ["Roll Forearm w/ Peanut"], tool="peanut roller or two balls taped together")
rolling("roll-glute", "foam roll glutes", "upper legs", "glutes", "glute, crossing that ankle over the other knee", ["Roll Glute"])
rolling("roll-hamstring", "foam roll hamstrings", "upper legs", "hamstrings", "hamstrings", ["Roll Hamstring"])
rolling("roll-it-band", "foam roll outer thigh", "upper legs", "abductors", "outer thigh, lying on your side", ["Roll IT Band"])
rolling("roll-lower-back", "foam roll lower back", "back", "spine", "lower back, hugging your knees", ["Roll Lower Back"])
rolling("roll-quad", "foam roll quads", "upper legs", "quads", "thighs, lying face down", ["Roll Quad"])
rolling("roll-t-spine", "foam roll upper back", "back", "upper back", "upper back, hands behind your head", ["Roll T-Spine"])
rolling("roll-triceps", "foam roll triceps", "upper arms", "triceps", "back of your upper arm, lying on your side", ["Roll Tricep"])
rolling("roll-hip-flexor", "roll hip flexors", "upper legs", "quads", "front of your hip, lying face down", ["Rolling Hip Flexor"])
rolling("ball-roll-lats", "ball roll lats", "back", "lats", "side of your back below the armpit, lying on your side", ["Lax Ball Roll Lats"], tool="lacrosse ball")
rolling("ball-roll-glute", "ball roll glutes", "upper legs", "glutes", "glute while sitting, then fold forward", ["Lax Ball to Glute Fold"], tool="lacrosse ball")
rolling("ball-roll-foot", "ball roll hamstrings", "upper legs", "hamstrings", "back of your thigh while sitting", ["Lax Ball With Foot"], tool="lacrosse ball")
rolling("stick-quad", "stick roll quads", "upper legs", "quads", "thigh while sitting and press it", ["Stick Quad"], tool="massage stick")
rolling("stick-shin", "stick roll shins", "lower legs", "calves", "shin while sitting and press it", ["Stick Tibia"], tool="massage stick")
rolling("stick-hamstring", "stick roll hamstrings", "upper legs", "hamstrings", "back of your thigh while kneeling and press it", ["Stick To Hamstring"], tool="massage stick")
rolling("stick-lower-back", "stick roll lower back", "back", "spine", "lower back while sitting and press it", ["Stick to Lower Back"], tool="massage stick")

# ---------------------------------------------------------------- suspension trainer (filled in after review)
TRX_START = len(E)


def trx(slug, n, bp, tg, mg, sm, titles, st=None):
    ex("suspension-" + slug, "suspension " + n, bp, TRX, tg, mg, sm, st, tecom=titles)


def trx_steps(*middle):
    return ["Adjust the suspension trainer straps to the right length and hold both handles."] + list(middle) + [
        "Keep the straps taut the whole time; walk your feet closer or further away to change the difficulty."]


trx("assisted-squat", "assisted squat", "upper legs", "quads", "quads", ["glutes"], ["TRX Assisted Bottom Up Squat", "TRX Assisted Squat"], trx_steps(
    "Face the anchor, lean back slightly with your arms straight and feet hip-width apart.",
    "Sit down into a deep squat, using the straps to stay balanced and upright.",
    "Drive through your heels to stand."))
trx("squat-to-press", "assisted squat to press", "upper legs", "quads", "quads", ["glutes", "shoulders"], ["TRX Assisted Squat To Press"], trx_steps(
    "Face the anchor holding the handles at your chest.",
    "Squat down, then stand and press the handles up overhead as you rise.",
    "Lower the hands as you go into the next squat."))
trx("balance-lunge", "balance lunge", "upper legs", "quads", "quads", ["glutes", "core"], ["TRX Balance Lunge"])
trx("crossing-balance-lunge", "crossing balance lunge", "upper legs", "glutes", "glutes", ["quads", "abductors"], ["TRX Crossing Balance Lunge"], trx_steps(
    "Face the anchor with your arms straight.",
    "Step one leg back and across behind the other into a curtsy lunge, sinking low.",
    "Push through the front foot to stand and repeat on the other side."))
trx("biceps-curl", "biceps curl", "upper arms", "biceps", "biceps", ["forearms"], ["TRX Bicep Curls"], trx_steps(
    "Face the anchor and lean back with your arms straight in front of you, palms up.",
    "Curl your hands toward your forehead, keeping your elbows high and still.",
    "Lower back to straight arms with control."))
trx("burpee", "burpee", "cardio", "cardiovascular system", "quads", ["chest", "shoulders"], ["TRX Burpee"], [
    "Hook one foot into the foot cradle of a suspension trainer, facing away from the anchor.",
    "Squat down, place your hands on the floor and hop the free leg back into a plank.",
    "Do a push-up, hop the leg back in and jump up on the standing leg.",
    "Finish the set, then switch legs."])
trx("chest-press", "chest press", "chest", "pectorals", "chest", ["triceps", "shoulders"], ["TRX Chest Press"], trx_steps(
    "Face away from the anchor and lean forward with straight arms, body in one line.",
    "Lower your chest between the handles by bending your elbows.",
    "Press back up to straight arms."))
trx("clock-press", "clock press", "chest", "pectorals", "chest", ["shoulders", "core"], ["TRX Clock Press"], trx_steps(
    "Face away from the anchor and lean forward with straight arms.",
    "Open one arm out to the side like a clock hand as you lower your body, keeping the other arm straight.",
    "Press back to the centre and repeat to the other side."))
trx("cossack-squat", "cossack squat", "upper legs", "adductors", "quads", ["glutes", "adductors"], ["TRX Cossack"], trx_steps(
    "Face the anchor with your feet wide.",
    "Shift your weight to one side and sit deep into that leg, keeping the other leg straight with toes up.",
    "Push back through the middle to the other side."))
trx("curtsy-lunge", "curtsy lunge", "upper legs", "glutes", "glutes", ["quads", "adductors"], ["TRX Curtsy Lunge"])
trx("forward-lunge-hip-flexor", "forward lunge with hip flexor stretch", "upper legs", "quads", "hip flexors", ["quads"],
    ["TRX Forward Lunge with Hip Flexor Stretch"])
trx("half-kneeling-rollout", "half-kneeling rollout", "waist", "abs", "abs", ["lats", "shoulders"], ["TRX Half Kneeling Roll Out"], trx_steps(
    "Kneel on one knee facing away from the anchor, arms straight in front holding the handles.",
    "Lean forward and let your arms rise overhead, keeping your body in one line from knee to head.",
    "Pull back to the start using your abs and lats."))
trx("half-kneeling-y-fly", "half-kneeling y fly", "back", "upper back", "lower traps", ["rear shoulders"], ["TRX Half Kneeling Y Fly"], trx_steps(
    "Kneel on one knee facing the anchor and lean back with straight arms in front of you.",
    "Raise your arms up and out into a Y shape, pulling your chest toward the anchor.",
    "Lower back with control."))
trx("half-kneeling-split-squat", "split squat", "upper legs", "quads", "quads", ["glutes"], ["TRX Halk Kneeling Split Squat"], trx_steps(
    "Face the anchor in a split stance with your arms straight.",
    "Lower the back knee toward the floor, keeping your chest up.",
    "Drive through the front foot to stand; finish the set and switch legs."))
trx("high-row", "high row", "back", "upper back", "rear shoulders", ["upper back", "biceps"], ["TRX High Row"], trx_steps(
    "Face the anchor and lean back with your arms straight in front at shoulder height, palms down.",
    "Pull the handles to your face with your elbows high and out.",
    "Lower back to straight arms."))
trx("hip-abduction", "hip abduction", "upper legs", "abductors", "glutes", ["abductors"], ["TRX Hip Abduction"], [
    "Lie on your back with your heels in the foot cradles of a suspension trainer.",
    "Lift your hips off the floor into a straight line.",
    "Open your legs wide, then bring them back together.",
    "Keep your hips up throughout."])
trx("hip-drop", "hip drop", "waist", "abs", "obliques", ["abductors"], ["TRX Hip Drop"], trx_steps(
    "Stand side-on to the anchor holding the handles above your head.",
    "Let your hips drop out away from the anchor, stretching the side of your body.",
    "Pull the hips back under you to stand tall."))
trx("hip-hinge", "hip hinge", "upper legs", "hamstrings", "hamstrings", ["glutes", "lower back"], ["TRX Hip Hinge"], trx_steps(
    "Face the anchor with your arms straight and slightly raised.",
    "Push your hips back with a flat back, letting your arms rise overhead.",
    "Drive the hips forward to stand tall."))
trx("single-leg-hip-hinge", "single-leg hip hinge", "upper legs", "hamstrings", "hamstrings", ["glutes", "core"], ["TRX Hip Hinge Single Leg"], trx_steps(
    "Face the anchor and stand on one leg with your arms straight.",
    "Hinge forward, reaching the other leg back, until your body is close to level.",
    "Return to standing; finish the set and switch legs."))
trx("hip-press", "hip press", "upper legs", "glutes", "glutes", ["hamstrings"], ["TRX Hip Press"], [
    "Lie on your back with your heels in the foot cradles and your knees bent.",
    "Press your heels down and lift your hips until your body is straight from knees to shoulders.",
    "Lower slowly.",
    "Keep your arms on the floor for balance."])
trx("hamstring-curl", "hamstring curl", "upper legs", "hamstrings", "hamstrings", ["glutes", "calves"], ["TRX Hmastring Curl"], [
    "Lie on your back with your heels in the foot cradles and your legs straight.",
    "Lift your hips, then pull your heels toward your glutes.",
    "Straighten your legs again with your hips up.",
    "Move with control."])
trx("incline-press", "incline press", "chest", "pectorals", "upper chest", ["triceps", "shoulders"], ["TRX Incline Press"], trx_steps(
    "Face away from the anchor and lean forward with the handles held high.",
    "Lower by bending the elbows, pressing on an upward angle.",
    "Press back to straight arms."))
trx("jump-squat", "jump squat", "upper legs", "quads", "quads", ["glutes", "calves"], ["TRX Jump Squat"])
trx("long-torso-stretch", "long torso stretch", "waist", "abs", "lats", ["obliques"], ["TRX Long Torso Stretch"], trx_steps(
    "Stand side-on to the anchor holding both handles above your head.",
    "Cross the outside leg behind and lean your hips away, making a long curve along your side.",
    "Hold, then switch sides."))
trx("lunge", "lunge", "upper legs", "quads", "quads", ["glutes"], ["TRX Lunge"])
trx("lunge-hop", "lunge with hop", "upper legs", "quads", "quads", ["glutes", "calves"], ["TRX Lunge with Hop"])
trx("mid-row", "mid row", "back", "upper back", "upper back", ["lats", "biceps"], ["TRX Mid Row"], trx_steps(
    "Face the anchor and lean back with straight arms, palms facing in.",
    "Row your chest up to the handles, squeezing your shoulder blades.",
    "Lower back to straight arms."))
trx("overhead-back-extension", "overhead back extension", "back", "upper back", "lower traps", ["rear shoulders", "lower back"],
    ["TRX Overhead Back Extension"], trx_steps(
    "Face the anchor and lean back with straight arms.",
    "Pull your arms up overhead, keeping them straight, and bring your body upright.",
    "Lower back slowly."))
trx("pendulum", "pendulum", "waist", "abs", "obliques", ["shoulders", "core"], ["TRX Pendulum"], [
    "Put your feet in the foot cradles and hold a high plank with your hands under your shoulders.",
    "Swing your legs to one side and back, then to the other side.",
    "Keep your hips level and your arms straight.",
    "Move with control."])
trx("power-pull", "power pull", "back", "upper back", "lats", ["obliques", "biceps"], ["TRX Power Pull"], [
    "Face the anchor holding one handle with one hand and lean back.",
    "Let the free arm reach back and rotate your body open toward the floor.",
    "Pull yourself up and rotate back to face the anchor, reaching the free hand forward.",
    "Finish the set, then switch hands."])
trx("assisted-pull-up", "assisted pull-up", "back", "lats", "lats", ["biceps", "upper back"], ["TRX Pull Up", "TRX Pullup"], [
    "Set the straps low and sit underneath them, holding the handles with straight arms.",
    "Pull your chest up between the handles, helping with your legs as little as you can.",
    "Lower slowly to straight arms.",
    "Keep your shoulders down."])
trx("resisted-torso-rotation", "resisted torso rotation", "waist", "abs", "obliques", ["shoulders"], ["TRX Resisted Torso Rotation"], trx_steps(
    "Stand side-on to the anchor holding both handles with straight arms in front of your chest.",
    "Rotate your torso away from the anchor, then pull back to the middle.",
    "Finish the set, then switch sides."))
trx("reverse-lunge", "reverse lunge", "upper legs", "quads", "quads", ["glutes"], ["TRX Reverse Lunge"])
trx("single-arm-row", "single-arm row", "back", "upper back", "lats", ["biceps", "core"], ["TRX Single Arm Row"], trx_steps(
    "Face the anchor holding one handle and lean back with your arm straight.",
    "Row your body up, keeping your hips and shoulders square.",
    "Lower back slowly; finish the set and switch hands."))
trx("single-leg-jump-squat", "single-leg jump squat", "upper legs", "quads", "quads", ["glutes", "calves"], ["TRX Single Leg Jump Squat"], trx_steps(
    "Face the anchor and stand on one leg.",
    "Squat down on the standing leg and jump up explosively.",
    "Land softly on the same leg; finish the set and switch legs."))
trx("single-leg-squat", "single-leg squat", "upper legs", "quads", "quads", ["glutes"], ["TRX Single Leg Squat"], trx_steps(
    "Face the anchor and stand on one leg with the other held out in front.",
    "Sit down slowly as deep as you can on the standing leg.",
    "Drive up to stand; finish the set and switch legs."))
trx("speed-skater", "speed skater", "upper legs", "quads", "glutes", ["quads", "abductors"], ["TRX Speed Skater"])
trx("spiderman-push-up", "spiderman push-up", "chest", "pectorals", "chest", ["abs", "hip flexors"], ["TRX Spiderman Push Up"], [
    "Put your feet in the foot cradles and start in a push-up position.",
    "As you lower into a push-up, bring one knee toward the same-side elbow.",
    "Push up and return the leg, then repeat on the other side.",
    "Keep your hips level."])
trx("split-fly", "split fly", "chest", "pectorals", "chest", ["shoulders"], ["TRX Split Fly"], trx_steps(
    "Face away from the anchor and lean forward with straight arms.",
    "Open one arm out to the side while the other stays forward, lowering your chest.",
    "Bring the arm back and repeat to the other side."))
trx("split-squat-m-fly", "split squat with M fly", "upper legs", "quads", "quads", ["rear shoulders", "upper back"],
    ["TRX Split Squat with M Deltoid Fly", "TRX Split Squat W/ M Deltoid Fly"], trx_steps(
    "Face the anchor in a split stance, leaning back with straight arms.",
    "Lower into a split squat while pulling your elbows down and back into an M shape.",
    "Stand and straighten your arms; finish the set and switch legs."))
trx("split-squat-t-fly", "split squat with T fly", "upper legs", "quads", "quads", ["rear shoulders", "upper back"],
    ["TRX Split Squat with T Deltoid Fly", "TRX Split Squat w/ T Deltoid Fly"], trx_steps(
    "Face the anchor in a split stance, leaning back with straight arms.",
    "Lower into a split squat while opening your straight arms out to the sides in a T.",
    "Stand and bring your arms back together; finish the set and switch legs."))
trx("split-squat-y-fly", "split squat with Y fly", "upper legs", "quads", "quads", ["lower traps", "rear shoulders"],
    ["TRX Split Squat with Y Deltoid Fly", "TRX Split Squat w/ Y Deltoid Fly"], trx_steps(
    "Face the anchor in a split stance, leaning back with straight arms.",
    "Lower into a split squat while raising your straight arms overhead into a Y.",
    "Stand and lower your arms; finish the set and switch legs."))
trx("squat", "squat", "upper legs", "quads", "quads", ["glutes", "hamstrings"], ["TRX Squat"])
trx("step-back-lunge", "step-back lunge", "upper legs", "quads", "quads", ["glutes"], ["TRX Step Back Lunge"], trx_steps(
    "Face the anchor with your arms straight.",
    "Step one foot back and lower into a lunge.",
    "Push through the front foot to step back up; alternate legs."))
trx("supine-plank", "supine plank", "waist", "abs", "glutes", ["hamstrings", "core"], ["TRX Supine Plank"], [
    "Lie on your back with your heels in the foot cradles and your arms on the floor.",
    "Lift your hips until your body is straight from heels to shoulders.",
    "Hold without letting your hips sag.",
    "Lower slowly."])
trx("t-spine-rotation", "t-spine rotation", "back", "upper back", "thoracic spine", ["obliques"], ["TRX T-Spine Rotation"], trx_steps(
    "Stand side-on to the anchor holding one handle with the near hand, leaning back.",
    "Reach the other arm under and across, then rotate open and reach it up and back.",
    "Follow your hand with your eyes; finish the set and switch sides."))
trx("triceps-press", "triceps press", "upper arms", "triceps", "triceps", ["chest"], ["TRX Tricep Press"], trx_steps(
    "Face away from the anchor and lean forward with straight arms at shoulder height.",
    "Bend only your elbows, bringing your hands toward your forehead.",
    "Straighten your arms to push back up."))
trx("v-sit", "v-sit", "waist", "abs", "abs", ["hip flexors"], ["TRX V-Sit"], [
    "Lie on your back with your heels in the foot cradles.",
    "Lift your upper body and reach your hands toward your feet into a V.",
    "Lower back down slowly.",
    "Keep your legs straight."])
trx("abducted-lunge", "abducted lunge", "upper legs", "adductors", "quads", ["glutes", "adductors"], ["TRX Abducted Lunge"])
trx("active-straight-leg-raise", "active straight leg raise", "upper legs", "hamstrings", "hamstrings", ["hip flexors"], ["TRX Active Straight Leg Raises"])

# ---------------------------------------------------------------- last few
ex("walking-plank", "plank walk-out", "waist", BW, "abs", "core", ["shoulders", "hamstrings"], [
    "Stand tall, then bend forward and put your hands on the floor.",
    "Walk your hands out until you are in a high plank.",
    "Walk them back to your feet and stand up.",
    "Keep your legs as straight as you can."], tecom=["Walking Plank"])
ex("wall-ball", "wall ball", "upper legs", MB, "quads", "quads", ["glutes", "shoulders"], [
    "Stand facing a wall holding a medicine ball at your chest.",
    "Squat down, then stand explosively and throw the ball up to a target on the wall.",
    "Catch it and sink straight into the next squat.",
    "Keep your chest up."], tecom=["Wall Ball"])
ex("warrior-stretch", "world's greatest stretch", "upper legs", BW, "quads", "hip flexors", ["hamstrings", "upper back"], [
    "Step forward into a deep lunge and place both hands on the floor inside the front foot.",
    "Drop the same-side elbow toward the front instep.",
    "Rotate and reach that arm up toward the ceiling, following it with your eyes.",
    "Return and step through to the other side."], tecom=["Warrior Stretch"])
ex("wide-outs", "squat wide-outs", "upper legs", BW, "quads", "quads", ["glutes", "adductors"], [
    "Start in a quarter squat with your feet together and hands at your chest.",
    "Jump your feet out wide and land in a deeper squat.",
    "Jump them back together and repeat quickly.",
    "Stay low throughout."], tecom=["Wideouts"])

# Demos of exercises already in the catalogue: title -> openGym ids.
TECOM_MORE = {"Barbell back squat": ["0043"], "Barbell Dead Lift": ["0032"], "Butterfly": ["1494"], "Dumbbell Bicep Curl": ["0375"],
              "Hip Adduction": ["3667"], "Seated Band Row": ["3144"]}
SASEBO_MORE = {"Banded Forward Raise": ["0978"], "Banded Knee Extension": ["3007"], "Banded Palloff Press": ["0979"],
               "Bent Over Row": ["0293"], "Bent Over T": ["0380"], "Biceps Curl": ["0294"], "Bound Angle Stretch": ["1494"],
               "Forward & Backward Monster Walks": ["0628"], "One-arm Bent Over Row": ["0292"], "Quadriceps Stretch": ["1713"],
               "Sideways Monster Walk": ["0628"], "Split Squat": ["2368"]}

# Clips whose busiest window starts on a fade or a cut: seconds to skip at the start of the video.
SKIP_START = {"Long Arm Pull and Rotate": 2.0}
# Clips cut at a fixed window (start, length) in seconds, past fades the motion search would pick.
# Keys are titles (every take) or "video:ID" (one take); picked from full-video timelines.
CUTS = {"Traveling Push Up": (23.6, 8.0),
        "video:640272": (5.0, 13.5),   # TRX Inverted Row: rows only, not standing up after
        "video:753721": (1.5, 8.0),    # Lat Stretch on Bar: side view, before the dissolve
        "video:679685": (9.5, 6.5),    # Hanging Oblique Knee Raises: hanging part only
        "video:636929": (6.5, 12.0),   # Dumbbell Kickback: after setting up on the bench
        "video:753252": (1.5, 9.0),    # EZ Bar Curl: the barbell part, not the dumbbell part after
        "video:754731": (9.0, 9.0),    # Kettlebell Swing: swings, not the set-up
        "video:551361": (13.5, 14.0),  # Bear Crawl: crawling, not standing
        }


def steps_from(desc):
    """Preparation/Execution text of a Marine Corps demo, as steps addressed to the reader."""
    d = (desc or "").replace("\r", "")
    prep = re.search(r"Preparation:\s*(.*?)(?=Execution:|$)", d, re.S)
    exe = re.search(r"Execution:\s*(.*?)(?=Common Mistakes|Coaching|$)", d, re.S)
    if not exe:
        return None
    mist = re.search(r"Common Mistakes:\s*(.*)$", d, re.S)
    parts = [x.group(1).strip() for x in (prep, exe) if x]
    text = " ".join(p if p.endswith((".", "!")) else p + "." for p in parts)
    text = re.sub(r"\s+", " ", text).strip()
    sentences = [s.strip() for s in re.split(r"(?<=[.!])\s+", text) if s.strip()]
    out = []
    for s in sentences:
        s = re.sub(r"^(The|Each) Marines?(’|')?s? will (then )?", "", s)
        s = re.sub(r"^(They|He|She) will (then )?", "", s)
        s = re.sub(r"^Once \w+, the Marine will ", "Once there, ", s)
        s = re.sub(r"\bthe Marine(’|')s\b", "your", s, flags=re.I)
        s = re.sub(r"\bThe Marines\b", "Your", s)
        s = re.sub(r"\bthe Marine will\b", "you", s, flags=re.I)
        s = re.sub(r"\bthe Marine\b", "you", s, flags=re.I)
        s = re.sub(r"\bthemselves\b", "yourself", s)
        s = re.sub(r"\btheir\b", "your", s)
        s = re.sub(r"\bTheir\b", "Your", s)
        s = re.sub(r"\bthey will\b", "you", s)
        s = re.sub(r"\bthey\b", "you", s)
        s = re.sub(r"\bthem\b", "you", s)
        s = re.sub(r"\bthe deck\b", "the floor", s)
        s = re.sub(r"\bdeck\b", "floor", s)
        s = s.replace("you is", "you are").replace("you has", "you have")
        s = re.sub(r"\b(then|and) will\b", r"\1", s)
        s = re.sub(r"^Lay down\b", "Lie down", s)
        s = re.sub(r"\bthe TRX\b", "the suspension trainer", s).replace("TRX", "suspension trainer")
        if not s.endswith((".", "!")):
            s += "."
        out.append(s[0].upper() + s[1:])
    if mist:
        items = [re.sub(r"\s+", " ", m).strip(" -–\t") for m in re.split(r"\n\s*-|\s-\s", mist.group(1))]
        items = [m for m in items if m]
        if items:
            avoid = "; ".join(i[0].lower() + i[1:] for i in items).rstrip(".")
            avoid = re.sub(r"\b(the )?deck\b", "the floor", avoid).replace("TRX", "suspension trainer")
            out.append("Avoid: " + avoid + ".")
    return out or None


def build():
    sys.path.insert(0, HERE)
    import dvids as D
    titles = {x["name"]: x for x in json.load(open(os.path.join(HERE, "tecom-titles.json")))}
    missing = []
    for e in E:
        if e["st"] is None:
            for t in e["tecom"]:
                st = steps_from(D.asset(titles[t]["id"]).get("description"))
                if st:
                    e["st"] = st
                    break
        if not e["st"]:
            missing.append(e["id"])
    if missing:
        raise SystemExit("no steps for: " + ", ".join(missing))
    ids = [e["id"] for e in E]
    dupes = {i for i in ids if ids.count(i) > 1}
    assert not dupes, dupes
    js = ["// Generated by apple/mediatools/dvids_extras.py from public-domain US military demo videos (DVIDS).",
          "// Each has a free video demo; edit the generator, not this file.", "export const EXTRAS_DVIDS = ["]
    for e in E:
        row = {k: e[k] for k in ("id", "n", "bp", "eq", "tg", "mg", "sm", "st")}
        js.append("  " + json.dumps(row, ensure_ascii=False) + ",")
    js.append("]")
    open(os.path.join(HERE, "..", "core", "extras-dvids.js"), "w").write("\n".join(js) + "\n")
    print(len(E), "exercises")


def tecom_targets():
    """TECOM title -> openGym ids, for fetch_free.py."""
    out = {t: list(ids) for t, ids in TECOM_MORE.items()}
    for e in E:
        for t in e["tecom"]:
            out.setdefault(t, []).append(e["id"])
    return out


def sasebo_targets():
    out = {t: list(ids) for t, ids in SASEBO_MORE.items()}
    for e in E:
        for t in e["sasebo"]:
            out.setdefault(t, []).append(e["id"])
    return out


if __name__ == "__main__":
    build()
