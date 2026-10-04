"""Pull-ups, rows, dips and hanging leg raises."""
from __future__ import annotations

import math

from registry import exercise
from rig import L, SHOULDER_AT, Limb, Pose, add, angle_of, ankle_on_floor, arm_to, dist, ease, leg_to, lerp, lerp_angle, v
from exercises import BAR_Y, DIP_H, LEG, updown, straight_limb

ARM = L['uarm'] + L['farm']
GRIP = (0.03, BAR_Y - 0.01)
BAR = ("bar", (0.03, BAR_Y))


def hang_pose(d, lean=(92, 102), top_y=0.12, hand_angle=90, legs=None, sh_x=(-0.005, -0.04), bar=GRIP):
    """Hanging from the bar: d 0 arms straight, 1 at the top."""
    wrist = add(bar, v(-90, L['hand'] * 0.6))
    reach = ARM + L['hand'] * 0.6
    sh = (lerp(bar[0] + sh_x[0] - 0.03, bar[0] + sh_x[1] - 0.03, d), lerp(bar[1] - reach + 0.01, bar[1] - top_y, d))
    torso = lerp(lean[0], lean[1], d)
    hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=torso, head=lerp(lean[0], lean[0] + 4, d))
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, -1, hand=hand_angle))
    if legs is None:
        p.leg_n = Limb(-82, -96, -60); p.leg_f = Limb(-84, -98, -62)
    else:
        p.leg_n, p.leg_f = legs(d)
    return p


def pull_variant(id, name, period=2.8, active=("arms", "torso"), **kw):
    exercise(id, name, period, active=active, props=("floor", BAR))(
        lambda t: hang_pose(updown(t, down=(0.08, 0.45), up=(0.55, 0.95)), **kw))


pull_variant("0651", "pull up (neutral grip)")
pull_variant("1429", "wide grip pull-up", lean=(93, 104))
pull_variant("0674", "reverse grip pull-up", active=("arms",), lean=(92, 98))
pull_variant("0139", "biceps narrow pull-ups", active=("arms",), lean=(92, 97))
pull_variant("0140", "biceps pull-up", active=("arms",), lean=(92, 97))
pull_variant("0253", "chin-ups (narrow parallel grip)", active=("arms",), lean=(92, 97))
pull_variant("1327", "close grip chin-up", active=("arms",), lean=(92, 97))
pull_variant("0627", "mixed grip chin-up", lean=(92, 100))
pull_variant("1763", "shoulder grip pull-up", lean=(92, 101))
pull_variant("3019", "bench pull-ups", lean=(92, 100))
# Behind the neck: the body leans forward so the bar passes behind the head.
pull_variant("0670", "rear pull-up", lean=(88, 78), sh_x=(0.02, 0.10), top_y=0.20)
pull_variant("1367", "wide grip rear pull-up", lean=(88, 78), sh_x=(0.02, 0.10), top_y=0.20)
# Sternum chin: lean far back and pull the lower chest to the bar.
pull_variant("0466", "gironda sternum chin", lean=(98, 140), sh_x=(-0.02, -0.14), top_y=0.05)
# L-pull-up: legs held straight out in front.
pull_variant("3418", "l-pull-up", active=("arms", "torso", "legs"), lean=(94, 100),
             legs=lambda d: (Limb(-2, -2, 20), Limb(0, 0, 22)))
pull_variant("0638", "one arm chin-up", active=("arms",), lean=(92, 98))


@exercise("0467", "gorilla chin", 2.8, active=("arms", "torso", "legs"), props=("floor", BAR))
def gorilla_chin(t):
    d = updown(t, down=(0.08, 0.45), up=(0.55, 0.95))
    return hang_pose(d, legs=lambda d: (Limb(lerp(-82, 10, d), lerp(-96, -80, d), -40), Limb(lerp(-84, 8, d), lerp(-98, -82, d), -42)))


@exercise("0688", "scapular pull-up", 2.2, active=("torso",), props=("floor", BAR))
def scapular_pull_up(t):
    # Arms stay straight: the shoulders pull down and back, lifting the body a few centimetres.
    d = updown(t)
    p = hang_pose(0)
    return Pose(hip=add(p.hip, (0, 0.035 * d)), torso=p.torso + 3 * d, head=p.head, arm_n=p.arm_n, arm_f=p.arm_f,
                leg_n=p.leg_n, leg_f=p.leg_f) if False else hang_pose(0.12 * d, lean=(92, 99))


