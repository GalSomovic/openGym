"""Squats, lunges, calf raises, jumps: legs with planted feet solved by IK."""
from __future__ import annotations

import math

from registry import exercise
from rig import L, Limb, Pose, add, ankle_on_floor, arm_to, ease, keyed, leg_to, lerp, lerp_angle, pose, v
from exercises import LEG, updown, straight_limb

STAND_H = L['heel'] + LEG - 0.004
BENCH = 0.26


def squat_pose(d, bottom_h=0.31, back=0.13, lean=38, arms="forward", feet=(0.015, -0.015), heels=0.0, head_drop=20):
    """d 0 standing, 1 at the bottom. heels: how far the heels lift (0..1)."""
    hip = (lerp(0.0, -back, d), lerp(STAND_H, bottom_h, d))
    p = Pose(hip=hip, torso=90 - lean * d, head=90 - head_drop * d)
    fa = -30 * heels
    for side, dx in zip("nf", feet):
        ank = (dx - 0.06 * heels, L['heel'] + 0.05 * heels)
        setattr(p, f"leg_{side}", leg_to(p, side, ank, +1, foot=fa))
    if arms == "forward":
        reach = lerp(-90, 2, d)
        p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach)
    elif arms == "prisoner":       # hands behind the head
        tgt = add(p.head_center(), v(p.head + 160, 0.07))
        p.arm_n = arm_to(p, "n", tgt, +1, hand=p.head + 90); p.arm_f = p.arm_n
    elif arms == "chest":          # hands together at the chest
        tgt = add(p.shoulder(), v(p.torso - 70, 0.16))
        p.arm_n = arm_to(p, "n", tgt, -1, hand=p.torso); p.arm_f = p.arm_n
    return p


def jump(p: Pose, air: float, height=0.16) -> Pose:
    """The pose lifted into the air with straightened legs and pointed toes."""
    q = Pose(hip=add(p.hip, (0, height * air)), torso=lerp_angle(p.torso, 90, air), head=lerp_angle(p.head, 90, air),
             arm_n=p.arm_n, arm_f=p.arm_f,
             leg_n=Limb(lerp_angle(p.leg_n.a1, -88, air), lerp_angle(p.leg_n.a2, -92, air), lerp_angle(p.leg_n.a3, -60, air)),
             leg_f=Limb(lerp_angle(p.leg_f.a1, -92, air), lerp_angle(p.leg_f.a2, -95, air), lerp_angle(p.leg_f.a3, -62, air)))
    return q


@exercise("0514", "jump squat", 1.8, active=("legs",))
def jump_squat(t):
    # Squat, explode upward, land soft back into the squat.
    if t < 0.40:
        return squat_pose(ease(t / 0.40), arms="chest")
    if t < 0.55:
        return squat_pose(1 - ease((t - 0.40) / 0.15), arms="chest")
    if t < 0.82:
        air = math.sin(math.pi * (t - 0.55) / 0.27)
        q = jump(squat_pose(0, arms="chest"), air)
        reach = lerp(-60, -100, air)
        q.arm_n = straight_limb(reach); q.arm_f = straight_limb(reach)
        return q
    return squat_pose(0.4 * math.sin(math.pi * (t - 0.82) / 0.18), arms="chest")


exercise("0513", "jump squat v. 2", 1.8, active=("legs",))(jump_squat)


@exercise("3222", "semi squat jump (male)", 1.6, active=("legs",))
def semi_squat_jump(t):
    if t < 0.40:
        return squat_pose(0.55 * ease(t / 0.40))
    if t < 0.55:
        return squat_pose(0.55 * (1 - ease((t - 0.40) / 0.15)))
    if t < 0.82:
        return jump(squat_pose(0), math.sin(math.pi * (t - 0.55) / 0.27), 0.11)
    return squat_pose(0.3 * math.sin(math.pi * (t - 0.82) / 0.18))


@exercise("3543", "bodyweight drop jump squat", 2.0, active=("legs",))
def drop_jump_squat(t):
    # A small hop up, then drop fast into a squat and hold it.
    if t < 0.25:
        return jump(squat_pose(0), math.sin(math.pi * t / 0.25), 0.07)
    if t < 0.40:
        return squat_pose(ease((t - 0.25) / 0.15), arms="chest")
    if t < 0.75:
        return squat_pose(1, arms="chest")
    return squat_pose(1 - ease((t - 0.75) / 0.25), arms="chest")


