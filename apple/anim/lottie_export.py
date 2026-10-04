"""
Exports a sampled exercise (a list of Poses over one loop) as a Lottie animation: a parented
rig whose joints rotate, so the motion is smooth at any frame rate and sharp at any size.
"""
from __future__ import annotations

import json
import math

from rig import L, SHOULDER_AT, Pose

W = H = 600
FPS = 60

# Colours: a light figure on the app's dark stage. Working segments in GymFree lime.
BODY = (0.91, 0.93, 0.95)
BODY_FAR = (0.55, 0.60, 0.65)
ACTIVE = (0.19, 0.82, 0.35)
ACTIVE_FAR = (0.10, 0.50, 0.21)
PROP = (0.40, 0.45, 0.50)
FLOOR = (0.25, 0.29, 0.33)

# Thickness of each segment (world units).
T = dict(torso=0.115, uarm=0.060, farm=0.048, hand=0.040, thigh=0.088, shin=0.066, neck=0.045)
# Where each limb ends (its thickness at the far joint).
TE = dict(uarm=0.050, farm=0.036, hand=0.034, thigh=0.064, shin=0.040)

# Lateral offsets of the shoulders and hips in the front view (world units).
FRONT_SHOULDER = 0.085
FRONT_HIP = 0.048


def unwrap(values: list[float]) -> list[float]:
    out = [values[0]]
    for a in values[1:]:
        prev = out[-1]
        out.append(prev + ((a - prev + 180) % 360 - 180))
    return out


def anim(values, times, linear=True):
    """An animated Lottie property from per-sample values (numbers or lists)."""
    if all(json.dumps(x) == json.dumps(values[0]) for x in values):
        return {"a": 0, "k": values[0] if isinstance(values[0], list) else values[0]}
    keys = []
    for i, (t, val) in enumerate(zip(times, values)):
        val = val if isinstance(val, list) else [val]
        k = {"t": t, "s": [round(x, 3) for x in val]}
        if i < len(values) - 1:
            n = len(val)
            k["i"] = {"x": [1] * n, "y": [1] * n}
            k["o"] = {"x": [0] * n, "y": [0] * n}
        keys.append(k)
    return {"a": 1, "k": keys}


def static(value):
    return {"a": 0, "k": value}


def ks(p=None, r=None, a=None, o=None):
    return {"o": o or static(100), "r": r or static(0), "p": p or static([0, 0, 0]),
            "a": a or static([0, 0, 0]), "s": static([100, 100, 100])}


def fill(rgb):
    return {"ty": "fl", "c": static([rgb[0], rgb[1], rgb[2], 1]), "o": static(100), "r": 1, "nm": "fill"}


def rect(cx, cy, w, h, r):
    return {"ty": "rc", "d": 1, "p": static([cx, cy]), "s": static([w, h]), "r": static(r), "nm": "rect"}


def ellipse(cx, cy, w, h):
    return {"ty": "el", "d": 1, "p": static([cx, cy]), "s": static([w, h]), "nm": "ellipse"}


def group(items, rgb, name):
    return {"ty": "gr", "nm": name, "it": items + [fill(rgb), {"ty": "tr", "p": static([0, 0]), "a": static([0, 0]),
            "s": static([100, 100]), "r": static(0), "o": static(100), "sk": static(0), "sa": static(0)}]}


class Camera:
    """World (y up, figure 1.0 tall) to Lottie pixels (y down)."""

    def __init__(self, cx: float, floor_y: float, scale: float):
        self.cx, self.floor_y, self.scale = cx, floor_y, scale

    def pt(self, p):
        return [W / 2 + (p[0] - self.cx) * self.scale, self.floor_y - p[1] * self.scale]

    def len(self, x):
        return x * self.scale


def path(points, closed=True):
    return {"ty": "sh", "nm": "path", "ks": static({"i": [[0, 0]] * len(points), "o": [[0, 0]] * len(points),
                                                   "v": [[round(x, 2), round(y, 2)] for x, y in points], "c": closed})}


def capsule(length_px, thick_px, rgb, name, end_px=None):
    """A limb from its joint along +x, tapering from thick_px to end_px, with round ends."""
    e = end_px if end_px is not None else thick_px * 0.82
    a, b = thick_px / 2, e / 2
    return group([ellipse(0, 0, thick_px, thick_px), ellipse(length_px, 0, e, e),
                  path([(0, -a), (length_px, -b), (length_px, b), (0, a)])], rgb, name)