@exercise("gf-dead-hang", "dead hang", 3.0, active=("arms",), props=("floor", BAR))
def dead_hang(t):
    p = hang_pose(0.01 * math.sin(2 * math.pi * t))
    return p


@exercise("gf-negative-pull-up", "negative pull-up", 4.0, active=("arms", "torso"), props=("floor", BAR))
def negative_pull_up(t):
    # Jump to the top, then lower as slowly as you can.
    if t < 0.15:
        return hang_pose(ease(t / 0.15))
    if t < 0.25:
        return hang_pose(1)
    return hang_pose(1 - (t - 0.25) / 0.75)


def muscle_up_pose(t, kip=False):
    # Pull hard to the chest, roll the wrists over, press out to straight arms above the bar.
    if t < 0.35:
        d = ease(t / 0.35)
        p = hang_pose(d, lean=(92, 112), top_y=0.02, sh_x=(-0.005, -0.08))
        if kip:
            sw = math.sin(math.pi * d)
            p.leg_n = Limb(-82 - 25 * sw, -96 - 20 * sw, -60); p.leg_f = p.leg_n
        return p
    if t < 0.55:
        u = ease((t - 0.35) / 0.20)
        # The transition: chest over the bar, elbows travel from below to above.
        sh = (lerp(GRIP[0] - 0.11, GRIP[0] + 0.02, u), lerp(BAR_Y - 0.02, BAR_Y + 0.10, u))
        torso = lerp(112, 70, u)
        hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
        p = Pose(hip=hip, torso=torso, head=torso)
        hand = (GRIP[0], BAR_Y + 0.02)
        for side in "nf":
            setattr(p, f"arm_{side}", arm_to(p, side, hand, -1 if u < 0.5 else -1, hand=0))
        p.leg_n = Limb(-100, -115, -80); p.leg_f = p.leg_n
        return p
    if t < 0.75:
        u = ease((t - 0.55) / 0.20)
        hand = (GRIP[0], BAR_Y + 0.02)
        sh = (GRIP[0] + 0.02, lerp(BAR_Y + 0.10, BAR_Y + ARM - 0.01, u))
        torso = lerp(70, 90, u)
        hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
        p = Pose(hip=hip, torso=torso, head=torso)
        for side in "nf":
            setattr(p, f"arm_{side}", arm_to(p, side, hand, -1, hand=0))
        p.leg_n = Limb(-95, -105, -70); p.leg_f = p.leg_n
        return p
    # Lower back down under control to a hang.
    u = ease((t - 0.75) / 0.25)
    return hang_pose(1 - u, lean=(92, 112), top_y=0.02)


exercise("0631", "muscle up", 3.4, active=("arms", "torso"), props=("floor", BAR))(lambda t: muscle_up_pose(t))
exercise("0558", "kipping muscle up", 3.0, active=("arms", "torso"), props=("floor", BAR))(lambda t: muscle_up_pose(t, kip=True))
exercise("1401", "muscle-up (on vertical bar)", 3.4, active=("arms", "torso"), props=("floor", BAR))(lambda t: muscle_up_pose(t))


# ---------------------------------------------------------------- hanging leg raises

def hanging_raise(t, knees_bent=True, to_bar=False, hip_only=False):
    d = updown(t)
    p = hang_pose(0)
    if hip_only:   # hip raise: the pelvis curls up as the legs lift
        thigh = lerp(-85, 30 if knees_bent else 10, d)
    else:
        thigh = lerp(-85, (5 if knees_bent else -2) if not to_bar else 60, d)
    shin = thigh - (lerp(10, 100, d) if knees_bent else 0)
    p.torso = lerp(p.torso, 100 if (hip_only or to_bar) else 94, d)
    p.leg_n = Limb(thigh, shin, shin + 40); p.leg_f = Limb(thigh - 2, shin - 2, shin + 38)
    return p


