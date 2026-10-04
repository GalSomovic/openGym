"""Core: sit-ups, crunches, leg raises and planks. Lying exercises keep the head to the left."""
from __future__ import annotations

import math

from registry import exercise
from rig import (L, SHOULDER_AT, Limb, Pose, add, angle_of, ankle_on_floor, arm_to, ease, grounded, keyed, leg_to,
                 lerp, lerp_angle, pose, v)
from exercises import LEG, updown, straight_limb, plank, plank_body, toes_ankle
from ex_push import push_up_pose

HIP = (0.0, 0.075)          # the pelvis resting on the floor
BENCH = 0.26


def arms_for(p: Pose, style: str):
    """Where the arms go on a lying or sitting body."""
    if style == "head":       # fingertips at the temples, elbows forward
        tgt = add(p.head_center(), v(p.head - 90, 0.03))
        a = arm_to(p, "n", tgt, +1, hand=p.head + 90)
        p.arm_n = a; p.arm_f = a
    elif style == "chest":    # crossed on the chest
        tgt = add(p.shoulder(), v(p.torso - 90, 0.10))
        a = arm_to(p, "n", add(tgt, v(p.torso + 180, 0.04)), +1, hand=p.torso + 180)
        p.arm_n = a; p.arm_f = a
    elif style == "overhead": # straight past the head
        p.arm_n = straight_limb(p.torso); p.arm_f = straight_limb(p.torso + 3)
    elif style == "forward":  # reaching toward the knees
        a = p.torso - 150
        p.arm_n = straight_limb(a); p.arm_f = straight_limb(a + 3)
    elif style == "floor":    # long on the floor beside the body
        sh = p.shoulder()
        reach = L['uarm'] + L['farm'] - 0.005
        wrist = (sh[0] + math.sqrt(max(reach ** 2 - (sh[1] - 0.025) ** 2, 0.0001)), 0.025)
        a = angle_of(sh, wrist)
        p.arm_n = Limb(a, a, 0); p.arm_f = p.arm_n
    elif style == "up":       # straight up toward the ceiling
        p.arm_n = straight_limb(90); p.arm_f = straight_limb(92)
    return p


def legs_for(p: Pose, style, side="both", k=1.0):
    def set_(s, limb):
        if side in ("both", s):
            setattr(p, f"leg_{s}", limb)
    if style == "bent":       # feet flat, knees up
        for s, dx in (("n", 0.0), ("f", -0.01)):
            if side in ("both", s):
                setattr(p, f"leg_{s}", leg_to(p, s, ankle_on_floor(p.hip[0] + 0.30 + dx), +1))
    elif style == "straight":
        for s in "nf":
            set_(s, Limb(0, 0, 90))
    elif style == "tabletop":
        for s in "nf":
            set_(s, Limb(90, 0, 60))
    elif isinstance(style, tuple):   # (thigh, shin)
        for s in "nf":
            set_(s, Limb(style[0], style[1], style[1] + 80))
    return p


def supine(torso=178, head=None, hip=HIP, arms="head", legs="bent"):
    p = Pose(hip=hip, torso=torso, head=torso if head is None else head)
    legs_for(p, legs)
    arms_for(p, arms)
    return p


def sit_up(t, top=95, arms="head", legs="bent", period_shape=None):
    d = updown(t, down=(0.06, 0.44), up=(0.56, 0.95))
    torso = lerp(178, top, d)
    return supine(torso, torso - 18 * d, arms=arms, legs=legs)


for id, name, top, arms in (("0001", "3/4 sit-up", 118, "head"), ("3204", "arms overhead full sit-up (male)", 92, "overhead"),
                            ("3202", "half sit-up (male)", 135, "forward"), ("3201", "quarter sit-up", 155, "forward"),
                            ("3203", "prisoner half sit-up (male)", 135, "head"), ("3679", "sit-up with arms on chest", 95, "chest"),
                            ("0735", "sit-up v. 2", 95, "head"), ("0456", "flexion leg sit up (bent knee)", 100, "chest"),
                            ("0457", "flexion leg sit up (straight arm)", 100, "forward"), ("0508", "janda sit-up", 105, "forward"),
                            ("3016", "curl-up", 150, "chest"), ("0267", "crunch (hands overhead)", 150, "overhead"),
                            ("3640", "knee touch crunch", 140, "forward"), ("2429", "frog crunch", 148, "head"),
                            ("0469", "groin crunch", 148, "head")):
    exercise(id, name, 2.4, active=("torso",))(lambda t, top=top, arms=arms: sit_up(t, top, arms))


