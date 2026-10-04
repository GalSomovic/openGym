#!/usr/bin/env python3
"""
Builds GymFree's exercise animations: apple/anim/build.py [id ...]
Writes apple/App/GymFree/Animations/<id>.json (Lottie) and a manifest.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from exercises import EXERCISES  # noqa: E402
from lottie_export import build, frame_camera  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "App", "GymFree", "Animations")
SAMPLES = 48


def props_of(ex):
    out = []
    for p in ex["props"]:
        if p == "floor":
            out.append({"kind": "floor"})
        elif p[0] == "bar":
            out.append({"kind": "bar", "at": p[1], "posts": len(p) > 2 and p[2] == "posts"})
        elif p[0] == "parallettes":
            out.append({"kind": "parallettes", "x": p[1], "h": p[2]})
        elif p[0] == "box":
            out.append({"kind": "box", "x": p[1], "w": p[2], "h": p[3]})
        elif p[0] == "wall":
            out.append({"kind": "wall", "x": p[1]})
    return out


def main(ids):
    os.makedirs(OUT, exist_ok=True)
    manifest = {}
    for id, ex in EXERCISES.items():
        if ids and id not in ids:
            continue
        poses = [ex["fn"](i / SAMPLES) for i in range(SAMPLES)]
        props = props_of(ex)
        cam = frame_camera(poses, props)
        doc = build(ex["name"], poses, ex["period"], ex["active"], props, cam, ex["view"])
        with open(os.path.join(OUT, f"{id}.json"), "w") as f:
            json.dump(doc, f, separators=(",", ":"))
        manifest[id] = {"name": ex["name"], "period": ex["period"]}
        print("built", id, ex["name"])
    if not ids:
        with open(os.path.join(OUT, "manifest.json"), "w") as f:
            json.dump(manifest, f, indent=1)


if __name__ == "__main__":
    main(sys.argv[1:])