@exercise("3221", "half knee bends (male)", 1.8, active=("legs",))
def half_knee_bends(t):
    return squat_pose(updown(t) * 0.5, arms="forward")


@exercise("1685", "squat to overhead reach", 3.0, active=("legs", "torso"))
def squat_overhead(t):
    d = updown(t, down=(0.05, 0.40), up=(0.48, 0.80))
    p = squat_pose(d, arms="forward")
    reach = updown(t, down=(0.70, 0.82), up=(0.90, 0.99))
    if reach:
        a = lerp(-90, 92, reach)
        p.arm_n = straight_limb(a); p.arm_f = straight_limb(a)
        p.head = lerp(90, 100, reach)
    return p


exercise("1686", "squat to overhead reach with twist", 3.0, active=("legs", "torso"))(squat_overhead)


@exercise("3119", "potty squat", 3.2, active=("legs",))
def potty_squat(t):
    # A deep, relaxed squat: heels down, chest up, elbows inside the knees.
    d = updown(t, down=(0.05, 0.40), up=(0.70, 0.98))
    p = squat_pose(d, bottom_h=0.20, back=0.10, lean=30, arms="chest")
    return p


exercise("3132", "potty squat with support", 3.2, active=("legs",))(potty_squat)


@exercise("1489", "sissy squat", 2.8, active=("legs",))
def sissy_squat(t):
    # Up on the toes, knees travel forward, the body leans back in one line from knee to head.
    d = updown(t)
    ank = (0.0, L['heel'] + 0.06)
    knee = (lerp(0.02, 0.24, d), lerp(L['heel'] + 0.06 + L['shin'], 0.22, d))
    shin = math.degrees(math.atan2(knee[1] - ank[1], knee[0] - ank[0]))
    lean = lerp(90, 128, d)
    hip = add(knee, v(lean + 180 - 180 + 0, 0) if False else v(lean, L['thigh']))
    p = Pose(hip=hip, torso=lean, head=lean - 15 * d)
    thigh = math.degrees(math.atan2(knee[1] - hip[1], knee[0] - hip[0]))
    for side in "nf":
        setattr(p, f"leg_{side}", Limb(thigh, shin + 180, -35))
    reach = lerp(-90, -10, d)
    p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach)
    return p


@exercise("1759", "single leg squat (pistol) male", 3.0, active=("legs",))
def pistol(t):
    d = updown(t)
    hip = (lerp(0.0, -0.17, d), lerp(STAND_H, 0.17, d))
    p = Pose(hip=hip, torso=lerp(90, 50, d), head=lerp(90, 62, d))
    p.leg_n = leg_to(p, "n", ankle_on_floor(0.0), +1)
    # The free leg straight out in front, held off the floor.
    fl = lerp(-70, 2, d)
    p.leg_f = Limb(fl, fl, fl + 60)
    reach = lerp(-60, 5, d)
    p.arm_n = straight_limb(reach); p.arm_f = straight_limb(reach)
    return p


exercise("1476", "one leg squat", 3.0, active=("legs",))(pistol)


def split_pose(d, front=0.32, back=-0.30, back_h=0.0, torso=90):
    """A split stance: d 0 up, 1 down (back knee near the floor). back_h: back foot on a bench."""
    hip = ((front + back) / 2 - 0.03, lerp(STAND_H - 0.06, 0.40 + back_h * 0.35, d))
    p = Pose(hip=hip, torso=torso, head=90)
    p.leg_n = leg_to(p, "n", ankle_on_floor(front), +1)
    if back_h:
        p.leg_f = leg_to(p, "f", (back, back_h + 0.05), +1, foot=-20)
    else:
        fa = -40
        toe = (back + 0.07, 0.0)
        ank = (toe[0] - L['foot'] * 0.8 * math.cos(math.radians(fa)), L['heel'] - L['foot'] * 0.75 * math.sin(math.radians(fa)))
        p.leg_f = leg_to(p, "f", ank, +1, foot=fa)
    p.arm_n = Limb(-95, -95, -95); p.arm_f = Limb(-85, -85, -85)
    return p


exercise("2368", "split squats", 2.6, active=("legs",))(lambda t: split_pose(updown(t)))
exercise("gf-bulgarian-split-squat", "bulgarian split squat", 2.8, active=("legs",),
         props=("floor", ("box", -0.42, 0.30, BENCH)))(lambda t: split_pose(updown(t), front=0.26, back=-0.40, back_h=BENCH, torso=84))
