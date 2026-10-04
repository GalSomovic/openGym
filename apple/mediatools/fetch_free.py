#!/usr/bin/env python3
"""
Downloads free, openly licensed exercise media and prepares it for the app:
  apple/mediatools/fetch_free.py wger
Files go to apple/Media/Free/ (gitignored, bundled by Xcode); the index of options goes to
apple/App/GymFree/FreeMedia.json (committed), with licence and credit for each.
"""
import json
import os
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "Media", "Free")
INDEX = os.path.join(HERE, "..", "App", "GymFree", "FreeMedia.json")
UA = {"User-Agent": "GymFree/1.0 (open-source fitness app; https://github.com/GalSomovic/openGym)"}


FRESH = set()


def load_index():
    """The index so far; a source run with FRESH=1 first drops that source's own options."""
    ix = json.load(open(INDEX)) if os.path.exists(INDEX) else {}
    if os.environ.get("FRESH") == "1":
        for k in list(ix):
            ix[k] = [o for o in ix[k] if o["id"] in FRESH or not o["id"].startswith(CURRENT[0])]
            if not ix[k]:
                del ix[k]
    return ix


CURRENT = [""]


def save_index(ix):
    with open(INDEX, "w") as f:
        json.dump(ix, f, indent=1, sort_keys=True)


def download(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return path
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as r, open(path + ".part", "wb") as f:
        while chunk := r.read(1 << 16):
            f.write(chunk)
    os.rename(path + ".part", path)
    time.sleep(0.4)
    return path


def to_video(src, dst, start=0.0, length=None, crop=None):
    """H.264, 540 px tall, no audio, at most 12 s: small, plays everywhere, loops cleanly.
    crop: an ffmpeg crop expression (w:h:x:y) applied first, to frame the person."""
    if os.path.exists(dst):
        return dst
    cmd = ["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-i", src]
    if length:
        cmd += ["-t", str(length)]
    else:
        cmd += ["-t", "12"]
    vf = (f"crop={crop}," if crop else "") + "scale=-2:540:flags=lanczos,fps=30"
    cmd += ["-vf", vf, "-an", "-c:v", "libx264", "-preset", "slow", "-crf", "26",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", dst]
    subprocess.run(cmd, check=True)
    return dst


def to_image(src, dst):
    """JPEG, at most 720 px on the long side (macOS sips reads WebP, PNG, GIF, JPEG)."""
    if os.path.exists(dst):
        return dst
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "80", "-Z", "720", src, "--out", dst],
                   check=True, capture_output=True)
    return dst


# Rejected on review: logos, other apps' watermarks or screenshots, likely AI-generated art.
BLOCKED = {"wger-i1573", "wger-i2529", "wger-i984", "wger-i1551", "wger-i1554", "wger-i1572",
           "wger-i507", "wger-i301", "wger-i265", "wger-i1307",
           # Marine Corps clips whose busiest window misses the move, or where the person is tiny.
           "tecom-679638", "tecom-639937", "tecom-549334", "tecom-679688", "tecom-640257",
           "tecom-548828", "tecom-551148"}


def add_option(ix, exercise_id, option):
    if option["id"] in BLOCKED:
        return
    opts = ix.setdefault(exercise_id, [])
    if not any(o["id"] == option["id"] for o in opts):
        opts.append(option)