exercise("0472", "hanging leg raise", 2.6, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t))
exercise("0475", "hanging straight leg raise", 2.8, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t, knees_bent=False))
exercise("1764", "hanging leg hip raise", 2.8, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t, hip_only=True))
exercise("0474", "hanging straight leg hip raise", 2.8, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t, knees_bent=False, hip_only=True))
exercise("0473", "hanging pike", 3.0, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t, knees_bent=False, to_bar=True))
exercise("gf-toes-to-bar", "toes to bar", 2.6, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t, knees_bent=False, to_bar=True))
exercise("1761", "hanging oblique knee raise", 2.6, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t))
exercise("0476", "hanging straight twisting leg hip raise", 2.8, active=("torso", "legs"), props=("floor", BAR))(lambda t: hanging_raise(t, knees_bent=False, hip_only=True))


def support_raise(t, straight=False):
    """Captain's chair / parallel bars: held up on the forearms or straight arms, legs lift."""
    d = updown(t)
    hand = (0.0, DIP_H + 0.02)
    sh = (-0.02, DIP_H + ARM - 0.01)
    hip = add(sh, v(270, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=90, head=90)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, hand, -1, hand=0))
    thigh = lerp(-88, 0, d)
    shin = thigh - (0 if straight else lerp(5, 90, d))
    p.leg_n = Limb(thigh, shin, shin + 40); p.leg_f = Limb(thigh - 2, shin - 2, shin + 38)
    return p


exercise("2963", "captains chair straight leg raise", 2.6, active=("torso", "legs"),
         props=("floor", ("parallettes", 0.0, DIP_H)))(lambda t: support_raise(t, True))
exercise("0826", "vertical leg raise (on parallel bars)", 2.6, active=("torso", "legs"),
         props=("floor", ("parallettes", 0.0, DIP_H)))(lambda t: support_raise(t))


# ---------------------------------------------------------------- rows

ROW_BAR = 0.56


def row_pose(d, bar_h=ROW_BAR, knees=False, feet_on=None, top_y=0.06):
    """Inverted row under a bar: body straight from the heels, chest pulled up to the bar."""
    bar = (0.0, bar_h)
    wrist = add(bar, (0, -0.02))
    heel_y = feet_on if feet_on is not None else 0.0
    # Heels on the floor (or a bench) ahead of... behind the bar; the body hangs under it.
    # Heels on the floor (or a bench) far enough out that the body hangs under the bar.
    if knees:
        ankle = (-0.42, L['heel'] + heel_y)
    else:
        ankle = (-0.72, L['heel'] + heel_y)
    def body(beta):
        hip_from = ankle
        if knees:
            knee = add(ankle, v(90, L['shin']))
            hip = add(knee, v(beta, L['thigh']))
        else:
            hip = add(ankle, v(beta, LEG))
        return hip
    # The bottom: the body angle at which straight arms just reach the bar. The top: about
    # 20 degrees higher, chest at the bar.
    lo, hi = -10.0, 70.0
    for _ in range(50):
        mid = (lo + hi) / 2
        hip = body(mid)
        sh = add(hip, v(mid, L['torso'] * SHOULDER_AT))
        if dist(sh, wrist) > ARM - 0.01:
            lo = mid
        else:
            hi = mid
    lo = hi = (lo + hi) / 2 + (19 if knees else 14) * d
    beta = (lo + hi) / 2
    hip = body(beta)
    p = Pose(hip=hip, torso=beta, head=beta + 5)
    if knees:
        knee = add(ankle, v(90, L['shin']))
        th = angle_of(hip, knee)
        p.leg_n = Limb(th, -90, 0); p.leg_f = p.leg_n
    else:
        back = beta + 180
        p.leg_n = Limb(back, back, back + 100); p.leg_f = p.leg_n
    for side in "nf":
        # Elbows drive back past the ribs, toward the feet.
        setattr(p, f"arm_{side}", arm_to(p, side, wrist, +1, hand=90))
    return p


