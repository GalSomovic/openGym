"""
The exercises GymFree animates itself. Each is a function of the loop phase t in [0, 1)
returning a Pose; constraints (planted hands and feet, straight bodies, bars) are solved per
sample, so what moves is what moves in the real exercise.

`id` is openGym's catalogue id, or a new `gf-` id for an exercise the catalogue lacks
(registered in extras.json).
"""
from __future__ import annotations

import math

from rig import L, SHOULDER_AT, Limb, Pose, add, angle_of, ankle_on_floor, arm_to, dist, ease, leg_to, lerp, standing, v

from registry import EXERCISES, exercise  # noqa: F401


def updown(t, down=(0.06, 0.47), up=(0.55, 0.96)):
    """0 at the start position, 1 at the far end: eased out and back with short pauses."""
    if t < down[0]:
        return 0.0
    if t < down[1]:
        return ease((t - down[0]) / (down[1] - down[0]))
    if t < up[0]:
        return 1.0
    if t < up[1]:
        return 1 - ease((t - up[0]) / (up[1] - up[0]))
    return 0.0


LEG = L['thigh'] + L['shin']


def straight_limb(a):
    return Limb(a, a, a)


# ---------------------------------------------------------------- push-ups and planks

def plank_body(beta: float, ankle=(0.0, 0.0), toe_angle=None) -> Pose:
    """A straight body from the ankles at angle beta (deg above the floor), facing right."""
    hip = add(ankle, v(beta, LEG))
    p = Pose(hip=hip, torso=beta, head=beta + 6)
    back = beta + 180
    toe = toe_angle if toe_angle is not None else beta - 72
    p.leg_n = Limb(back, back, toe)
    p.leg_f = Limb(back, back, toe)
    return p


def toes_ankle(toe_angle: float) -> tuple[float, float]:
    """Where the ankle sits with the toes on the floor and the foot at toe_angle."""
    return (0.0, -math.sin(math.radians(toe_angle)) * L['foot'] * 0.8 + 0.01)


def solve_beta(ankle, target_shoulder_dist, wrist, lo=2, hi=60):
    """The body angle at which the shoulder is `target_shoulder_dist` from the wrist."""
    for _ in range(60):
        mid = (lo + hi) / 2
        p = plank_body(mid, ankle)
        if dist(p.shoulder(), wrist) < target_shoulder_dist:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


@exercise("0662", "push-up", 2.4, active=("arms", "torso"))
def push_up(t):
    toe = -66
    ankle = toes_ankle(toe)
    arm = L['uarm'] + L['farm']
    # Hands under the shoulders at the top, flat on the floor.
    top = plank_body(solve_beta(ankle, 10, (9, 9), lo=10, hi=40), ankle)
    beta_top = 0
    wrist = None
    for b in [x / 4 for x in range(20, 160)]:
        p = plank_body(b, ankle, toe)
        w = (p.shoulder()[0] + 0.02, 0.022)
        if dist(p.shoulder(), w) >= arm - 0.006:
            beta_top, wrist = b, w
            break
    # Bottom: chest a fist above the floor.
    beta_bot = beta_top
    while plank_body(beta_bot, ankle, toe).shoulder()[1] > 0.115 and beta_bot > 1:
        beta_bot -= 0.25
    d = updown(t)
    p = plank_body(beta_top + (beta_bot - beta_top) * d, ankle, toe)
    for side in "nf":
        # Elbows travel back toward the feet, about 45 degrees from the body.
        limb = arm_to(p, side, wrist, -1, hand=0)
        setattr(p, f"arm_{side}", limb)
    p.head = p.torso + 4
    return p


@exercise("gf-plank", "plank", 3.2, active=("torso",))
def plank(t):
    """Forearm plank: a held position, breathing."""
    toe = -66
    ankle = toes_ankle(toe)
    breathe = 0.6 * math.sin(2 * math.pi * t)
    # Elbows under the shoulders, forearms flat.
    beta = 2
    while True:
        p = plank_body(beta, ankle, toe)
        if p.shoulder()[1] >= L['uarm'] + 0.03:
            break
        beta += 0.1
    p = plank_body(beta + breathe * 0.15, ankle, toe)
    elbow = (p.shoulder()[0] + 0.005, 0.03)
    for side in "nf":
        a1 = angle_of(p.shoulder(), elbow)
        setattr(p, f"arm_{side}", Limb(a1, 0, 0))
    p.head = p.torso + 2
    return p


