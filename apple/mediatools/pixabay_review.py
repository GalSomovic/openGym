#!/usr/bin/env python3
"""Filters Pixabay candidates by their tags and makes thumbnail sheets for picking by eye."""
import json, os, sys, urllib.request, io
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
WORDS = {
    "push up exercise": ["push"], "pull up bar": ["pull"], "chin up": ["chin", "pull"], "bodyweight squat": ["squat"],
    "lunges exercise": ["lunge"], "plank exercise": ["plank"], "burpees": ["burpee"], "jumping jacks": ["jumping jack", "jack"],
    "mountain climbers exercise": ["mountain climber"], "sit ups": ["sit up", "sit-up", "situp"], "crunches abs": ["crunch"],
    "dips exercise": ["dip"], "bench dips": ["dip"], "glute bridge": ["bridge", "glute"], "jump squat": ["squat"],
    "high knees": ["knee"], "jump rope": ["rope", "skipping"], "handstand": ["handstand"], "handstand push up": ["handstand"],
    "pistol squat": ["pistol"], "muscle up": ["muscle up", "muscle-up"], "leg raises": ["leg raise", "leg lift"],
    "hanging leg raise": ["hanging"], "russian twist": ["twist"], "side plank": ["side plank"], "calf raises": ["calf"],
    "wall sit": ["wall sit"], "step ups exercise": ["step"], "inverted row": ["row"], "bicycle crunches": ["bicycle crunch"],
    "flutter kicks": ["flutter", "kick"], "l-sit": ["l-sit", "l sit"], "front lever": ["lever"], "diamond push up": ["push"],
    "incline push up": ["push"], "v-ups": ["v-up", "v up"], "bear crawl": ["bear crawl", "crawl"], "inchworm exercise": ["inchworm"],
    "split squat": ["squat"], "street workout": ["pull", "push", "dip", "bar"],
}
cands = json.load(open(os.path.join(HERE, "pixabay-candidates.json")))
keep, seen = [], set()
for c in cands:
    tags = c["tags"].lower()
    if any(w in tags for w in WORDS.get(c["q"], [])) and (c["q"], c["id"]) not in seen:
        seen.add((c["q"], c["id"]))
        keep.append(c)
json.dump(keep, open(os.path.join(HERE, "pixabay-filtered.json"), "w"), indent=1)
print(len(keep), "after tag filter")
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
cell = (256, 170)
per_sheet = 48
for s in range(0, len(keep), per_sheet):
    chunk = keep[s:s + per_sheet]
    sheet = Image.new("RGB", (cell[0] * 6, (cell[1] + 28) * ((len(chunk) + 5) // 6)), (15, 15, 15))
    d = ImageDraw.Draw(sheet)
    for i, c in enumerate(chunk):
        x, y = (i % 6) * cell[0], (i // 6) * (cell[1] + 28)
        try:
            data = urllib.request.urlopen(urllib.request.Request(c["thumb"], headers={"User-Agent": "GymFree/1.0"}), timeout=30).read()
            im = Image.open(io.BytesIO(data)).convert("RGB"); im.thumbnail(cell)
            sheet.paste(im, (x, y))
        except Exception:
            pass
        d.text((x + 3, y + cell[1] + 2), f"#{s + i} {c['q'][:18]} {c['duration']}s", fill=(255, 255, 0))
        d.text((x + 3, y + cell[1] + 14), c["tags"][:40], fill=(200, 200, 200))
    sheet.save(os.path.join(out, f"px-{s // per_sheet + 1}.png"))
print("sheets:", (len(keep) + per_sheet - 1) // per_sheet)