ROW_PROPS = ("floor", ("bar", (0.0, ROW_BAR), "posts"))
exercise("0499", "inverted row", 2.6, active=("arms", "torso"), props=ROW_PROPS)(lambda t: row_pose(updown(t)))
exercise("0497", "inverted row v. 2", 2.6, active=("arms", "torso"), props=ROW_PROPS)(lambda t: row_pose(updown(t)))
exercise("2300", "inverted row bent knees", 2.6, active=("arms", "torso"), props=ROW_PROPS)(lambda t: row_pose(updown(t), knees=True))
exercise("2298", "inverted row on bench", 2.6, active=("arms", "torso"),
         props=("floor", ("bar", (0.0, ROW_BAR), "posts"), ("box", -0.74, 0.3, 0.26)))(lambda t: row_pose(updown(t), feet_on=0.26))
exercise("0498", "inverted row with straps", 2.6, active=("arms", "torso"), props=ROW_PROPS)(lambda t: row_pose(updown(t)))
exercise("0808", "suspended row", 2.6, active=("arms", "torso"), props=ROW_PROPS)(lambda t: row_pose(updown(t)))


def standing_row(t, squat=False):
    """Holding a door frame (or a towel round a post) and leaning back, then pulling in."""
    d = updown(t)
    post = (0.40, 0.95)
    ankle = (0.18, L['heel'])
    lean = lerp(64, 80, d)   # body angle from the heels
    if squat:
        hip = (lerp(-0.05, 0.02, d), 0.40)
        p = Pose(hip=hip, torso=lerp(70, 84, d), head=84)
        for side in "nf":
            setattr(p, f"leg_{side}", leg_to(p, side, ankle, +1))
    else:
        hip = add(ankle, v(180 - lean + 0, LEG)) if False else add(ankle, v(180 - (90 - lean) - 90 + 90 + 0, 0))
        hip = (ankle[0] - LEG * math.cos(math.radians(lean)), ankle[1] + LEG * math.sin(math.radians(lean)))
        # One straight line from the heels, leaning back away from the post.
        p = Pose(hip=hip, torso=180 - lean, head=180 - lean - 8)
        th = angle_of(hip, ankle)
        p.leg_n = Limb(th, th, 0); p.leg_f = p.leg_n
    hand = (post[0] - 0.02, post[1] - 0.05 if not squat else 0.62)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, hand, -1, hand=0))
    return p


for id, name in (("3166", "bodyweight standing row"), ("3165", "bodyweight standing row (with towel)"),
                 ("3158", "bodyweight standing close-grip row"), ("3162", "bodyweight standing one arm row"),
                 ("3161", "bodyweight standing one arm row (with towel)"), ("3156", "bodyweight standing close-grip one arm row"),
                 ("1773", "one arm towel row")):
    exercise(id, name, 2.6, active=("arms", "torso"), props=("floor", ("wall", 0.40)))(lambda t: standing_row(t))
for id, name in (("3168", "bodyweight squatting row"), ("3167", "bodyweight squatting row (with towel)")):
    exercise(id, name, 2.6, active=("arms", "torso"), props=("floor", ("wall", 0.40)))(lambda t: standing_row(t, squat=True))


# ---------------------------------------------------------------- dips

def dip_pose(d, lean=(96, 66), sh_x=(-0.01, -0.06), legs="crossed", hand_h=DIP_H, depth=0.10):
    hand = (0.0, hand_h + 0.02)
    torso = lerp(lean[0], lean[1], d)
    sh = (lerp(sh_x[0], sh_x[1], d), lerp(hand_h + ARM - 0.01, hand_h + depth, d))
    hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=torso, head=lerp(lean[0], lean[1] - 6, d))
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, hand, -1, hand=0))
    lean_off = torso - 90
    if legs == "crossed":
        p.leg_n = Limb(-96 + lean_off * 0.5, -128 + lean_off * 0.4, -120)
        p.leg_f = Limb(-92 + lean_off * 0.5, -122 + lean_off * 0.4, -115)
    else:   # straight down
        p.leg_n = Limb(-92 + lean_off * 0.3, -94 + lean_off * 0.3, -70); p.leg_f = p.leg_n
    return p