@exercise("0630", "mountain climber", 1.1, active=("legs", "torso"))
def mountain_climber(t):
    toe = -60
    ankle = toes_ankle(toe)
    arm = L['uarm'] + L['farm']
    beta = 0
    wrist = None
    for b in [x / 4 for x in range(40, 200)]:
        p = plank_body(b, ankle, toe)
        w = (p.shoulder()[0] + 0.01, 0.022)
        if dist(p.shoulder(), w) >= arm - 0.004:
            beta, wrist = b, w
            break
    p = plank_body(beta + 3, ankle, toe)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, -1, hand=0))
    # Each leg swings between the plank (back, on the toes) and the tuck (knee under the
    # chest, foot off the floor), by joint angles so the knee never drops to the floor.
    back_leg = p.leg_n
    tuck_leg = Limb(-50, -176, -130)
    from rig import lerp_angle
    def phase(x):
        # Held in, quick switch, held out, quick switch: the legs pass each other fast.
        x %= 1
        if x < 0.32: return 1.0
        if x < 0.5: return 1 - ease((x - 0.32) / 0.18)
        if x < 0.82: return 0.0
        return ease((x - 0.82) / 0.18)
    for side, off in (("n", 0.0), ("f", 0.5)):
        k = phase(t + off)
        lift = math.sin(math.pi * k) * 22   # the foot clears the floor on the way
        leg = Limb(lerp_angle(back_leg.a1, tuck_leg.a1, k), lerp_angle(back_leg.a2, tuck_leg.a2, k) - lift,
                   lerp_angle(back_leg.a3, tuck_leg.a3, k) - lift)
        setattr(p, f"leg_{side}", leg)
    return p


# ---------------------------------------------------------------- squats and lunges

@exercise("gf-squat", "bodyweight squat", 2.6, active=("legs",))
def squat(t):
    d = updown(t)
    stand_h = L['heel'] + LEG - 0.004
    hip = (lerp(0.0, -0.13, d), lerp(stand_h, 0.31, d))
    p = Pose(hip=hip, torso=lerp(90, 52, d), head=lerp(90, 70, d))
    for side, dx in (("n", 0.015), ("f", -0.015)):
        setattr(p, f"leg_{side}", leg_to(p, side, ankle_on_floor(dx), +1))
    reach = lerp(-90, 2, d)
    p.arm_n = straight_limb(reach)
    p.arm_f = straight_limb(reach)
    return p


@exercise("3470", "forward lunge", 3.2, active=("legs",))
def forward_lunge(t):
    stand_h = L['heel'] + LEG - 0.004
    step = 0.40
    # Phases: step out, lower, rise, step back.
    if t < 0.22:
        k, depth = ease(t / 0.22), 0.0
    elif t < 0.47:
        k, depth = 1.0, ease((t - 0.22) / 0.25)
    elif t < 0.62:
        k, depth = 1.0, 1.0
    elif t < 0.80:
        k, depth = 1.0, 1 - ease((t - 0.62) / 0.18)
    else:
        k, depth = 1 - ease((t - 0.80) / 0.20), 0.0
    front_x = step * k
    lift = 0.07 * math.sin(math.pi * k) if (t < 0.22 or t >= 0.80) else 0.0
    hip_x = front_x * 0.48
    hip_y = stand_h - 0.035 * math.sin(math.pi * k) - depth * 0.20
    p = Pose(hip=(hip_x, hip_y), torso=lerp(90, 92, depth), head=90)
    # Back foot: the heel rises as the lunge deepens; the toes stay put.
    toe_back = (0.075, 0.0)
    fa = lerp(0, -38, max(depth, 0.6 * k))
    back_ankle = (toe_back[0] - L['foot'] * 0.8 * math.cos(math.radians(fa)),
                  L['heel'] - L['foot'] * 0.8 * math.sin(math.radians(fa)) * 0.9)
    p.leg_f = leg_to(p, "f", back_ankle, +1, foot=fa)
    p.leg_n = leg_to(p, "n", (front_x, L['heel'] + lift), +1, foot=0)
    swing = lerp(-90, -80, depth)
    p.arm_n = Limb(swing - 8, swing + 10, swing + 10)
    p.arm_f = Limb(swing + 8, swing - 5, swing - 5)
    return p


# ---------------------------------------------------------------- bars

BAR_Y = 1.42