def wger():
    CURRENT[0] = "wger-"
    sys.path.insert(0, HERE)
    from wger_map import WGER_TO_OPENGYM
    data = {e["id"]: e for e in json.load(open(os.path.join(HERE, "wger.json")))}
    raw = os.path.join(OUT, "..", "_raw", "wger")
    os.makedirs(raw, exist_ok=True)
    os.makedirs(os.path.join(OUT, "wger"), exist_ok=True)
    ix = load_index()
    for wid, targets in WGER_TO_OPENGYM.items():
        e = data.get(wid)
        if not e:
            continue
        for n, v in enumerate(e["videos"]):
            ext = os.path.splitext(v["url"])[1] or ".mp4"
            src = download(v["url"], os.path.join(raw, f"v{wid}-{n}{ext}"))
            name = f"wger-v{wid}-{n}.mp4"
            to_video(src, os.path.join(OUT, "wger", name))
            for t in targets:
                add_option(ix, t, {"id": f"wger-v{wid}-{n}", "kind": "video", "files": [f"wger/{name}"],
                                   "source": "wger", "title": e["name"], "license": v["license"], "author": v["author"],
                                   "link": f"https://wger.de/exercise/{wid}/view/"})
        imgs = sorted(e["images"], key=lambda x: not x.get("main"))
        if imgs:
            files = []
            for n, im in enumerate(imgs[:2]):
                ext = os.path.splitext(im["url"])[1].lower() or ".png"
                src = download(im["url"], os.path.join(raw, f"i{wid}-{n}{ext}"))
                name = f"wger-i{wid}-{n}.jpg"
                to_image(src, os.path.join(OUT, "wger", name))
                files.append(f"wger/{name}")
            authors = sorted({im["author"] for im in imgs[:2]})
            licenses = sorted({im["license"] for im in imgs[:2] if im["license"]})
            for t in targets:
                add_option(ix, t, {"id": f"wger-i{wid}", "kind": "images", "files": files, "source": "wger",
                                   "title": e["name"], "license": ", ".join(licenses), "author": ", ".join(authors),
                                   "link": f"https://wger.de/exercise/{wid}/view/"})
        print("wger", wid, e["name"], "->", ",".join(targets), f"{len(e['videos'])}v {len(imgs[:2])}i", flush=True)
    save_index(ix)


# Wikimedia Commons files -> openGym ids. The Wensceslao set is traced from real video
# (CC BY-SA 4.0); the US Army clips are public domain (works of the US government).
COMMONS = {
    "Pushups.gif": ["0662"], "Squats.gif": ["gf-squat"], "Situps.gif": ["0735", "3679"], "Burpees.gif": ["1160"],
    "Jumpingjacks.gif": ["gf-jumping-jack", "3224"], "Legraises.gif": ["gf-lying-leg-raise"], "High_knees.gif": ["gf-high-knees"],
    "Touchankles.gif": ["3212"], "Plank.png": ["gf-plank"], "Jumpingrope.gif": ["2612"],
    "Conditioning_Drill_1-_Power_Jump.webm": ["0514"],
    "Conditioning_Drill-_Eight_Count_T_Push-Up.webm": ["0664"],
    "Strength_Training_Circuit-_Forward_Lunge.webm": ["3470"],
}


def commons_info(title):
    import urllib.parse
    url = ("https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|mime|extmetadata&format=json&titles="
           + urllib.parse.quote("File:" + title))
    req = urllib.request.Request(url, headers=UA)
    page = next(iter(json.load(urllib.request.urlopen(req, timeout=60))["query"]["pages"].values()))
    info = page["imageinfo"][0]
    meta = info.get("extmetadata", {})
    strip = lambda h: __import__("re").sub("<[^>]+>", "", h or "").strip()
    return {"url": info["url"], "mime": info["mime"], "license": strip(meta.get("LicenseShortName", {}).get("value")),
            "author": strip(meta.get("Artist", {}).get("value")) or "Wikimedia Commons",
            "link": info.get("descriptionurl") or f"https://commons.wikimedia.org/wiki/File:{title}"}


def commons():
    CURRENT[0] = "commons-"
    raw = os.path.join(OUT, "..", "_raw", "commons")
    os.makedirs(raw, exist_ok=True)
    os.makedirs(os.path.join(OUT, "commons"), exist_ok=True)
    ix = load_index()
    for title, targets in COMMONS.items():
        info = commons_info(title)
        base = os.path.splitext(title)[0].replace(" ", "_")
        src = download(info["url"], os.path.join(raw, title))
        if info["mime"].startswith("image/") and not title.lower().endswith(".gif"):
            name = f"commons-{base}.jpg"
            to_image(src, os.path.join(OUT, "commons", name))
            kind = "images"
        else:
            name = f"commons-{base}.mp4"
            to_video(src, os.path.join(OUT, "commons", name))
            kind = "video"
        for t in targets:
            add_option(ix, t, {"id": f"commons-{base}", "kind": kind, "files": [f"commons/{name}"], "source": "Wikimedia Commons",
                               "title": base.replace("_", " "), "license": info["license"], "author": info["author"], "link": info["link"]})
        print("commons", title, "->", ",".join(targets), info["license"], "|", info["author"][:40], flush=True)
    save_index(ix)