def build(name: str, poses: list[Pose], period: float, active: set[str], props: list[dict], cam: Camera,
          view: str = "side") -> dict:
    n = len(poses)
    frames = round(period * FPS)
    times = [round(i * frames / n, 3) for i in range(n)] + [frames]
    poses = poses + [poses[0]]  # close the loop
    s = cam.len
    layers = []
    ind = [0]

    def add_layer(layer):
        ind[0] += 1
        layer.update({"ddd": 0, "ind": ind[0], "ip": 0, "op": frames, "st": 0, "sr": 1, "ao": 0, "bm": 0})
        layers.append(layer)
        return ind[0]

    def rot(values):  # world direction (deg, CCW) → Lottie rotation (deg, clockwise)
        return [-a for a in values]

    # Root: the pelvis (a null), moved in world space.
    pelvis = add_layer({"ty": 3, "nm": "pelvis", "ks": ks(p=anim([cam.pt(p.hip) + [0] for p in poses], times))})

    torso_abs = unwrap([p.torso for p in poses])
    # Lottie draws later layers on top: collect then order far → near.
    built = {}

    def limb_chain(prefix, side, parent, base_rot, attach, segs, thick, colour_key):
        """segs: list of (name, getter(pose)->abs angle, length, shape_fn)."""
        parent_abs = base_rot
        out = []
        pos = attach
        par = parent
        for seg_name, getter, length, shape in segs:
            absolute = unwrap([getter(p) for p in poses])
            rel = [a - b for a, b in zip(absolute, parent_abs)]
            colour = colour_for(colour_key, side)
            lay = {"ty": 4, "nm": f"{prefix}_{seg_name}", "parent": par,
                   "ks": ks(p=static(pos + [0]), r=anim(rot(rel), times)),
                   "shapes": [shape(colour)]}
            out.append(lay)
            par = None  # resolved when added
            parent_abs = absolute
            pos = [s(length), 0]
        return out

    def colour_for(key, side):
        on = key in active
        if side == "f":
            return ACTIVE_FAR if on else BODY_FAR
        return ACTIVE if on else BODY

    # Ordered drawing: far arm, far leg, torso+head, near leg, near arm.
    def add_chain(chain, first_parent):
        prev = first_parent
        for lay in chain:
            lay["parent"] = prev
            prev = add_layer(lay)
        return prev

    lat = (lambda side, amount: (amount if side == "n" else -amount)) if view == "front" else (lambda side, amount: 0)

    def arm_chain(side):
        lim = (lambda p: p.arm_n) if side == "n" else (lambda p: p.arm_f)
        key = f"arm_{side}" if f"arm_{side}" in active else ("arms" if "arms" in active else "_")
        return limb_chain("arm" + side, side, None, torso_abs,
                          [s(L['torso'] * SHOULDER_AT), s(lat(side, FRONT_SHOULDER))],
                          [("upper", lambda p: lim(p).a1, L['uarm'], lambda c: capsule(s(L['uarm']), s(T['uarm']), c, "upper", s(TE['uarm']))),
                           ("fore", lambda p: lim(p).a2, L['farm'], lambda c: capsule(s(L['farm']), s(T['farm']), c, "fore", s(TE['farm']))),
                           ("hand", lambda p: lim(p).a3, L['hand'], lambda c: capsule(s(L['hand']), s(T['hand']), c, "hand", s(TE['hand'])))],
                          None, key)

    def leg_chain(side):
        lim = (lambda p: p.leg_n) if side == "n" else (lambda p: p.leg_f)
        key = f"leg_{side}" if f"leg_{side}" in active else ("legs" if "legs" in active else "_")
        foot_shape = lambda c: group([rect(s(0.04), s(L['heel']) * 0.45, s(L['foot']) + s(0.03), s(L['heel']) * 1.5 + s(0.012),
                                           s(0.02))], c, "foot")
        return limb_chain("leg" + side, side, None, [0.0] * len(poses),
                          [0, s(lat(side, FRONT_HIP))],
                          [("thigh", lambda p: lim(p).a1, L['thigh'], lambda c: capsule(s(L['thigh']), s(T['thigh']), c, "thigh", s(TE['thigh']))),
                           ("shin", lambda p: lim(p).a2, L['shin'], lambda c: capsule(s(L['shin']), s(T['shin']), c, "shin", s(TE['shin']))),
                           ("foot", lambda p: lim(p).a3, L['foot'], foot_shape)],
                          None, key)

    # The foot's rotation is relative to the shin's, but its shape should be drawn level with
    # the sole when the foot angle is 0, so its getter returns the absolute foot direction.

    torso_colour = ACTIVE if ("torso" in active or "core" in active) else BODY
    torso_layer = {"ty": 4, "nm": "torso", "parent": pelvis, "ks": ks(r=anim(rot(torso_abs), times)),
                   "shapes": [torso_shape(s, torso_colour, view)]}
    head_abs = unwrap([p.head for p in poses])
    head_layer = {"ty": 4, "nm": "head", "ks": ks(p=static([s(L['torso']), 0, 0]),
                                                  r=anim(rot([h - t for h, t in zip(head_abs, torso_abs)]), times)),
                  "shapes": [group([rect(s(L['neck']) / 2, 0, s(L['neck']) + s(0.02), s(T['neck']), s(0.02)),
                                    ellipse(s(L['neck'] + L['head'] / 2), 0, s(L['head']), s(L['head']) * 1.05)], BODY, "head")]}

    # Props sit behind everything.
    for prop in props:
        add_layer(prop_layer(prop, cam))
    add_chain(arm_chain("f"), None)
    add_chain(leg_chain("f"), pelvis)
    torso_ind = add_layer(torso_layer)
    head_layer["parent"] = torso_ind
    add_layer(head_layer)
    add_chain(leg_chain("n"), pelvis)
    add_chain(arm_chain("n"), None)

    # Arm chains hang off the torso: fix their first parent now that the torso exists.
    for lay in layers:
        if lay["nm"] in ("armf_upper", "armn_upper"):
            lay["parent"] = torso_ind
    # Far arm was added before the torso; Lottie allows any order for parenting.

    return {"v": "5.7.4", "fr": FPS, "ip": 0, "op": frames, "w": W, "h": H, "nm": name, "ddd": 0,
            "assets": [], "layers": list(reversed(layers))}