DIP_PROPS = ("floor", ("parallettes", 0.0, DIP_H))
exercise("1430", "chest dip (on dip-pull-up cage)", 2.6, active=("arms", "torso"), props=DIP_PROPS)(lambda t: dip_pose(updown(t)))
exercise("2363", "wide-grip chest dip on high parallel bars", 2.6, active=("arms", "torso"), props=DIP_PROPS)(lambda t: dip_pose(updown(t), lean=(94, 60)))
exercise("0814", "triceps dip", 2.6, active=("arms",), props=DIP_PROPS)(lambda t: dip_pose(updown(t), lean=(92, 86), sh_x=(-0.01, -0.03), legs="straight"))
exercise("0677", "ring dips", 2.8, active=("arms", "torso"), props=DIP_PROPS)(lambda t: dip_pose(updown(t), lean=(94, 74)))
exercise("2462", "chest dip on straight bar", 2.6, active=("arms", "torso"), props=DIP_PROPS)(lambda t: dip_pose(updown(t), lean=(80, 55), sh_x=(-0.05, -0.12)))
exercise("0639", "one arm dip", 2.6, active=("arms",), props=DIP_PROPS)(lambda t: dip_pose(updown(t), lean=(90, 80), depth=0.16))
exercise("3012", "scapula dips", 2.0, active=("torso",), props=DIP_PROPS)(lambda t: dip_pose(0.12 * updown(t), lean=(92, 92)))


@exercise("3288", "korean dips", 2.6, active=("arms", "torso"), props=DIP_PROPS)
def korean_dip(t):
    # The bar behind you: hands behind the hips, the body leaning forward as you lower.
    d = updown(t)
    hand = (0.0, DIP_H + 0.02)
    torso = lerp(86, 60, d)
    sh = (lerp(0.07, 0.20, d), lerp(DIP_H + 0.24, DIP_H + 0.02, d))
    hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=torso, head=torso - 5)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, hand, +1, hand=180))
    p.leg_n = Limb(-80, -85, -60); p.leg_f = p.leg_n
    return p


def bench_dip(d, feet="floor", knees_bent=False, floor_hands=False):
    """Hands on a bench behind you (or on the floor), hips dropping in front of it."""
    bench_h = 0.0 if floor_hands else 0.26
    hand = (0.0, bench_h + 0.02)
    sh = (0.045, lerp(bench_h + ARM - 0.01, bench_h + 0.14, d))
    torso = lerp(88, 80, d)
    hip = add(sh, v(torso + 180, L['torso'] * SHOULDER_AT))
    p = Pose(hip=hip, torso=torso, head=torso)
    for side in "nf":
        setattr(p, f"arm_{side}", arm_to(p, side, hand, +1, hand=180))
    if feet == "bench":
        ank = (0.62, 0.26 + L['heel'])
    elif knees_bent or floor_hands:
        ank = (hip[0] + 0.40, L['heel'])
    else:
        ank = (hip[0] + 0.62, L['heel'])
    for side in "nf":
        setattr(p, f"leg_{side}", leg_to(p, side, ank, +1, foot=60 if not (knees_bent or floor_hands) else 0))
    return p


BENCH_PROP = ("box", -0.12, 0.30, 0.26)
exercise("0129", "bench dip (knees bent)", 2.4, active=("arms",), props=("floor", BENCH_PROP))(lambda t: bench_dip(updown(t), knees_bent=True))
exercise("0812", "triceps dip (bench leg)", 2.4, active=("arms",), props=("floor", BENCH_PROP))(lambda t: bench_dip(updown(t)))
exercise("0813", "triceps dip (between benches)", 2.4, active=("arms",), props=("floor", BENCH_PROP, ("box", 0.70, 0.24, 0.26)))(lambda t: bench_dip(updown(t), feet="bench"))
exercise("1753", "three bench dip", 2.4, active=("arms",), props=("floor", BENCH_PROP, ("box", 0.70, 0.24, 0.26)))(lambda t: bench_dip(updown(t), feet="bench"))
exercise("1399", "bench dip on floor", 2.2, active=("arms",))(lambda t: bench_dip(updown(t) * 0.7, floor_hands=True))
exercise("0815", "triceps dips floor", 2.2, active=("arms",))(lambda t: bench_dip(updown(t) * 0.7, floor_hands=True))
exercise("0672", "reverse dip", 2.4, active=("arms",), props=("floor", BENCH_PROP))(lambda t: bench_dip(updown(t)))
