#!/usr/bin/env python3
"""
Renders the built Lottie files with lottie-web (the reference player) into contact sheets:
apple/anim/preview.py OUT_DIR [id ...]   one row of frames per exercise.
"""
import io
import json
import os
import sys

from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright

ANIM = os.path.join(os.path.dirname(__file__), "..", "App", "GymFree", "Animations")
PAGE = """<!doctype html><html><body style="margin:0;background:#1B1F24">
<div id="a" style="width:300px;height:300px"></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>
<script>
window.load = (data) => new Promise(r => {
  document.getElementById('a').innerHTML = '';
  window.anim = lottie.loadAnimation({container: document.getElementById('a'), renderer: 'svg', loop: false, autoplay: false, animationData: data});
  window.anim.addEventListener('DOMLoaded', () => r(window.anim.totalFrames));
});
</script></body></html>"""


def main(out, ids, frames_per_row=int(os.environ.get('FRAMES', 8))):
    os.makedirs(out, exist_ok=True)
    files = sorted(f for f in os.listdir(ANIM) if f.endswith(".json") and f != "manifest.json")
    if ids:
        files = [f for f in files if f[:-5] in ids]
    rows = []
    with sync_playwright() as pw:
        b = pw.chromium.launch()
        page = b.new_page(viewport={"width": 300, "height": 300})
        page.set_content(PAGE)
        page.wait_for_function("window.lottie !== undefined")
        for f in files:
            data = json.load(open(os.path.join(ANIM, f)))
            total = page.evaluate("d => window.load(d)", data)
            row = []
            for i in range(frames_per_row):
                fr = int(total * i / frames_per_row)
                page.evaluate(f"window.anim.goToAndStop({fr}, true)")
                row.append(Image.open(io.BytesIO(page.screenshot())).convert("RGB"))
            rows.append((f[:-5] + " " + data["nm"], row))
        b.close()
    sheet = Image.new("RGB", (300 * frames_per_row, 330 * len(rows)), (10, 10, 10))
    d = ImageDraw.Draw(sheet)
    for r, (label, row) in enumerate(rows):
        d.text((8, r * 330 + 6), label, fill=(255, 255, 255))
        for c, im in enumerate(row):
            sheet.paste(im, (c * 300, r * 330 + 26))
    path = os.path.join(out, "sheet.png")
    sheet.save(path)
    print(path)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