exercise("0809", "suspended split squat", 2.8, active=("legs",))(lambda t: split_pose(updown(t), front=0.26, back=-0.42, back_h=0.32, torso=86))


def lunge_cycle(t, direction=1, jump_switch=False, twist=False, overhead=False):
    """Step out (direction +1 forward, -1 back), lower, rise, step home."""
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
    step = 0.40 * k
    lift = 0.07 * math.sin(math.pi * k) if (t < 0.22 or t >= 0.80) else 0.0
    if direction > 0:
        front_x, back_x = step, 0.0
    else:
        front_x, back_x = 0.0, -step
    hip_x = (front_x + back_x) / 2 + 0.02 * k
    hip_y = STAND_H - 0.035 * math.sin(math.pi * k) - depth * 0.20
    p = Pose(hip=(hip_x, hip_y), torso=lerp(90, 92, depth), head=90)
    fa = lerp(0, -38, max(depth, 0.6 * k))
    toe_back = (back_x + 0.075, 0.0)
    back_ankle = (toe_back[0] - L['foot'] * 0.8 * math.cos(math.radians(fa)),
                  L['heel'] - L['foot'] * 0.8 * math.sin(math.radians(fa)) * 0.9 + (lift if direction < 0 else 0))
    p.leg_f = leg_to(p, "f", back_ankle, +1, foot=fa)
    p.leg_n = leg_to(p, "n", (front_x, L['heel'] + (lift if direction > 0 else 0)), +1, foot=0)
    if overhead:
        a = lerp(-90, 95, depth); p.arm_n = straight_limb(a); p.arm_f = straight_limb(a)
    elif twist:
        a = lerp(-60, 0, depth); p.arm_n = Limb(a, a + 60 * depth, a + 60 * depth); p.arm_f = Limb(a - 10, a + 40 * depth, a + 40 * depth)
    else:
        swing = lerp(-90, -80, depth)
        p.arm_n = Limb(swing - 8, swing + 10, swing + 10); p.arm_f = Limb(swing + 8, swing - 5, swing - 5)
    return p


exercise("1460", "walking lunge", 3.0, active=("legs",))(lambda t: lunge_cycle(t))
exercise("1688", "lunge with twist", 3.2, active=("legs", "torso"))(lambda t: lunge_cycle(t, twist=True))
exercise("1687", "posterior step to overhead reach", 3.2, active=("legs", "torso"))(lambda t: lunge_cycle(t, direction=-1, overhead=True))
exercise("gf-reverse-lunge", "reverse lunge", 3.2, active=("legs",))(lambda t: lunge_cycle(t, direction=-1))


@exercise("3582", "lunge with jump", 1.8, active=("legs",))
def lunge_jump(t):
    # Down in a lunge, jump and switch legs in the air, land in the other lunge.
    def stance(d, flip):
        p = split_pose(d, front=0.30, back=-0.28)
        if flip:
            p.leg_n, p.leg_f = p.leg_f, p.leg_n
        return p
    half = t < 0.5
    u = (t % 0.5) / 0.5
    if u < 0.45:
        return stance(1 - 0.25 * math.sin(math.pi * u / 0.45), not half)
    if u < 0.75:
        air = math.sin(math.pi * (u - 0.45) / 0.30)
        a = stance(0.3, not half)
        b = stance(0.3, half)
        mid = Pose(hip=add(a.hip, (0, 0.14 * air)), torso=90, head=90, arm_n=a.arm_n, arm_f=a.arm_f,
                   leg_n=Limb(lerp_angle(a.leg_n.a1, b.leg_n.a1, (u - 0.45) / 0.30), lerp_angle(a.leg_n.a2, b.leg_n.a2, (u - 0.45) / 0.30), -40),
                   leg_f=Limb(lerp_angle(a.leg_f.a1, b.leg_f.a1, (u - 0.45) / 0.30), lerp_angle(a.leg_f.a2, b.leg_f.a2, (u - 0.45) / 0.30), -40))
        return mid
    return stance(1 - 0.75 * (1 - (u - 0.75) / 0.25), half)