# Feeel (AGPL workout app) exercise images, CC BY-SA 4.0, slug -> openGym ids.
FEEEL = {
    "pushUps": ["0662"], "squats": ["gf-squat"], "pullUps": ["0652"], "lunges": ["3470"], "reverseLunges": ["gf-reverse-lunge"],
    "splitSquats": ["2368"], "bulgarianSplitSquats": ["gf-bulgarian-split-squat"], "pistolSquats": ["1759", "1476"],
    "pikePushUps": ["gf-pike-push-up"], "floorDips": ["0815", "1399"], "tricepsDips": ["0812", "0129"],
    "forearmPlank": ["gf-plank"], "sidePlank": ["gf-side-plank"], "mountainClimbers": ["0630"],
    "legRaises": ["gf-lying-leg-raise"], "jumpingJacks": ["gf-jumping-jack"], "highKnees": ["gf-high-knees"],
    "fourCountBurpees": ["1160"], "noPushUpBurpees": ["1160"], "abCrunches": ["0274"], "wallSit": ["gf-wall-sit"],
    "stepUps": ["gf-step-up"], "singleLegCalfRaises": ["1387"], "jumpRopeBasic": ["2612"], "pushUpRotations": ["0664"],
}


def feeel(repo):
    CURRENT[0] = "feeel-"
    from PIL import Image
    import re
    meta = {e["imageSlug"]: e for e in json.load(open(os.path.join(repo, "assets/json_supplements/local_exercise_images.json")))["exercises"]}
    os.makedirs(os.path.join(OUT, "feeel"), exist_ok=True)
    ix = load_index()
    for slug, targets in FEEEL.items():
        src = os.path.join(repo, "assets/exercise_images", slug + ".webp")
        if not os.path.exists(src):
            continue
        im = Image.open(src)
        files = []
        # Each frame is a full picture on a transparent background: put it on a dark one
        # (converting transparent pixels straight to RGB leaves garbage stripes).
        for n in range(getattr(im, "n_frames", 1)):
            im.seek(n)
            canvas = Image.new("RGBA", im.size, (14, 16, 19, 255))
            canvas.alpha_composite(im.convert("RGBA"))
            frame = canvas.convert("RGB")
            frame.thumbnail((720, 720), Image.LANCZOS)
            name = f"feeel-{slug}-{n}.jpg"
            frame.save(os.path.join(OUT, "feeel", name), quality=82)
            files.append(f"feeel/{name}")
        credit = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", meta.get(slug, {}).get("license", "Feeel contributors, CC BY-SA 4.0"))
        for t in targets:
            add_option(ix, t, {"id": f"feeel-{slug}", "kind": "images", "files": files, "source": "Feeel",
                               "title": re.sub(r"(?<!^)([A-Z])", r" \1", slug).capitalize(), "license": "CC BY-SA 4.0",
                               "author": credit, "link": "https://gitlab.com/enjoyingfoss/feeel"})
        print("feeel", slug, len(files), "frames ->", ",".join(targets), flush=True)
    save_index(ix)


# Pixabay videos picked by hand (Pixabay Content License: free to use, no attribution
# required; credited anyway). id: (openGym ids, start, length, crop)
PIXABAY = {
    13134: (["0662"], 2.0, 9.0, None),
    330871: (["0662"], 0.0, 9.0, "iw*0.52:ih*0.52:iw*0.18:ih*0.40"),
}


def pixabay():
    CURRENT[0] = "pixabay-"
    cands = {c["id"]: c for c in json.load(open(os.path.join(HERE, "pixabay-filtered.json")))}
    raw = os.path.join(OUT, "..", "_raw", "pixabay")
    os.makedirs(os.path.join(OUT, "pixabay"), exist_ok=True)
    ix = load_index()
    for pid, (targets, start, length, crop) in PIXABAY.items():
        c = cands[pid]
        src = os.path.join(raw, f"{pid}.mp4")
        name = f"pixabay-{pid}.mp4"
        to_video(src, os.path.join(OUT, "pixabay", name), start, length, crop)
        for t in targets:
            add_option(ix, t, {"id": f"pixabay-{pid}", "kind": "video", "files": [f"pixabay/{name}"], "source": "Pixabay",
                               "title": c["tags"].split(",")[0], "license": "Pixabay Content License", "author": c["user"],
                               "link": c["page"]})
        print("pixabay", pid, "->", ",".join(targets), flush=True)
    save_index(ix)


