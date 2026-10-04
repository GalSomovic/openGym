#!/usr/bin/env python3
"""
DVIDS (US military media, public domain) through its API:
  dvids.py search "query" ...      list short videos
  dvids.py preview VIDEO_ID ...    download a small copy and a timestamped contact sheet
The public key is read from KEYFILE (env DVIDS_KEYFILE) and never printed.
"""
import json, os, subprocess, sys, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "Media", "_raw", "dvids")
KEYFILE = os.environ.get("DVIDS_KEYFILE", os.path.expanduser("~/claude-temp/army.api"))
UA = {"User-Agent": "GymFree/1.0 (open-source fitness app)"}


def key():
    return open(KEYFILE).read().split("\n")[0].strip()


def api(path, **q):
    q["api_key"] = key()
    url = f"https://api.dvidshub.net/{path}?" + urllib.parse.urlencode(q)
    for attempt in range(3):
        try:
            return json.load(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60))
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(5 * (attempt + 1)); continue
            sys.stderr.write(f"dvids {path}: HTTP {e.code}\n")
            return {}
    return {}


def asset(vid):
    cache = os.path.join(RAW, f"{vid.replace(':', '_')}.json")
    if os.path.exists(cache):
        return json.load(open(cache))
    a = api("asset", id=vid).get("results", {})
    os.makedirs(RAW, exist_ok=True)
    json.dump(a, open(cache, "w"))
    time.sleep(0.4)
    return a


def file_for(a, max_h):
    files = [f for f in a.get("files", []) if f.get("type") == "video/mp4" and f.get("height")]
    files.sort(key=lambda f: f["height"])
    fit = [f for f in files if f["height"] <= max_h]
    return (fit[-1] if fit else files[0]) if files else None


def download(url, path):
    if not os.path.exists(path):
        open(path + ".part", "wb").write(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=300).read())
        os.rename(path + ".part", path)
    return path


def contact(src, sheet, step=2, start=0, end=None):
    """Frames every `step` seconds with their time, 8 to a row."""
    import tempfile, glob
    from PIL import Image, ImageDraw
    tmp = tempfile.mkdtemp()
    cmd = ["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-i", src]
    if end:
        cmd += ["-t", str(end - start)]
    subprocess.run(cmd + ["-vf", f"fps=1/{step},scale=240:-1", os.path.join(tmp, "%04d.jpg")])
    frames = sorted(glob.glob(os.path.join(tmp, "*.jpg")))
    if not frames:
        return
    w, h = Image.open(frames[0]).size
    rows = (len(frames) + 7) // 8
    out = Image.new("RGB", (8 * w, rows * h), (0, 0, 0))
    d = ImageDraw.Draw(out)
    for i, f in enumerate(frames):
        x, y = (i % 8) * w, (i // 8) * h
        out.paste(Image.open(f), (x, y))
        t = start + i * step
        d.rectangle((x, y, x + 46, y + 14), fill=(0, 0, 0))
        d.text((x + 3, y + 1), f"{int(t // 60)}:{int(t % 60):02d}", fill=(255, 255, 0))
    out.save(sheet)


def search(queries):
    for q in queries:
        r = api("search", q=q, type="video", max_results=50)
        res = [x for x in r.get("results", []) if (x.get("duration") or 999) <= 300]
        print(f"\n== {q}: {r.get('page_info', {}).get('total_results')} total")
        for x in res:
            print(f"  {x['id']} | {x['title'][:80]} | {x.get('duration')}s | {x.get('branch')}")
        time.sleep(0.5)


def preview(ids, out):
    os.makedirs(out, exist_ok=True)
    for vid in ids:
        a = asset(vid)
        f = file_for(a, 360)
        if not f:
            print(vid, "no mp4"); continue
        src = download(f["src"], os.path.join(RAW, f"{vid.replace(':', '_')}-{f['height']}.mp4"))
        sheet = os.path.join(out, f"{vid.replace(':', '_')}.png")
        contact(src, sheet, step=2)
        print(vid, a.get("title"), a.get("duration"), "->", sheet)


if __name__ == "__main__":
    if sys.argv[1] == "search":
        search(sys.argv[2:])
    elif sys.argv[1] == "preview":
        preview(sys.argv[3:], sys.argv[2])
    elif sys.argv[1] == "zoom":   # zoom VIDEO_ID OUT START END STEP: a closer look at one stretch
        vid, out, a, b, st = sys.argv[2], sys.argv[3], float(sys.argv[4]), float(sys.argv[5]), float(sys.argv[6])
        f = file_for(asset(vid), 360)
        src = os.path.join(RAW, f"{vid.replace(':', '_')}-{f['height']}.mp4")
        contact(src, out, step=st, start=a, end=b)
