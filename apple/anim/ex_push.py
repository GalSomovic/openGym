"""Push-ups: one generator for the whole family, by where the hands and the pivot are."""
from __future__ import annotations

import math

from registry import exercise
from rig import L, Limb, Pose, add, arm_to, dist, ease, lerp, v
from exercises import LEG, plank_body, toes_ankle, updown, straight_limb

ARM = L['uarm'] + L['farm']
WRIST_H = 0.022


def body_from(pivot, beta, knees=False):
    """A straight body from the pivot (the ankles, or the knees when kneeling)."""
    if not knees:
        return plank_body(beta, pivot)
    hip = add(pivot, v(beta, L['thigh']))
    p = Pose(hip=hip, torso=beta, head=beta + 6)
    back = beta + 180
    # Shins flat on the floor behind the knees, feet relaxed.
    for side in "nf":
        setattr(p, f"leg_{side}", Limb(back, 180, 170))
    return p


def solve_shoulder_height(pivot, target_y, knees=False, lo=-30.0, hi=85.0):
    for _ in range(60):
        mid = (lo + hi) / 2
        if body_from(pivot, mid, knees).shoulder()[1] < target_y:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def push_up_pose(d, hands_h=0.0, feet_h=0.0, dx=0.02, knees=False, depth=0.11, toe=-66, bend=-1, lift=0.0):
    """
    d: 0 at the top (arms straight), 1 at the bottom. hands_h / feet_h: a box under the hands
    (incline) or the feet (decline). dx: wrist ahead of the shoulder at the top (negative:
    under the chest). lift: extra body angle above the top (a plyometric push leaving the floor).
    """
    if knees:
        pivot = (0.0, 0.05)
    else:
        a = toes_ankle(toe)
        pivot = (a[0], a[1] + feet_h)
    wrist_y = hands_h + WRIST_H
    top_y = wrist_y + math.sqrt(max(ARM ** 2 - dx ** 2, 0)) - 0.004
    beta_top = solve_shoulder_height(pivot, top_y, knees)
    top = body_from(pivot, beta_top, knees)
    wrist = (top.shoulder()[0] + dx, wrist_y)
    beta_bot = solve_shoulder_height(pivot, wrist_y + depth, knees)
    beta = beta_top + (beta_bot - beta_top) * d + lift
    p = body_from(pivot, beta, knees)
    if not knees and toe != -66:
        for side in "nf":
            limb = getattr(p, f"leg_{side}")
            setattr(p, f"leg_{side}", Limb(limb.a1, limb.a2, beta - 72))
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, bend, hand=0))
    p.head = p.torso + 4 + 10 * d
    return p, wrist


def box(x, w, h):
    return ("box", x, w, h)


def variant(id, name, period=2.4, active=("arms", "torso"), props=("floor",), **kw):
    def fn(t):
        return push_up_pose(updown(t), **kw)[0]
    exercise(id, name, period, active=active, props=props)(fn)


variant("0662", "push-up")
variant("1311", "wide hand push up", dx=0.05, active=("torso", "arms"))
variant("0259", "close-grip push-up", dx=0.0, active=("arms",))
variant("0283", "diamond push-up", dx=-0.05, depth=0.13, active=("arms",))
variant("3211", "kneeling push-up", knees=True)
variant("2398", "close-grip push-up (on knees)", knees=True, dx=0.0, active=("arms",))

# Incline: hands on a box. Its far edge sits under the hands.
BENCH = 0.26
for id, name, h, dx in (("0493", "incline push-up", BENCH, 0.02), ("3785", "incline push-up (on box)", 0.22, 0.02),
                        ("0490", "incline close-grip push-up", BENCH, 0.0), ("0494", "incline reverse grip push-up", BENCH, -0.01)):
    _, w = push_up_pose(0, hands_h=h, dx=dx)
    # The hands grip the near edge; the box extends away from the body.
    variant(id, name, hands_h=h, dx=dx, depth=0.10, props=("floor", box(w[0] + 0.15, 0.34, h)))

# Decline: feet on a box.
# Decline: feet on a bench; the chest stops higher so the head stays clear of the floor.
variant("0279", "decline push-up", feet_h=BENCH, depth=0.16, props=("floor", box(-0.02, 0.30, BENCH)), active=("torso", "arms"))