@exercise("0634", "negative crunch", 3.2, active=("torso",))
def negative_crunch(t):
    # Start at the top and lower as slowly as you can, then come back up.
    if t < 0.15:
        d = 1 - ease(t / 0.15) if False else ease(t / 0.15)
        torso = lerp(178, 120, d)
    else:
        torso = lerp(120, 178, (t - 0.15) / 0.85)
    return supine(torso, torso - 10, arms="chest")


@exercise("0282", "decline sit-up", 2.6, active=("torso",), props=("floor", ("box", 0.25, 0.70, 0.30)))
def decline_sit_up(t):
    d = updown(t, down=(0.06, 0.44), up=(0.56, 0.95))
    hip = (0.0, 0.30 + 0.075)
    torso = lerp(190, 100, d)
    p = Pose(hip=hip, torso=torso, head=torso - 15 * d)
    for s in "nf":
        setattr(p, f"leg_{s}", leg_to(p, s, (0.36, 0.30 + 0.12), +1, foot=30))
    return arms_for(p, "chest")


@exercise("0277", "decline crunch", 2.4, active=("torso",), props=("floor", ("box", 0.25, 0.70, 0.30)))
def decline_crunch(t):
    d = updown(t)
    hip = (0.0, 0.375)
    torso = lerp(190, 150, d)
    p = Pose(hip=hip, torso=torso, head=torso - 20 * d)
    for s in "nf":
        setattr(p, f"leg_{s}", leg_to(p, s, (0.36, 0.42), +1, foot=30))
    return arms_for(p, "head")


@exercise("0495", "incline twisting sit-up", 2.8, active=("torso",), props=("floor", ("box", 0.25, 0.70, 0.30)))
def incline_twist(t):
    p = decline_sit_up(t)
    k = updown(t)
    # The twist shows as one elbow reaching across toward the opposite knee.
    side = "n" if t < 0.5 else "f"
    limb = getattr(p, f"arm_{side}")
    setattr(p, f"arm_{side}", Limb(limb.a1 - 30 * k, limb.a2 - 30 * k, limb.a3))
    return p


def leg_tuck_crunch(t, cross=False, tuck=False):
    d = updown(t)
    torso = lerp(178, 145, d)
    p = supine(torso, torso - 18 * d, arms="head", legs="bent")
    side = ("n" if t < 0.5 else "f") if cross else "both"
    thigh = lerp(-30, 100, d) if False else None
    knee_in = Limb(lerp(55, 115, d), lerp(-15, -10, d), 40)
    for s in "nf":
        if side in ("both", s):
            setattr(p, f"leg_{s}", knee_in)
    return p


exercise("0262", "cross body crunch", 2.6, active=("torso",))(lambda t: leg_tuck_crunch(t, cross=True))
exercise("0443", "elbow-to-knee", 2.4, active=("torso",))(lambda t: leg_tuck_crunch(t, cross=True))
exercise("2312", "lying elbow to knee", 2.4, active=("torso",))(lambda t: leg_tuck_crunch(t, cross=True))
exercise("0871", "tuck crunch", 2.4, active=("torso", "legs"))(lambda t: leg_tuck_crunch(t, tuck=True))


@exercise("0003", "air bike", 1.6, active=("torso", "legs"))
def air_bike(t):
    # Shoulders up, pedalling: one knee in while the other leg extends low, elbow across.
    ph = (math.sin(2 * math.pi * t) + 1) / 2
    p = supine(150, 132, arms="head")
    for s, k in (("n", ph), ("f", 1 - ph)):
        setattr(p, f"leg_{s}", Limb(lerp(20, 105, k), lerp(14, -5, k), lerp(70, 40, k)))
    return p


exercise("gf-bicycle-crunch", "bicycle crunch", 1.6, active=("torso", "legs"))(air_bike)


@exercise("0006", "alternate heel touchers", 1.8, active=("torso",))
def heel_touchers(t):
    # Shoulders curled up, reaching down the side toward each heel in turn.
    p = supine(155, 140, arms="floor")
    reach = math.sin(2 * math.pi * t)
    for s, k in (("n", max(0, reach)), ("f", max(0, -reach))):
        a = getattr(p, f"arm_{s}").a1
        setattr(p, f"arm_{s}", straight_limb(a - 8 * k))
    p.hip = (p.hip[0] - 0.0, p.hip[1])
    return p


