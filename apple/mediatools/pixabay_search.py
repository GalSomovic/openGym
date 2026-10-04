#!/usr/bin/env python3
"""
Searches Pixabay's video API for each exercise and saves the candidates for review:
  apple/mediatools/pixabay_search.py KEYFILE > pixabay-candidates.json
Responses are cached for 24 hours (Pixabay's API terms). The key is read from a file and is
never printed or written anywhere.
"""
import hashlib, json, os, sys, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "..", "Media", "_raw", "pixabay-cache")
TERMS = {
    "push up exercise": ["0662"], "pull up bar": ["0652"], "chin up": ["1326"], "bodyweight squat": ["gf-squat"],
    "lunges exercise": ["3470", "gf-reverse-lunge"], "plank exercise": ["gf-plank"], "burpees": ["1160"],
    "jumping jacks": ["gf-jumping-jack"], "mountain climbers exercise": ["0630"], "sit ups": ["0735"],
    "crunches abs": ["0274"], "dips exercise": ["0251", "0814"], "bench dips": ["0129"], "glute bridge": ["3013"],
    "jump squat": ["0514"], "high knees": ["gf-high-knees"], "jump rope": ["2612"], "handstand": ["3302"],
    "handstand push up": ["0471"], "pistol squat": ["1759"], "muscle up": ["0631"], "leg raises": ["gf-lying-leg-raise"],
    "hanging leg raise": ["0472"], "russian twist": ["0687"], "side plank": ["gf-side-plank"], "calf raises": ["1373"],
    "wall sit": ["gf-wall-sit"], "step ups exercise": ["gf-step-up"], "inverted row": ["0499"], "bicycle crunches": ["0003"],
    "flutter kicks": ["0459"], "l-sit": ["3419"], "front lever": ["3296"], "diamond push up": ["0283"],
    "incline push up": ["0493"], "v-ups": ["gf-v-up"], "bear crawl": ["3360"], "inchworm exercise": ["1471"],
    "split squat": ["2368"], "calisthenics": [], "street workout": [],
}


def get(key, q):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, hashlib.sha1(q.encode()).hexdigest() + ".json")
    if os.path.exists(path) and time.time() - os.path.getmtime(path) < 86400:
        return json.load(open(path))
    url = "https://pixabay.com/api/videos/?" + urllib.parse.urlencode({"key": key, "q": q, "per_page": 50, "safesearch": "true"})
    req = urllib.request.Request(url, headers={"User-Agent": "GymFree/1.0 (open-source fitness app)"})
    try:
        data = json.load(urllib.request.urlopen(req, timeout=60))
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"pixabay: '{q}' failed with HTTP {e.code}\n")
        return {"hits": []}
    json.dump(data, open(path, "w"))
    time.sleep(0.8)
    return data


key = open(sys.argv[1]).read().strip()
out = []
for q, targets in TERMS.items():
    data = get(key, q)
    for h in data.get("hits", []):
        v = h["videos"]
        out.append({"q": q, "targets": targets, "id": h["id"], "tags": h["tags"], "duration": h["duration"],
                    "user": h["user"], "page": h["pageURL"], "thumb": v["tiny"].get("thumbnail"),
                    "small": v["small"]["url"], "medium": v["medium"]["url"], "w": v["small"]["width"], "h": v["small"]["height"]})
    sys.stderr.write(f"{q}: {len(data.get('hits', []))}\n")
print(json.dumps(out, indent=1))
