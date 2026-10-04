"""
GymFree's exercise figure: a rigged 2D mannequin whose poses are computed with real
constraints (hands and feet stay planted, bodies stay straight where they should) and
exported as Lottie animations.

World coordinates: metres-ish units where the figure is 1.0 tall, y up, the floor at y = 0.
Every segment has an absolute direction angle in degrees, measured from +x
counter-clockwise (0 = pointing forward/right, 90 = up, -90 = down).
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field, replace

# Proportions of a 1.0-tall figure.
L = dict(
    torso=0.30,     # hip to base of neck
    neck=0.045,
    head=0.115,     # head diameter
    uarm=0.165, farm=0.145, hand=0.055,
    thigh=0.245, shin=0.235, foot=0.12,
    heel=0.03,      # ankle height above the sole
)
SHOULDER_AT = 0.93  # shoulder position along the torso

Vec = tuple[float, float]


def v(a: float, length: float) -> Vec:
    r = math.radians(a)
    return (length * math.cos(r), length * math.sin(r))


def add(p: Vec, q: Vec) -> Vec:
    return (p[0] + q[0], p[1] + q[1])


def sub(p: Vec, q: Vec) -> Vec:
    return (p[0] - q[0], p[1] - q[1])


def dist(p: Vec, q: Vec) -> float:
    return math.hypot(p[0] - q[0], p[1] - q[1])


def angle_of(p: Vec, q: Vec) -> float:
    """Direction from p to q, degrees."""
    return math.degrees(math.atan2(q[1] - p[1], q[0] - p[0]))


def lerp(a, b, t):
    if isinstance(a, tuple):
        return tuple(lerp(x, y, t) for x, y in zip(a, b))
    return a + (b - a) * t


def lerp_angle(a: float, b: float, t: float) -> float:
    d = (b - a + 180) % 360 - 180
    return a + d * t


def ease(t: float) -> float:
    """Smooth in and out (cosine)."""
    return 0.5 - 0.5 * math.cos(math.pi * max(0.0, min(1.0, t)))


def two_bone(root: Vec, target: Vec, l1: float, l2: float, bend: int) -> tuple[float, float]:
    """
    Angles of two segments from `root` reaching `target`. `bend` +1 or -1 picks which side the
    middle joint goes (+1: counter-clockwise of the root→target line). Out of reach straightens.
    """
    d = min(dist(root, target), l1 + l2 - 1e-6)
    d = max(d, abs(l1 - l2) + 1e-6)
    base = angle_of(root, target)
    cos_a = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    a = math.degrees(math.acos(max(-1, min(1, cos_a))))
    a1 = base + bend * a
    elbow = add(root, v(a1, l1))
    a2 = angle_of(elbow, target) if dist(root, target) <= l1 + l2 else a1
    return a1, a2


@dataclass
class Limb:
    a1: float          # upper segment (upper arm / thigh)
    a2: float          # lower segment (forearm / shin)
    a3: float          # end (hand / foot)


@dataclass
class Pose:
    hip: Vec                      # pelvis position (the root)
    torso: float = 90             # hip → neck
    head: float = 90              # neck → top of head
    arm_n: Limb = field(default_factory=lambda: Limb(-90, -90, -90))   # near side (toward viewer)
    arm_f: Limb = field(default_factory=lambda: Limb(-90, -90, -90))   # far side
    leg_n: Limb = field(default_factory=lambda: Limb(-90, -90, 0))
    leg_f: Limb = field(default_factory=lambda: Limb(-90, -90, 0))

    # joint positions, for constraints and checks
    def neck(self) -> Vec:
        return add(self.hip, v(self.torso, L['torso']))

    def shoulder(self) -> Vec:
        return add(self.hip, v(self.torso, L['torso'] * SHOULDER_AT))

    def elbow(self, side='n') -> Vec:
        arm = self.arm_n if side == 'n' else self.arm_f
        return add(self.shoulder(), v(arm.a1, L['uarm']))

    def wrist(self, side='n') -> Vec:
        arm = self.arm_n if side == 'n' else self.arm_f
        return add(self.elbow(side), v(arm.a2, L['farm']))

    def knee(self, side='n') -> Vec:
        leg = self.leg_n if side == 'n' else self.leg_f
        return add(self.hip, v(leg.a1, L['thigh']))

    def ankle(self, side='n') -> Vec:
        leg = self.leg_n if side == 'n' else self.leg_f
        return add(self.knee(side), v(leg.a2, L['shin']))

    def head_center(self) -> Vec:
        return add(add(self.neck(), v(self.head, L['neck'])), v(self.head, L['head'] / 2))

    def lowest(self) -> float:
        """The lowest point of the body, to keep it on the floor."""
        pts = [self.head_center(), self.hip]
        for s in 'nf':
            pts += [self.wrist(s), self.ankle(s), self.elbow(s), self.knee(s)]
            leg = self.leg_n if s == 'n' else self.leg_f
            toe = add(self.ankle(s), v(leg.a3, L['foot'] * 0.75))
            pts += [toe]
        return min(p[1] for p in pts)


def arm_to(p: Pose, side: str, target: Vec, bend: int, hand: float | None = None) -> Limb:
    a1, a2 = two_bone(p.shoulder(), target, L['uarm'], L['farm'], bend)
    return Limb(a1, a2, a2 if hand is None else hand)


def leg_to(p: Pose, side: str, ankle: Vec, bend: int, foot: float = 0) -> Limb:
    a1, a2 = two_bone(p.hip, ankle, L['thigh'], L['shin'], bend)
    return Limb(a1, a2, foot)


# A leg reaching the floor: the ankle sits L['heel'] above it.
def ankle_on_floor(x: float, floor: float = 0.0) -> Vec:
    return (x, floor + L['heel'])


def standing(x: float = 0.0) -> Pose:
    hip_h = L['heel'] + L['thigh'] + L['shin'] - 0.004
    p = Pose(hip=(x, hip_h))
    p.leg_n = leg_to(p, 'n', ankle_on_floor(x + 0.01), +1)
    p.leg_f = leg_to(p, 'f', ankle_on_floor(x - 0.01), +1)
    return p


def interpolate(a: Pose, b: Pose, t: float) -> Pose:
    def limb(x: Limb, y: Limb) -> Limb:
        return Limb(lerp_angle(x.a1, y.a1, t), lerp_angle(x.a2, y.a2, t), lerp_angle(x.a3, y.a3, t))
    return Pose(hip=lerp(a.hip, b.hip, t), torso=lerp_angle(a.torso, b.torso, t), head=lerp_angle(a.head, b.head, t),
                arm_n=limb(a.arm_n, b.arm_n), arm_f=limb(a.arm_f, b.arm_f),
                leg_n=limb(a.leg_n, b.leg_n), leg_f=limb(a.leg_f, b.leg_f))