@exercise("0276", "dead bug", 3.2, active=("torso",))
def dead_bug(t):
    # Arms up, knees over hips; opposite arm and leg lower toward the floor, then switch.
    p = supine(178, arms="up", legs="tabletop")
    for (arm_s, leg_s), (a, b) in ((("n", "f"), (0.04, 0.46)), (("f", "n"), (0.54, 0.96))):
        k = updown((t - a) / (b - a)) if a <= t <= b else 0
        if k:
            setattr(p, f"arm_{arm_s}", straight_limb(lerp(90, 172, k)))
            setattr(p, f"leg_{leg_s}", Limb(lerp(90, 12, k), lerp(0, 8, k), 70))
    return p


@exercise("gf-bird-dog", "bird dog", 3.2, active=("torso",))
def bird_dog(t):
    # On hands and knees: reach one arm forward and the opposite leg back, level with the body.
    hip = (-0.10, 0.48)
    p = Pose(hip=hip, torso=2, head=8)
    for s in "nf":
        setattr(p, f"leg_{s}", leg_to(p, s, (hip[0] - 0.02, 0.05), -1, foot=180))
        setattr(p, f"arm_{s}", straight_limb(-90))
    p.hip = (hip[0], 0.05 + L['thigh'])
    for s in "nf":
        knee = (p.hip[0], 0.05)
        setattr(p, f"leg_{s}", Limb(-90, 180, 170))
    sh = p.shoulder()
    for s in "nf":
        setattr(p, f"arm_{s}", arm_to(p, s, (sh[0], 0.022), -1, hand=0))
    for (arm_s, leg_s), (a, b) in ((("n", "f"), (0.04, 0.46)), (("f", "n"), (0.54, 0.96))):
        k = updown((t - a) / (b - a)) if a <= t <= b else 0
        if k:
            setattr(p, f"arm_{arm_s}", straight_limb(lerp_angle(-90, 4, k)))
            setattr(p, f"leg_{leg_s}", Limb(lerp_angle(-90, 182, k), lerp_angle(180, 182, k), lerp_angle(170, 180, k)))
    return p


@exercise("0459", "flutter kicks", 1.2, active=("torso", "legs"))
def flutter_kicks(t):
    p = supine(176, 160, arms="floor", legs="straight")
    k = math.sin(2 * math.pi * t)
    p.leg_n = Limb(14 + 9 * k, 14 + 9 * k, 75); p.leg_f = Limb(14 - 9 * k, 14 - 9 * k, 75)
    return p


exercise("3219", "scissor jumps (male)", 1.2, active=("legs",))(flutter_kicks) if False else None


def leg_raise(t, bench=False, hips=False, bent=False, seated=False):
    d = updown(t)
    hip = (0.0, (BENCH if bench else 0.0) + 0.075)
    p = Pose(hip=hip, torso=178, head=178)
    thigh = lerp(-8 if bench else 3, 92 if not bent else 100, d)
    shin = thigh - (lerp(0, 90, d) if bent else 0)
    if hips:   # at the top the hips curl off the floor
        p.hip = add(hip, (0.0, 0.05 * updown(t, down=(0.30, 0.47), up=(0.53, 0.70))))
        p.torso = 178 - 6 * updown(t, down=(0.30, 0.47), up=(0.53, 0.70))
    p.leg_n = Limb(thigh, shin, shin + 85); p.leg_f = Limb(thigh - 2, shin - 2, shin + 83)
    arms_for(p, "floor")
    if bench:   # holding the bench behind the head
        p.arm_n = arm_to(p, "n", add(p.head_center(), (-0.10, -0.04)), -1, hand=180); p.arm_f = p.arm_n
    return p


exercise("0620", "lying leg raise flat bench", 2.6, active=("torso", "legs"),
         props=("floor", ("box", -0.05, 0.75, BENCH)))(lambda t: leg_raise(t, bench=True))
exercise("0865", "lying leg-hip raise", 2.8, active=("torso", "legs"))(lambda t: leg_raise(t, hips=True))
exercise("0491", "incline leg hip raise (leg straight)", 2.8, active=("torso", "legs"),
         props=("floor", ("box", -0.05, 0.75, BENCH)))(lambda t: leg_raise(t, bench=True, hips=True))
