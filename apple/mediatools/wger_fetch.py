"""
Collects wger's openly licensed exercise media (CC BY-SA images and videos) with their
English names, licence and author: apple/mediatools/wger_fetch.py > wger.json
"""
import json
import urllib.request

UA = {"User-Agent": "GymFree/1.0 (open-source app; media index)"}
LICENSES = {1: "CC BY-SA 3.0", 2: "CC BY-SA 4.0", 3: "CC0", 4: "CC BY 4.0"}


def get(url):
    req = urllib.request.Request(url, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=60))


def all_pages(url):
    out = []
    while url:
        page = get(url)
        out += page["results"]
        url = page.get("next")
    return out


images = all_pages("https://wger.de/api/v2/exerciseimage/?limit=200")
videos = all_pages("https://wger.de/api/v2/video/?limit=200")
ids = sorted({x["exercise"] for x in images} | {x["exercise"] for x in videos})
exercises = {}
for i in ids:
    e = get(f"https://wger.de/api/v2/exerciseinfo/{i}/")
    en = [t["name"] for t in e.get("translations", []) if t.get("language") == 2]
    exercises[i] = {
        "id": i, "name": en[0] if en else None,
        "equipment": [x["name"] for x in e.get("equipment", [])],
        "category": (e.get("category") or {}).get("name"),
        "images": [{"url": x["image"], "main": x.get("is_main"), "license": LICENSES.get(x.get("license")),
                    "author": x.get("license_author") or "wger.de contributors"} for x in images if x["exercise"] == i],
        "videos": [{"url": x["video"], "license": LICENSES.get(x.get("license")), "author": x.get("license_author") or "wger.de contributors",
                    "w": x.get("width"), "h": x.get("height"), "duration": x.get("duration")} for x in videos if x["exercise"] == i],
    }
print(json.dumps(list(exercises.values()), indent=1))