# DVIDS (US military media, public domain). video id -> [(openGym ids, start, length, crop)].
# Segments and crops picked from contact sheets (dvids.py preview/zoom); crops keep on-screen
# text out of the frame.
TEXT_FREE = "iw*0.84:ih*0.58:iw*0.08:ih*0.41"
DVIDS = {
    "video:1016258": [(["0662"], 34.5, 5.4, None)],                                   # Culture of Fitness: Push Ups
    "video:1016260": [(["gf-hand-release-push-up"], 64.0, 7.0, TEXT_FREE)],           # Hand Release Push Up
    "video:1016256": [(["3679", "0735"], 54.0, 3.6, TEXT_FREE)],                       # Sit Ups (arms crossed)
    "video:1016254": [(["0871"], 36.0, 8.0, TEXT_FREE)],                               # Cross Leg Crunch
    "video:1017408": [(["0652"], 26.7, 4.3, None)],                                    # Get Fit: Proper Pull-Up
    "video:1003262": [(["gf-step-up"], 37.0, 7.0, None)],                              # Get Fit: Proper Step-Up
    "video:695517": [(["0472"], 78.0, 10.0, None)],                                    # ACFT: Leg Tuck
    "video:840093": [(["gf-plank"], 5.5, 3.4, None),                                  # ACFT Prep: Plank
                     (["0872"], 32.0, 6.0, "iw:ih*0.8:0:0"),                           #   bent-leg raise
                     (["gf-side-plank"], 43.0, 2.6, "iw:ih*0.8:0:0")],                 #   side bridge
}


def dvids():
    CURRENT[0] = "dvids-"
    sys.path.insert(0, HERE)
    import dvids as D
    raw = os.path.join(OUT, "..", "_raw", "dvids")
    os.makedirs(os.path.join(OUT, "dvids"), exist_ok=True)
    ix = load_index()
    for vid, cuts in DVIDS.items():
        a = D.asset(vid)
        f = D.file_for(a, 720)
        src = D.download(f["src"], os.path.join(raw, f"{vid.replace(':', '_')}-{f['height']}.mp4"))
        people = ", ".join(" ".join(x for x in (c.get("rank"), c.get("name")) if x) for c in a.get("credit", []) or [])
        author = f"{people} / DVIDS" if people else "DVIDS"
        for n, (targets, start, length, crop) in enumerate(cuts):
            oid = f"dvids-{vid.split(':')[1]}-{n}"
            name = f"{oid}.mp4"
            to_video(src, os.path.join(OUT, "dvids", name), start, length, crop)
            for t in targets:
                add_option(ix, t, {"id": oid, "kind": "video", "files": [f"dvids/{name}"], "source": "DVIDS",
                                   "title": a.get("title", ""), "license": "Public domain (US DoD)", "author": author,
                                   "link": f"https://www.dvidshub.net/video/{vid.split(':')[1]}"})
        print("dvids", vid, a.get("title"), "->", [c[0] for c in cuts], flush=True)
    save_index(ix)