@exercise("3655", "walking high knees lunge", 3.4, active=("legs",))
def high_knee_lunge(t):
    # Drive the knee high, then step it forward into a lunge.
    if t < 0.25:
        k = updown(t / 0.25, down=(0, 0.5), up=(0.5, 1.0)) if False else math.sin(math.pi * t / 0.25)
        p = squat_pose(0, arms="forward")
        p.arm_n = Limb(-80, -10, -10); p.arm_f = Limb(-100, -150, -150)
        p.leg_n = Limb(lerp(-90, 0, k), lerp(-90, -90, k), lerp(0, -20, k))
        p.hip = (0.0, STAND_H)
        return p
    return lunge_cycle((t - 0.25) / 0.75)


# ---------------------------------------------------------------- calves

def calf_pose(r, step=False, one_leg=False):
    """Standing on the balls of the feet; r 0 heels down, 1 high on the toes."""
    toe = (0.075, 0.0 if not step else 0.14)
    fa = lerp(8 if step else 0, -42, r)
    ank = (toe[0] - L['foot'] * 0.8 * math.cos(math.radians(fa)), toe[1] + L['heel'] - L['foot'] * 0.8 * math.sin(math.radians(fa)))
    hip = (ank[0], ank[1] + LEG - 0.003)
    p = Pose(hip=hip, torso=90, head=90)
    p.leg_n = leg_to(p, "n", ank, +1, foot=fa)
    if one_leg:
        p.leg_f = Limb(-95, -150, -150)
    else:
        p.leg_f = leg_to(p, "f", (ank[0] - 0.01, ank[1]), +1, foot=fa)
    p.arm_n = straight_limb(-92); p.arm_f = straight_limb(-88)
    return p


exercise("1373", "bodyweight standing calf raise", 1.8, active=("leg_n", "leg_f"))(lambda t: calf_pose(updown(t)))
exercise("1387", "one leg floor calf raise", 1.8, active=("leg_n",))(lambda t: calf_pose(updown(t), one_leg=True))
exercise("1490", "standing calf raise (on a staircase)", 2.0, active=("leg_n", "leg_f"),
         props=("floor", ("box", 0.25, 0.40, 0.14)))(lambda t: calf_pose(updown(t), step=True))


@exercise("0284", "donkey calf raise", 2.0, active=("leg_n", "leg_f"), props=("floor", ("box", 0.62, 0.20, 0.70)))
def donkey_calf(t):
    # Bent over at the hips, hands on a support, calves raise the heels.
    r = updown(t)
    p = calf_pose(r)
    p.torso = 8
    p.head = 20
    hand = (0.60, 0.72)
    p.arm_n = arm_to(p, "n", hand, -1, hand=0); p.arm_f = p.arm_n
    return p


@exercise("1386", "one leg donkey calf raise", 2.0, active=("leg_n",), props=("floor", ("box", 0.62, 0.20, 0.70)))
def one_leg_donkey(t):
    p = donkey_calf(t)
    p.leg_f = Limb(-110, -160, -150)
    return p


# ---------------------------------------------------------------- holds, steps and jumps

@exercise("gf-wall-sit", "wall sit", 3.0, active=("legs",), props=("floor", ("wall", -0.13)))
def wall_sit(t):
    # Back flat on the wall, thighs parallel to the floor, held.
    breathe = 0.004 * math.sin(2 * math.pi * t)
    hip = (-0.07, L['heel'] + L['shin'] + 0.01 + breathe)
    p = Pose(hip=hip, torso=90, head=90)
    for side, dx in (("n", 0.0), ("f", -0.01)):
        setattr(p, f"leg_{side}", leg_to(p, side, ankle_on_floor(hip[0] + L['thigh'] + dx), +1))
    p.arm_n = Limb(-80, -20, -20); p.arm_f = p.arm_n
    return p


@exercise("0624", "march sit (wall)", 2.4, active=("legs",), props=("floor", ("wall", -0.13)))
def march_sit(t):
    p = wall_sit(0)
    for side, (a, b) in (("n", (0.05, 0.45)), ("f", (0.55, 0.95))):
        k = updown((t - a) / (b - a)) if a <= t <= b else 0
        if k:
            leg = getattr(p, f"leg_{side}")
            setattr(p, f"leg_{side}", Limb(leg.a1 + 25 * k, leg.a2 + 15 * k, leg.a3))
    return p