@exercise("3145", "push-up plus", 2.8, active=("arms", "torso"))
def push_up_plus(t):
    # A push-up, then at the top the shoulder blades spread and the upper back rounds up.
    d = updown(t, down=(0.05, 0.35), up=(0.40, 0.65))
    plus = updown(t, down=(0.68, 0.80), up=(0.86, 0.97))
    p, w = push_up_pose(d)
    if plus:
        p, w = push_up_pose(0, lift=1.2 * plus)
    return p


@exercise("3021", "scapula push-up", 2.2, active=("torso",))
def scapula_push_up(t):
    # Arms stay straight; only the shoulder blades move, the chest sinking and rising a little.
    d = updown(t)
    p, w = push_up_pose(0, lift=-2.2 * d)
    return p


_, _wi = push_up_pose(0, hands_h=BENCH)


@exercise("3011", "incline scapula push up", 2.2, active=("torso",), props=("floor", box(_wi[0] + 0.15, 0.34, BENCH)))
def incline_scapula(t):
    p, w = push_up_pose(0, hands_h=BENCH, lift=-2.0 * updown(t))
    return p


def _plyo(t, clap=False):
    # Down, explode up so the hands leave the floor, land and absorb.
    if t < 0.40:
        p, w = push_up_pose(ease(t / 0.40))
        return p
    if t < 0.62:
        u = (t - 0.40) / 0.22
        p, w = push_up_pose(1 - ease(u))
        return p
    if t < 0.82:
        u = (t - 0.62) / 0.20
        air = math.sin(math.pi * u)
        p, w = push_up_pose(0, lift=7 * air)
        hands_up = 0.10 * air
        for side in "nf":
            target = (w[0] - (0.06 if clap else 0.0) * air, w[1] + hands_up)
            setattr(p, f"arm_{side}", arm_to(p, side, target, -1, hand=0))
        return p
    u = (t - 0.82) / 0.18
    p, w = push_up_pose(0.25 * math.sin(math.pi * u))
    return p


exercise("1306", "plyo push up", 2.0, active=("arms", "torso"))(lambda t: _plyo(t))
exercise("1273", "clap push up", 2.0, active=("arms", "torso"))(lambda t: _plyo(t, clap=True))


def _tap(t, target_of, hold=(0.35, 0.65)):
    """A plank or push-up top where one hand leaves the floor to tap `target_of(p)`, then the other."""
    p, w = push_up_pose(0)
    for side, (a, b) in (("n", (0.08, 0.42)), ("f", (0.58, 0.92))):
        k = updown((t - a) / (b - a)) if a <= t <= b else 0.0
        if k:
            tgt = target_of(p, side)
            dest = lerp(w, tgt, k)
            setattr(p, f"arm_{side}", arm_to(p, side, dest, -1, hand=lerp(0, 120, k)))
    return p


exercise("3699", "shoulder tap", 2.4, active=("torso", "arms"))(
    lambda t: _tap(t, lambda p, s: add(p.shoulder(), (-0.02, 0.03))))


@exercise("0699", "shoulder tap push-up", 3.4, active=("arms", "torso"))
def shoulder_tap_push_up(t):
    if t < 0.5:
        p, w = push_up_pose(updown(t / 0.5))
        return p
    return _tap((t - 0.5) / 0.5, lambda p, s: add(p.shoulder(), (-0.02, 0.03)))


@exercise("3216", "chest tap push-up (male)", 3.4, active=("arms", "torso"))
def chest_tap_push_up(t):
    if t < 0.5:
        p, w = push_up_pose(updown(t / 0.5))
        return p
    return _tap((t - 0.5) / 0.5, lambda p, s: add(p.shoulder(), (-0.07, -0.02)))


@exercise("0725", "single arm push-up", 2.8, active=("arms", "torso"))
def single_arm(t):
    p, w = push_up_pose(updown(t), depth=0.16, toe=-60)
    # The free hand rests on the lower back.
    back = add(p.hip, v(p.torso, 0.06))
    p.arm_f = arm_to(p, "f", add(back, (0, 0.05)), +1, hand=p.torso + 180)
    return p