@exercise("0652", "pull-up", 2.8, active=("arms", "torso"), props=("floor", ("bar", (0.03, BAR_Y))))
def pull_up(t):
    d = updown(t, down=(0.08, 0.45), up=(0.55, 0.95))
    grip = (0.03, BAR_Y - 0.01)
    arm = L['uarm'] + L['farm'] + L['hand'] * 0.6
    sh = (lerp(-0.005, -0.04, d), lerp(BAR_Y - arm + 0.01, BAR_Y - 0.12, d))
    torso = lerp(92, 102, d)
    hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=torso, head=lerp(92, 96, d))
    wrist = add(grip, v(-90, L['hand'] * 0.6))
    for side in "nf":
        limb = arm_to(p, side, wrist, -1, hand=90)
        setattr(p, f"arm_{side}", limb)
    # Legs together, slightly in front, toes pointed.
    p.leg_n = Limb(-82, -96, -60)
    p.leg_f = Limb(-84, -98, -62)
    return p


@exercise("1326", "chin-up", 2.8, active=("arms",), props=("floor", ("bar", (0.03, BAR_Y))))
def chin_up(t):
    p = pull_up(t)
    # Palms toward you: the elbows stay closer in front.
    d = updown(t, down=(0.08, 0.45), up=(0.55, 0.95))
    grip = (0.03, BAR_Y - 0.01)
    wrist = add(grip, v(-90, L['hand'] * 0.6))
    p.torso = lerp(92, 98, d)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, -1, hand=90))
    return p


DIP_H = 0.98


@exercise("0251", "chest dip", 2.6, active=("arms", "torso"), props=("floor", ("parallettes", 0.0, DIP_H)))
def chest_dip(t):
    d = updown(t)
    hand = (0.0, DIP_H + 0.02)
    arm = L['uarm'] + L['farm']
    torso = lerp(96, 66, d)          # leaning forward at the bottom
    sh = (lerp(-0.01, -0.06, d), lerp(DIP_H + arm - 0.01, DIP_H + 0.10, d))
    hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=torso, head=lerp(96, 60, d))
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, hand, -1, hand=0))
    # Knees bent, ankles crossed behind.
    lean = torso - 90
    p.leg_n = Limb(-96 + lean * 0.5, -128 + lean * 0.4, -120)
    p.leg_f = Limb(-92 + lean * 0.5, -122 + lean * 0.4, -115)
    return p


# ---------------------------------------------------------------- on the floor

def supine_hip(neck, hip_h):
    """The hip of a body lying on its back with its neck at `neck` and the hip at height hip_h."""
    dy = hip_h - neck[1]
    dx = math.sqrt(max(L['torso'] ** 2 - dy ** 2, 0))
    return (neck[0] + dx, hip_h)


@exercise("3013", "glute bridge", 2.6, active=("legs",))
def glute_bridge(t):
    d = updown(t, down=(0.05, 0.40), up=(0.62, 0.96))
    neck = (-0.28, 0.055)
    hip = supine_hip(neck, lerp(0.075, 0.26, d))
    torso = angle_of(hip, neck)
    p = Pose(hip=hip, torso=torso, head=178)
    feet = 0.20
    for side, dx in (("n", 0.0), ("f", -0.01)):
        setattr(p, f"leg_{side}", leg_to(p, side, ankle_on_floor(feet + dx), +1))
    # Arms long on the floor beside the body, palms down.
    sh = p.shoulder()
    reach = L['uarm'] + L['farm'] - 0.005
    wrist = (sh[0] + math.sqrt(max(reach ** 2 - (sh[1] - 0.025) ** 2, 0)), 0.025)
    for side in "nf":
        a = math.degrees(math.atan2(wrist[1] - sh[1], wrist[0] - sh[0]))
        setattr(p, f"arm_{side}", Limb(a, a, 0))
    return p


@exercise("0274", "crunch", 2.2, active=("torso",))
def crunch(t):
    d = updown(t, down=(0.06, 0.42), up=(0.58, 0.95))
    hip = (0.0, 0.075)
    torso = lerp(178, 146, d)
    p = Pose(hip=hip, torso=torso, head=torso - lerp(0, 26, d))
    for side, dx in (("n", 0.0), ("f", -0.01)):
        setattr(p, f"leg_{side}", leg_to(p, side, ankle_on_floor(0.30 + dx), +1))
    # Fingertips at the temples, elbows out toward the knees.
    head = p.head_center()
    target = add(head, v(p.head - 90, 0.03))
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, target, +1, hand=p.head + 90))
    return p


# The family modules register themselves on import.
import ex_push  # noqa: E402,F401
import ex_legs  # noqa: E402,F401
import ex_bars  # noqa: E402,F401