@exercise("gf-step-up", "step-up", 3.2, active=("legs",), props=("floor", ("box", 0.30, 0.34, 0.30)))
def step_up(t):
    # One foot on the box, stand up onto it, step back down, switch nothing (same lead leg).
    box_top = 0.30
    if t < 0.15:   # lead foot onto the box
        k = ease(t / 0.15)
        p = Pose(hip=(0.0, STAND_H), torso=90, head=90)
        p.leg_n = leg_to(p, "n", (lerp(0.0, 0.26, k), L['heel'] + lerp(0, box_top, k) + 0.08 * math.sin(math.pi * k)), +1)
        p.leg_f = leg_to(p, "f", ankle_on_floor(-0.01), +1)
    elif t < 0.45:  # drive up
        k = ease((t - 0.15) / 0.30)
        hip = (lerp(0.0, 0.25, k), lerp(STAND_H, STAND_H + box_top, k))
        p = Pose(hip=hip, torso=lerp(84, 90, k), head=90)
        p.leg_n = leg_to(p, "n", (0.26, box_top + L['heel']), +1)
        p.leg_f = leg_to(p, "f", (lerp(-0.01, 0.24, k), L['heel'] + lerp(0, box_top, k) + 0.06 * math.sin(math.pi * k)), +1)
    elif t < 0.60:
        hip = (0.25, STAND_H + box_top)
        p = Pose(hip=hip, torso=90, head=90)
        p.leg_n = leg_to(p, "n", (0.26, box_top + L['heel']), +1)
        p.leg_f = leg_to(p, "f", (0.24, box_top + L['heel']), +1)
    else:          # step down, trailing leg first
        k = ease((t - 0.60) / 0.40)
        hip = (lerp(0.25, 0.0, k), lerp(STAND_H + box_top, STAND_H, k))
        p = Pose(hip=hip, torso=90, head=90)
        p.leg_f = leg_to(p, "f", (lerp(0.24, -0.01, min(1, k * 1.6)), L['heel'] + lerp(box_top, 0, min(1, k * 1.6))), +1)
        p.leg_n = leg_to(p, "n", (lerp(0.26, 0.0, max(0, k * 1.6 - 0.6)), L['heel'] + lerp(box_top, 0, max(0, k * 1.6 - 0.6))), +1)
    p.arm_n = Limb(-95, -80, -80); p.arm_f = Limb(-85, -100, -100)
    return p


def broad_jump(t, direction=1):
    dist = 0.55 * direction
    if t < 0.30:
        p = squat_pose(0.6 * ease(t / 0.30), arms="forward")
        a = lerp(-90, -150, ease(t / 0.30)); p.arm_n = straight_limb(a); p.arm_f = straight_limb(a)
        return p
    if t < 0.60:
        u = (t - 0.30) / 0.30
        p = jump(squat_pose(0.2), math.sin(math.pi * u), 0.16)
        p.hip = (lerp(0, dist, u) + p.hip[0], p.hip[1])
        a = lerp(-150, 40, u); p.arm_n = straight_limb(a); p.arm_f = straight_limb(a)
        return p
    if t < 0.80:
        p = squat_pose(0.6 * math.sin(math.pi * (t - 0.60) / 0.40), arms="forward")
        p.hip = (p.hip[0] + dist, p.hip[1])
        for side in "nf":
            setattr(p, f"leg_{side}", leg_to(p, side, ankle_on_floor(dist), +1))
        return p
    # walk back to the start (reset), shown as a quick shuffle
    u = (t - 0.80) / 0.20
    p = squat_pose(0)
    p.hip = (lerp(dist, 0, ease(u)), p.hip[1])
    for side, off in (("n", 0.08), ("f", -0.08)):
        setattr(p, f"leg_{side}", leg_to(p, side, (p.hip[0] + off * math.sin(math.pi * u * 2), L['heel']), +1))
    return p


exercise("1472", "forward jump", 2.6, active=("legs",))(lambda t: broad_jump(t))
exercise("1473", "backward jump", 2.6, active=("legs",))(lambda t: broad_jump(t, -1))


@exercise("0795", "standing single leg curl", 2.2, active=("leg_n",))
def standing_leg_curl(t):
    k = updown(t)
    p = squat_pose(0)
    p.leg_n = Limb(-95, lerp(-92, 10, k), lerp(0, 60, k))
    p.arm_n = Limb(-60, -30, -30); p.arm_f = p.arm_n
    return p