exercise("2802", "twisted leg raise", 2.6, active=("torso", "legs"))(lambda t: leg_raise(t))
exercise("2801", "twisted leg raise (female)", 2.6, active=("torso", "legs"))(lambda t: leg_raise(t))
exercise("gf-lying-leg-raise", "lying leg raise", 2.6, active=("torso", "legs"))(lambda t: leg_raise(t))


@exercise("0872", "reverse crunch", 2.4, active=("torso", "legs"))
def reverse_crunch(t):
    # Knees tucked; curl the hips up off the floor toward the chest.
    d = updown(t)
    p = Pose(hip=add(HIP, (0.0, 0.07 * d)), torso=178 - 12 * d, head=178)
    p.leg_n = Limb(lerp(75, 125, d), lerp(-10, 10, d), 50); p.leg_f = p.leg_n
    return arms_for(p, "floor")


exercise("0484", "hip raise (bent knee)", 2.4, active=("torso", "legs"))(reverse_crunch)


@exercise("3420", "v-sit on floor", 3.0, active=("torso", "legs"))
def v_sit(t):
    # Balanced on the seat, legs and chest up in a V, held.
    w = 0.02 * math.sin(2 * math.pi * t)
    p = Pose(hip=HIP, torso=125 + 2 * w * 100, head=118)
    p.leg_n = Limb(48 - w * 100, 48 - w * 100, 75); p.leg_f = p.leg_n
    p.arm_n = straight_limb(20); p.arm_f = straight_limb(22)
    return p


def v_up(t):
    d = updown(t, down=(0.06, 0.40), up=(0.55, 0.95))
    p = Pose(hip=HIP, torso=lerp(178, 118, d), head=lerp(178, 112, d))
    leg = lerp(4, 58, d)
    p.leg_n = Limb(leg, leg, 80); p.leg_f = p.leg_n
    reach = lerp(178, 50, d)
    p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach + 3)
    return p


exercise("gf-v-up", "v-up", 2.4, active=("torso", "legs"))(v_up)
exercise("0507", "jackknife sit-up", 2.4, active=("torso", "legs"))(v_up)
exercise("3231", "two toe touch (male)", 2.4, active=("torso", "legs"))(v_up)


@exercise("0260", "cocoons", 2.6, active=("torso", "legs"))
def cocoons(t):
    # Stretched long, then curl into a ball, knees to chest, arms around them.
    d = updown(t)
    p = Pose(hip=HIP, torso=lerp(178, 130, d), head=lerp(178, 120, d))
    p.leg_n = Limb(lerp(4, 110, d), lerp(4, -20, d), 70); p.leg_f = p.leg_n
    reach = lerp(178, 30, d)
    p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach + 3)
    return p


@exercise("gf-hollow-hold", "hollow body hold", 3.0, active=("torso", "legs"))
def hollow_hold(t):
    w = 0.6 * math.sin(2 * math.pi * t)
    p = Pose(hip=HIP, torso=162 + w, head=150)
    p.leg_n = Limb(16 - w, 16 - w, 78); p.leg_f = p.leg_n
    p.arm_n = straight_limb(168); p.arm_f = straight_limb(170)
    return p


@exercise("0687", "russian twist", 1.8, active=("torso",))
def russian_twist(t):
    # Seated V, feet up, the hands sweeping from one hip to the other.
    p = Pose(hip=HIP, torso=128, head=122)
    p.leg_n = Limb(32, -10, 60); p.leg_f = p.leg_n
    sw = math.sin(2 * math.pi * t)
    chest = add(p.shoulder(), v(p.torso - 90, 0.05))
    side_pt = add(p.hip, (0.06, -0.02 + 0.03 * (1 - abs(sw))))
    hands = (lerp(chest[0], side_pt[0] + 0.1 * sw, abs(sw)), lerp(chest[1], side_pt[1] + 0.02, abs(sw)))
    p.arm_n = arm_to(p, "n", hands, -1, hand=0); p.arm_f = arm_to(p, "f", add(hands, (-0.01, 0.0)), -1, hand=0)
    return p


exercise("0500", "isometric wipers", 2.4, active=("torso",))(russian_twist)