def analyse(src, max_len=8.0):
    """
    Where to cut a clip: the most active `max_len` seconds (frame-to-frame motion), and a crop
    for the Marine Corps library layout (two stacked camera views inside black side bars, with a
    label box): the content columns and the lower view.
    """
    import numpy as np
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height:format=duration",
                            "-of", "json", src], capture_output=True, text=True)
    info = json.loads(probe.stdout)
    w, h = info["streams"][0]["width"], info["streams"][0]["height"]
    dur = float(info["format"]["duration"])
    sw, sh, fps = 160, int(160 * h / w) // 2 * 2, 4
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vf", f"fps={fps},scale={sw}:{sh},format=gray", "-f", "rawvideo", "-"],
                         capture_output=True).stdout
    frames = np.frombuffer(raw, np.uint8).reshape(-1, sh, sw).astype(np.int16)
    crop = None
    mean = frames.mean(axis=0)
    cols = mean.mean(axis=0)
    if cols[: sw // 6].mean() < 14 and cols[-sw // 6:].mean() < 14:
        lit = np.where(cols > 20)[0]
        # The label box sits in the left bar; the content is the widest lit run.
        runs, start = [], lit[0]
        for a, b in zip(lit, lit[1:]):
            if b != a + 1:
                runs.append((start, a)); start = b
        runs.append((start, lit[-1]))
        x0, x1 = max(runs, key=lambda r: r[1] - r[0])
        x0f, x1f = (x0 + 1) / sw, (x1 - 1) / sw
        crop = f"iw*{x1f - x0f:.3f}:ih*0.5:iw*{x0f:.3f}:ih*0.5"
        frames = frames[:, sh // 2:, x0:x1]
    else:
        # Older clips: 4:3 inside black bars above and below. Keep only the picture.
        rows = mean.mean(axis=1)
        lit = np.where(rows > 24)[0]   # video black is 16
        if len(lit) and (lit[0] > sh // 20 or lit[-1] < sh - sh // 20):
            y0f, y1f = (lit[0] + 1) / sh, lit[-1] / sh
            crop = f"iw:ih*{y1f - y0f:.3f}:0:ih*{y0f:.3f}"
            frames = frames[:, lit[0]:lit[-1]]
    motion = np.abs(np.diff(frames, axis=0)).mean(axis=(1, 2)) if len(frames) > 1 else np.zeros(1)
    win = int(max_len * fps)
    if dur <= max_len + 0.5 or len(motion) <= win:
        return 0.0, min(dur, max_len + 0.5), crop
    sums = np.convolve(motion, np.ones(win), "valid")
    best = int(np.argmax(sums))
    return best / fps, max_len, crop


def tecom():
    CURRENT[0] = "tecom-"
    sys.path.insert(0, HERE)
    import dvids as D
    from tecom_map import TECOM_TO_OPENGYM, OTHER_VIDEOS
    titles = {x["name"]: x for x in json.load(open(os.path.join(HERE, "tecom-titles.json")))}
    raw = os.path.join(OUT, "..", "_raw", "dvids")
    os.makedirs(os.path.join(OUT, "tecom"), exist_ok=True)
    ix = load_index()
    for title, targets in TECOM_TO_OPENGYM.items():
        t = titles.get(title)
        if not t:
            print("missing title", title); continue
        vid = t["id"]
        a = D.asset(vid)
        f = D.file_for(a, 720)
        if not f:
            print("no file", title); continue
        oid = f"tecom-{vid.split(':')[1]}"
        if oid in BLOCKED:
            continue
        src = D.download(f["src"], os.path.join(raw, f"{vid.replace(':', '_')}-{f['height']}.mp4"))
        name = f"{oid}.mp4"
        dst = os.path.join(OUT, "tecom", name)
        if not os.path.exists(dst):
            start, length, crop = analyse(src)
            to_video(src, dst, start, length, crop)
        for tg in targets:
            add_option(ix, tg, {"id": oid, "kind": "video", "files": [f"tecom/{name}"], "source": "DVIDS",
                                "title": title, "license": "Public domain (US DoD)",
                                "author": "U.S. Marine Corps Training and Education Command / DVIDS",
                                "link": f"https://www.dvidshub.net/video/{vid.split(':')[1]}"})
        print("tecom", title, "->", ",".join(targets), flush=True)
    for vid, (title, targets, (start, length)) in OTHER_VIDEOS.items():
        a = D.asset(vid)
        f = D.file_for(a, 720)
        src = D.download(f["src"], os.path.join(raw, f"{vid.replace(':', '_')}-{f['height']}.mp4"))
        oid = f"tecom-{vid.split(':')[1]}"
        name = f"{oid}.mp4"
        to_video(src, os.path.join(OUT, "tecom", name), start, length)
        for tg in targets:
            add_option(ix, tg, {"id": oid, "kind": "video", "files": [f"tecom/{name}"], "source": "DVIDS",
                                "title": title, "license": "Public domain (US DoD)",
                                "author": a.get("unit_name") or "U.S. Marine Corps / DVIDS",
                                "link": f"https://www.dvidshub.net/video/{vid.split(':')[1]}"})
        print("dvids", title, "->", ",".join(targets), flush=True)
    save_index(ix)
    used = {f for opts in ix.values() for o in opts for f in o["files"]}
    for name in os.listdir(os.path.join(OUT, "tecom")):
        if f"tecom/{name}" not in used:
            os.remove(os.path.join(OUT, "tecom", name))


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "feeel":
        feeel(sys.argv[2])
    else:
        {"wger": wger, "commons": commons, "pixabay": pixabay, "dvids": dvids, "tecom": tecom}[cmd]()