def torso_shape(s, colour, view):
    """Pelvis, waist and rib cage along the torso (+x from hip to neck). In the side view the
    chest is deeper toward the front (local -y, which faces forward when the figure faces right)."""
    Lt = s(L['torso'])
    if view == "front":
        return group([ellipse(s(0.02), 0, s(0.13), s(0.16)), rect(Lt * 0.45, 0, Lt * 0.55, s(0.13), s(0.04)),
                      ellipse(Lt * 0.78, 0, Lt * 0.5, s(0.19))], colour, "torso")
    return group([ellipse(s(0.025), s(0.006), s(0.13), s(0.115)),            # pelvis
                  path([(s(0.02), -s(0.05)), (Lt * 0.55, -s(0.046)), (Lt * 0.55, s(0.046)), (s(0.02), s(0.052))]),  # waist
                  ellipse(Lt * 0.74, -s(0.008), Lt * 0.62, s(0.122)),         # rib cage
                  ellipse(Lt * 0.94, s(0.004), s(0.07), s(0.085))],           # shoulder
                 colour, "torso")


def prop_layer(prop: dict, cam: Camera) -> dict:
    kind = prop["kind"]
    shapes = []
    s = cam.len
    if kind == "floor":
        y = cam.pt((0, 0))[1]
        shapes.append(group([rect(W / 2, y + s(0.012), W * 1.2, s(0.024), 0)], FLOOR, "floor"))
    elif kind == "bar":          # pull-up bar at world (x, y)
        p = cam.pt(prop["at"])
        # The bar end-on, and the frame it hangs from running back and up.
        shapes.append(group([rect(p[0] - s(0.32), p[1] - s(0.0), s(0.64), s(0.022), s(0.011))], FLOOR, "frame"))
        shapes.append(group([ellipse(p[0], p[1], s(0.05), s(0.05))], PROP, "bar"))
    elif kind == "box":          # bench / box: centre x, width, height
        x, w, h = prop["x"], prop["w"], prop["h"]
        c = cam.pt((x, h / 2))
        shapes.append(group([rect(c[0], c[1], s(w), s(h), s(0.015))], PROP, "box"))
    elif kind == "parallettes":  # dip bars: handle height h at x, with a post
        x, h = prop["x"], prop["h"]
        top = cam.pt((x, h))
        base = cam.pt((x, 0))
        shapes.append(group([rect(top[0], (top[1] + base[1]) / 2, s(0.022), base[1] - top[1], s(0.01))], PROP, "post"))
        shapes.append(group([rect(top[0], top[1], s(0.30), s(0.03), s(0.015))], PROP, "handle"))
    elif kind == "wall":
        x = prop["x"]
        c = cam.pt((x, 0.6))
        shapes.append(group([rect(c[0] + s(0.03), c[1], s(0.06), s(1.4), 0)], PROP, "wall"))
    return {"ty": 4, "nm": f"prop-{kind}", "ks": ks(), "shapes": shapes}


def frame_camera(poses: list[Pose], props: list[dict], scale: float = 420) -> Camera:
    xs, ys = [], [0.0]
    for p in poses:
        for q in (p.hip, p.head_center(), p.wrist('n'), p.wrist('f'), p.ankle('n'), p.ankle('f'), p.elbow('n'), p.knee('n')):
            xs.append(q[0]); ys.append(q[1])
    for prop in props:
        if prop["kind"] == "bar":
            xs.append(prop["at"][0]); ys.append(prop["at"][1])
        if prop["kind"] == "box":
            xs += [prop["x"] - prop["w"] / 2, prop["x"] + prop["w"] / 2]; ys.append(prop["h"])
    pad = 0.12
    span_x = max(xs) - min(xs) + 2 * pad
    span_y = max(ys) - min(ys) + 2 * pad
    sc = min(scale, (W - 40) / span_x, (H - 40) / span_y)
    cx = (max(xs) + min(xs)) / 2
    # The figure (and its props) centred vertically, the floor never above the middle.
    lo = min(ys) - 0.04
    hi = max(ys) + pad
    floor_y = H / 2 + ((hi + lo) / 2) * sc
    floor_y = max(H * 0.55, min(floor_y, H - 40))
    return Camera(cx, floor_y, sc)