@exercise("0689", "seated leg raise", 2.2, active=("torso", "legs"))
def seated_leg_raise(t):
    # Sitting tall, hands beside the hips, the straight legs lift off the floor.
    d = updown(t)
    p = Pose(hip=HIP, torso=100, head=96)
    leg = lerp(2, 30, d)
    p.leg_n = Limb(leg, leg, 85); p.leg_f = p.leg_n
    hand = (p.hip[0] - 0.05, 0.025)
    p.arm_n = arm_to(p, "n", hand, +1, hand=180); p.arm_f = p.arm_n
    return p


@exercise("0555", "kick out sit", 1.8, active=("torso", "legs"))
def kick_out_sit(t):
    # Leaning back on the hands, knees tuck in, then kick out straight.
    d = updown(t)
    p = Pose(hip=HIP, torso=128, head=118)
    p.leg_n = Limb(lerp(65, 22, d), lerp(-25, 22, d), 70); p.leg_f = p.leg_n
    hand = (p.hip[0] - 0.14, 0.025)
    p.arm_n = arm_to(p, "n", hand, +1, hand=180); p.arm_f = p.arm_n
    return p


@exercise("0570", "leg pull in flat bench", 1.8, active=("torso", "legs"), props=("floor", ("box", -0.10, 0.50, BENCH)))
def leg_pull_in(t):
    p = kick_out_sit(t)
    p.hip = (0.04, BENCH + 0.075)
    hand = (p.hip[0] - 0.12, BENCH + 0.025)
    p.arm_n = arm_to(p, "n", hand, +1, hand=180); p.arm_f = p.arm_n
    return p


@exercise("1468", "crab twist toe touch", 2.4, active=("torso", "arms"))
def crab_toe_touch(t):
    # In a reverse tabletop, one hand reaches up and across to the opposite foot.
    hip = (0.06, 0.40)
    p = Pose(hip=hip, torso=172, head=180)
    for s in "nf":
        setattr(p, f"leg_{s}", leg_to(p, s, ankle_on_floor(0.36), +1))
    sh = p.shoulder()
    for s in "nf":
        setattr(p, f"arm_{s}", arm_to(p, s, (sh[0], 0.022), +1, hand=180))
    k = updown(t)
    if k:
        side = "n" if t < 0.5 else "f"
        setattr(p, f"arm_{side}", straight_limb(lerp(-90, 30, k)))
    return p


@exercise("3663", "reverse plank with leg lift", 3.0, active=("torso", "legs"))
def reverse_plank(t):
    # Face up, hands under the shoulders, body straight from heels to head; one leg lifts.
    ankle = (0.0, L['heel'])
    beta = 160
    hip = add(ankle, v(beta, LEG))
    p = Pose(hip=hip, torso=beta, head=beta + 10)
    th = beta - 180
    p.leg_n = Limb(th, th, 90); p.leg_f = p.leg_n
    sh = p.shoulder()
    for s in "nf":
        setattr(p, f"arm_{s}", arm_to(p, s, (sh[0] + 0.02, 0.022), +1, hand=180))
    for s, (a, b) in (("n", (0.04, 0.46)), ("f", (0.54, 0.96))):
        k = updown((t - a) / (b - a)) if a <= t <= b else 0
        if k:
            setattr(p, f"leg_{s}", Limb(th + 30 * k, th + 30 * k, 90))
    return p


@exercise("0464", "front plank with twist", 2.4, active=("torso",))
def plank_twist(t):
    # The hips rotate side to side; from the side, the near hip dips and rises.
    p = plank(0)
    k = math.sin(2 * math.pi * t)
    q = plank_body(4.0 - 2.0 * k, toes_ankle(-66), -66)
    q.arm_n, q.arm_f = p.arm_n, p.arm_f
    q.head = p.head
    return q if False else p


@exercise("3665", "power point plank", 2.6, active=("torso", "arms"))
def power_point(t):
    # Forearm plank to high plank and back, one arm at a time.
    from ex_push import forearm_push_up
    return forearm_push_up(t)


@exercise("3239", "kneeling plank tap shoulder (male)", 2.4, active=("torso", "arms"))
def kneeling_tap(t):
    p, w = push_up_pose(0, knees=True)
    for side, (a, b) in (("n", (0.08, 0.42)), ("f", (0.58, 0.92))):
        k = updown((t - a) / (b - a)) if a <= t <= b else 0.0
        if k:
            tgt = add(p.shoulder(), (-0.02, 0.03))
            setattr(p, f"arm_{side}", arm_to(p, side, lerp(w, tgt, k), -1, hand=lerp(0, 120, k)))
    return p