@exercise("0666", "raise single arm push-up", 3.2, active=("arms", "torso"))
def raise_single_arm(t):
    if t < 0.55:
        p, w = push_up_pose(updown(t / 0.55))
        return p
    p, w = push_up_pose(0)
    for side, (a, b) in (("n", (0.55, 0.77)), ("f", (0.77, 0.99))):
        if a <= t <= b:
            k = updown((t - a) / (b - a), down=(0.0, 0.45), up=(0.55, 1.0))
            reach = lerp(-90, 2, k)
            setattr(p, f"arm_{side}", Limb(reach, reach, reach))
    return p


@exercise("0778", "spider crawl push up", 3.0, active=("arms", "torso", "legs"))
def spider(t):
    # As you lower, one knee comes up toward the elbow; alternate sides each rep.
    first = t < 0.5
    u = (t % 0.5) / 0.5
    d = updown(u)
    p, w = push_up_pose(d)
    side = "n" if first else "f"
    leg = getattr(p, f"leg_{side}")
    k = d
    setattr(p, f"leg_{side}", Limb(leg.a1 + 80 * k, leg.a2 - 30 * k, leg.a3))
    return p


@exercise("0803", "superman push-up", 2.4, active=("arms", "torso", "legs"))
def superman(t):
    # Down, then explode so the whole body leaves the floor, arms reaching forward.
    if t < 0.38:
        return push_up_pose(ease(t / 0.38))[0]
    if t < 0.55:
        return push_up_pose(1 - ease((t - 0.38) / 0.17))[0]
    if t < 0.82:
        u = (t - 0.55) / 0.27
        air = math.sin(math.pi * u)
        p, w = push_up_pose(0)
        p = Pose(hip=add(p.hip, (0.03 * air, 0.12 * air)), torso=lerp(p.torso, 4, air), head=lerp(p.head, 10, air),
                 arm_n=p.arm_n, arm_f=p.arm_f, leg_n=p.leg_n, leg_f=p.leg_f)
        reach = lerp(-90, 5, air)
        p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach + 3)
        back = lerp(p.leg_n.a1, 182, air)
        p.leg_n = Limb(back, back, back - 10); p.leg_f = Limb(back + 2, back + 2, back - 8)
        return p
    return push_up_pose(0.2 * math.sin(math.pi * (t - 0.82) / 0.18))[0]


@exercise("1467", "push-up on lower arms", 2.6, active=("arms",))
def forearm_push_up(t):
    # From a forearm plank, press up one arm at a time to a high plank, and back down.
    from exercises import plank as forearm_plank
    low = forearm_plank(0)
    high, w = push_up_pose(0)
    d = updown(t)
    p = Pose(hip=lerp(low.hip, high.hip, d), torso=lerp(low.torso, high.torso, d), head=lerp(low.head, high.head, d),
             leg_n=low.leg_n, leg_f=low.leg_f)
    elbow_low = (low.shoulder()[0] + 0.005, 0.03)
    for side, lag in (("n", 0.0), ("f", 0.15)):
        k = max(0.0, min(1.0, (d - lag) / (1 - lag)))
        wrist = lerp((elbow_low[0] + ARM - L['uarm'], WRIST_H), w, k)
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, -1, hand=0))
    return p


@exercise("0659", "push-up (wall)", 2.6, active=("arms", "torso"), props=("floor", ("wall", 0.60)))
def wall_push_up(t):
    # Standing at arm's length, leaning into the wall and pressing away.
    wall = 0.60
    d = updown(t)
    ankle = (0.0, L['heel'])
    for beta in [x / 4 for x in range(360, 200, -1)]:
        p = plank_body(beta, ankle, toe_angle=0)
        reach = wall - p.shoulder()[0]
        if reach <= ARM * lerp(0.97, 0.42, d):
            break
    wrist = (wall - 0.01, p.shoulder()[1] - 0.02)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, -1, hand=90))
    for side in "nf":
        limb = getattr(p, f"leg_{side}")
        setattr(p, f"leg_{side}", Limb(limb.a1, limb.a2, 0))
    p.head = p.torso
    return p


exercise("0658", "push-up (wall) v. 2", 2.6, active=("arms", "torso"), props=("floor", ("wall", 0.60)))(wall_push_up)
