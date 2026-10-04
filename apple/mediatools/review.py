#!/usr/bin/env python3
"""Contact sheets of every free media option: review.py OUT_DIR -> sheet-N.png (3 frames each)."""
import json, os, subprocess, sys, tempfile
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
FREE = os.path.join(HERE, "..", "Media", "Free")
ix = json.load(open(os.path.join(HERE, "..", "App", "GymFree", "FreeMedia.json")))
names = json.loads(subprocess.run(["node", "-e", "import('../../frontend/src/lib/exercises-data.js').then(m=>import('../core/extras.js').then(x=>console.log(JSON.stringify(Object.fromEntries([...m.EXDB,...x.EXTRAS].map(e=>[e.id,e.n]))))))"],
                                  capture_output=True, text=True, cwd=HERE).stdout)
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
rows = []
for ex, opts in sorted(ix.items()):
    for o in opts:
        frames = []
        if o["kind"] == "video":
            path = os.path.join(FREE, o["files"][0])
            dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path], capture_output=True, text=True).stdout or 1)
            for k in (0.1, 0.45, 0.8):
                tmp = tempfile.mktemp(suffix=".jpg")
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(dur * k), "-i", path, "-frames:v", "1", tmp])
                if os.path.exists(tmp): frames.append(Image.open(tmp).convert("RGB"))
        else:
            fs = o["files"]
            for f in (fs[0], fs[len(fs) // 2], fs[-1]) if len(fs) > 1 else fs:
                frames.append(Image.open(os.path.join(FREE, f)).convert("RGB"))
        rows.append((f"{ex} {names.get(ex, '?')}  <=  {o['source']}: {o['title']} ({o['kind']}, {len(o['files'])})", frames))
per = 24
for s in range(0, len(rows), per):
    chunk = rows[s:s + per]
    sheet = Image.new("RGB", (3 * 220 + 340, len(chunk) * 170), (20, 20, 20))
    d = ImageDraw.Draw(sheet)
    for r, (label, frames) in enumerate(chunk):
        d.text((6, r * 170 + 6), label[:52], fill=(255, 255, 255))
        d.text((6, r * 170 + 22), label[52:104], fill=(200, 200, 200))
        for c, im in enumerate(frames[:3]):
            im.thumbnail((210, 160))
            sheet.paste(im, (340 + c * 220, r * 170 + 5))
    sheet.save(os.path.join(out, f"sheet-{s // per + 1}.png"))
print(len(rows), "options,", (len(rows) + per - 1) // per, "sheets")