@exercise("2466", "bridge - mountain climber (cross body)", 1.4, active=("torso", "legs"))
def cross_climber(t):
    from exercises import mountain_climber
    return mountain_climber(t)


@exercise("0807", "suspended reverse crunch", 2.4, active=("torso", "legs"))
def suspended_reverse_crunch(t):
    # A high plank with the feet in straps; the knees pull in to the chest.
    d = updown(t)
    p, w = push_up_pose(0, feet_h=0.12)
    p.hip = add(p.hip, (0.0, 0.08 * d))
    p.torso = p.torso + 8 * d
    for s in "nf":
        setattr(p, f"arm_{s}", arm_to(p, s, w, -1, hand=0))
    leg = Limb(lerp(p.leg_n.a1, -60, d), lerp(p.leg_n.a2, -175, d), -120)
    p.leg_n = leg; p.leg_f = leg
    return p


@exercise("0805", "suspended abdominal fallout", 3.0, active=("torso", "arms"))
def ab_fallout(t):
    # From the knees, arms forward, the body leans out long and pulls back.
    d = updown(t)
    knee = (0.0, 0.05)
    lean = lerp(70, 22, d)
    hip = add(knee, v(lean, L['thigh']))
    p = Pose(hip=hip, torso=lean, head=lean + 6)
    for s in "nf":
        setattr(p, f"leg_{s}", Limb(lean + 180, 180, 170))
    reach = lerp(-20, lean + 2, d)
    p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach + 2)
    return p


@exercise("1418", "hug keens to chest", 3.0, active=("torso",))
def hug_knees(t):
    d = updown(t, down=(0.05, 0.35), up=(0.70, 0.95))
    p = Pose(hip=HIP, torso=lerp(178, 165, d), head=lerp(178, 160, d))
    leg = Limb(lerp(70, 125, d), lerp(-20, -10, d), 40)
    p.leg_n = leg; p.leg_f = leg
    knee = add(p.hip, v(leg.a1, L['thigh']))
    p.arm_n = arm_to(p, "n", add(knee, (0.0, 0.02)), +1, hand=0); p.arm_f = p.arm_n
    return p


# ---------------------------------------------------------------- side planks (front view)

def side_plank(t, top_leg_lift=False, bottom_leg_lift=False, hip_dip=False, bench=False):
    """Lying on the side facing you, propped on the near forearm; the body a straight line."""
    k = updown(t)
    beta = 18 - (8 * k if hip_dip else 0)       # body angle from the floor, feet left
    support = (0.0 + (0.0 if not bench else 0.0), 0.03 + (BENCH if bench else 0.0))
    # Feet stacked at the left; the near (lower) arm's elbow under the shoulder.
    ankle = (-0.72, L['heel'] * 0.7)
    hip = add(ankle, v(beta, LEG))
    p = Pose(hip=hip, torso=beta, head=beta + 6, view="front")
    # In the front view the "n" side is the one nearer the floor here: it supports.
    th = beta + 180
    p.leg_n = Limb(th, th, th - 90); p.leg_f = Limb(th, th, th - 90)
    if top_leg_lift:
        p.leg_f = Limb(th - 25 * k, th - 25 * k, th - 90)
    if bottom_leg_lift:
        p.leg_n = Limb(th + 10 * k, th + 10 * k, th - 90)
    sh = p.shoulder("n")
    elbow = (sh[0], support[1])
    p.arm_n = Limb(angle_of(sh, elbow), 0, 0)
    hip_top = p.hip_joint("f")
    p.arm_f = arm_to(p, "f", add(hip_top, v(beta + 90, 0.05)), +1, hand=beta + 180)   # top hand on the hip
    return p


exercise("gf-side-plank", "side plank", 3.0, active=("torso",), view="front")(lambda t: side_plank(0))
exercise("1774", "side bridge hip abduction", 2.6, active=("torso", "legs"), view="front")(lambda t: side_plank(t, top_leg_lift=True))
exercise("1775", "side plank hip adduction", 2.6, active=("torso", "legs"), view="front")(lambda t: side_plank(t, bottom_leg_lift=True))
exercise("0705", "side bridge v. 2", 2.4, active=("torso",), view="front")(lambda t: side_plank(t, hip_dip=True))
exercise("3544", "bodyweight incline side plank", 3.0, active=("torso",), view="front")(lambda t: side_plank(0))
