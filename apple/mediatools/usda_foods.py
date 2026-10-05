#!/usr/bin/env python3
"""
Builds GymFree's bundled, offline food database from USDA FoodData Central:
  apple/mediatools/usda_foods.py            # download (once) and build
  apple/mediatools/usda_foods.py --check    # build to a temp file and compare with the committed one

Sources: the Foundation Foods and SR Legacy CSV downloads (generic foods, raw and cooked; no
branded products). FoodData Central is public domain (CC0 1.0); USDA asks that it be credited as
"U.S. Department of Agriculture, Agricultural Research Service. FoodData Central".

Raw downloads go to apple/Media/_raw/usda/ (gitignored). The output,
apple/App/GymFree/Food/usda-foods.json, is committed and bundled by Xcode.

Per 100 g, each food keeps:
  kcal   Energy (1008); when missing, Atwater specific (2048) or general (2047) energy
  p      Protein (1003)
  f      Total lipid (fat) (1004)
  c      Available carbohydrate: carbohydrate by difference (1005; 1050 "by summation" when 1005
         is missing) minus total dietary fibre. US "total carbohydrate" includes fibre; EU/UK labels
         and GymFree's targets use available carbohydrate (research/NUTRITION.md §9.4, Step 8).
  fiber  Fiber, total dietary (1079), kept separately
and up to four household portions ("1 cup, chopped" = 91 g) for quick gram entry.
"""
import csv
import json
import os
import re
import sys
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "Media", "_raw", "usda")
OUT = os.path.join(HERE, "..", "App", "GymFree", "Food", "usda-foods.json")
BASE = "https://fdc.nal.usda.gov/fdc-datasets/"
UA = {"User-Agent": "GymFree/1.0 (open-source fitness app; https://github.com/GalSomovic/openGym)"}

DATASETS = [
    # (name, release, zip, data_type, the per-dataset food list)
    ("Foundation Foods", "2026-04-30", "FoodData_Central_foundation_food_csv_2026-04-30.zip", "foundation_food"),
    ("SR Legacy", "2018-04", "FoodData_Central_sr_legacy_food_csv_2018-04.zip", "sr_legacy_food"),
]

ENERGY, ATWATER_SPECIFIC, ATWATER_GENERAL = "1008", "2048", "2047"
PROTEIN, FAT, CARB, CARB_SUM, FIBER = "1003", "1004", "1005", "1050", "1079"
WANTED = {ENERGY, ATWATER_SPECIFIC, ATWATER_GENERAL, PROTEIN, FAT, CARB, CARB_SUM, FIBER}

# Categories left out: baby foods, branded products and lab quality-control materials.
SKIP_CATEGORIES = {"Baby Foods", "Branded Food Products Database", "Quality Control Materials"}

# Portion units that are just weights (the user types grams anyway) or Foundation lab pairings.
SKIP_UNITS = {"oz", "lb", "g", "kg", "paired cooked w", "paired raw w", "dripping w", "orig ckd g", "orig rw g"}
SKIP_PORTION = re.compile(r"^(oz|lb|g|kg|fl oz|ounce|pound|grams?)\b|yield from|\bRACC\b", re.I)
MAX_PORTIONS = 4

# Common foods: ranked first when they match a search. USDA descriptions (checked after cleaning).
COMMON = [
    "Rice, white, long-grain, regular, enriched, cooked",
    "Rice, brown, long-grain, cooked",
    "Rice, white, long-grain, regular, raw, enriched",
    "Chicken, broilers or fryers, breast, meat only, cooked, roasted",
    "Chicken, breast, boneless, skinless, raw",
    "Chicken, broilers or fryers, thigh, meat only, cooked, roasted",
    "Egg, whole, raw, fresh",
    "Egg, whole, cooked, hard-boiled",
    "Egg, whole, cooked, scrambled",
    "Egg, white, raw, fresh",
    "Oats",
    "Cereals, oats, regular and quick, not fortified, dry",
    "Cereals, oats, regular and quick, unenriched, cooked with water (includes boiling and microwaving), without salt",
    "Pasta, cooked, enriched, without added salt",
    "Pasta, dry, enriched",
    "Bread, whole-wheat, commercially prepared",
    "Bread, white, commercially prepared (includes soft bread crumbs)",
    "Potatoes, boiled, cooked without skin, flesh, without salt",
    "Potatoes, baked, flesh and skin, without salt",
    "Sweet potato, cooked, baked in skin, flesh, without salt",
    "Bananas, raw",
    "Apples, raw, with skin (Includes foods for USDA's Food Distribution Program)",
    "Oranges, raw, all commercial varieties",
    "Strawberries, raw",
    "Blueberries, raw",
    "Grapes, red or green (European type, such as Thompson seedless), raw",
    "Avocados, raw, all commercial varieties",
    "Broccoli, raw",
    "Broccoli, cooked, boiled, drained, without salt",
    "Spinach, raw",
    "Carrots, raw",
    "Tomatoes, red, ripe, raw, year round average",
    "Cucumber, with peel, raw",
    "Onions, raw",
    "Peppers, sweet, red, raw",
    "Lettuce, cos or romaine, raw",
    "Milk, whole, 3.25% milkfat, with added vitamin D",
    "Milk, reduced fat, fluid, 2% milkfat, with added vitamin A and vitamin D",
    "Milk, nonfat, fluid, with added vitamin A and vitamin D (fat free or skim)",
    "Yogurt, Greek, plain, nonfat",
    "Yogurt, Greek, plain, whole milk",
    "Yogurt, plain, whole milk",
    "Cheese, cheddar",
    "Cheese, mozzarella, whole milk",
    "Cheese, cottage, lowfat, 2% milkfat",
    "Cheese, parmesan, hard",
    "Butter, salted",
    "Oil, olive, salad or cooking",
    "Peanut butter, smooth style, without salt",
    "Nuts, almonds",
    "Nuts, walnuts, english",
    "Beef, ground, 85% lean meat / 15% fat, patty, cooked, broiled",
    "Beef, ground, 85% lean meat / 15% fat, raw",
    "Fish, salmon, Atlantic, farmed, cooked, dry heat",
    "Fish, salmon, Atlantic, farmed, raw",
    "Fish, tuna, light, canned in water, drained solids",
    "Fish, cod, Atlantic, cooked, dry heat",
    "Crustaceans, shrimp, cooked",
    "Pork, fresh, loin, tenderloin, separable lean only, cooked, roasted",
    "Turkey, whole, breast, meat only, cooked, roasted",
    "Tofu, raw, firm, prepared with calcium sulfate",
    "Chickpeas (garbanzo beans, bengal gram), mature seeds, cooked, boiled, without salt",
    "Lentils, mature seeds, cooked, boiled, without salt",
    "Beans, black, mature seeds, cooked, boiled, without salt",
    "Beans, kidney, all types, mature seeds, cooked, boiled, without salt",
    "Hummus, commercial",
    "Quinoa, cooked",
    "Couscous, cooked",
    "Sugars, granulated",
    "Honey",
    "Beverages, Protein powder whey based",
    "Beverages, coffee, brewed, prepared with tap water",
        "Orange juice, raw",
    "Chocolate, dark, 70-85% cacao solids",
    "Tortillas, ready-to-bake or -fry, flour, refrigerated",
    "Bagels, plain, enriched, with calcium propionate (includes onion, poppy, sesame)",
    "Cereals ready-to-eat, granola, homemade",
    "Corn, sweet, yellow, cooked, boiled, drained, without salt",
    "Peas, green, frozen, cooked, boiled, drained, without salt",
]

# Readability: drop USDA boilerplate that does not help anyone pick a food.
NAME_FIXES = [
    (re.compile(r"\s*\(Includes foods for USDA's Food Distribution Program\)", re.I), ""),
    (re.compile(r"\s*\(includes foods for USDA's Food Distribution Program\)", re.I), ""),
    (re.compile(r", broilers? or fryers", re.I), ""),
    (re.compile(r"[®™]"), ""),
    (re.compile(r"\s+,"), ","),
    (re.compile(r",\s*,"), ","),
    (re.compile(r"\s{2,}"), " "),
]


KEEP_CAPS = {"USDA", "NFSMI", "UHT"}


def clean_name(s):
    s = s.strip()
    for rx, rep in NAME_FIXES:
        s = rx.sub(rep, s)
    s = s.strip(" ,")
    # Brand names come in capitals ("UNCLE BEN'S"); short acronyms (KFC) stay as they are.
    def title(m):
        words = m.group(0).split(" ")
        if not any(len(w) >= 4 and w not in KEEP_CAPS for w in words):
            return m.group(0)
        return " ".join(w if w in KEEP_CAPS else w.capitalize() for w in words)
    s = re.sub(r"\b[A-Z][A-Z'&.-]*(?: [A-Z][A-Z'&.-]*)*\b", title, s)
    return s[:1].upper() + s[1:]


def download():
    os.makedirs(RAW, exist_ok=True)
    for _, _, z, _ in DATASETS:
        folder = os.path.join(RAW, z[:-4])
        if os.path.isdir(folder):
            continue
        path = os.path.join(RAW, z)
        if not os.path.exists(path):
            print("downloading", z)
            req = urllib.request.Request(BASE + z, headers=UA)
            with urllib.request.urlopen(req) as r, open(path + ".part", "wb") as f:
                while chunk := r.read(1 << 20):
                    f.write(chunk)
            os.replace(path + ".part", path)
        with zipfile.ZipFile(path) as zf:
            zf.extractall(RAW)


def rows(folder, name):
    with open(os.path.join(RAW, folder, name), newline="", encoding="utf-8") as f:
        yield from csv.DictReader(f)


def num(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def r1(x):
    return round(x + 0.0, 1)


def amount_text(a):
    a = num(a) or 1
    fractions = {0.25: "¼", 0.5: "½", 0.75: "¾", 0.33: "⅓", 0.333: "⅓", 0.67: "⅔", 0.667: "⅔"}
    if a in fractions:
        return fractions[a]
    if a == int(a):
        return str(int(a))
    whole, frac = int(a), round(a - int(a), 3)
    if whole and frac in fractions:
        return f"{whole}{fractions[frac]}"
    return f"{a:g}"


def portion_label(p, units):
    unit = units.get(p["measure_unit_id"], "")
    if unit in ("undetermined", "") or unit in SKIP_UNITS:
        if unit in SKIP_UNITS:
            return None
        unit = ""
    desc = " ".join(x for x in (unit, p.get("portion_description", "").strip(), p.get("modifier", "").strip()) if x)
    desc = re.sub(r"\s*\(.*?\)", "", desc)
    desc = re.sub(r"\bserving size.*$", "", desc, flags=re.I)
    desc = re.sub(r"\bNLEA\s+", "", desc, flags=re.I)
    desc = re.sub(r"\b(\w+) \1\b", r"\1", desc).strip(" ,")
    if not desc or SKIP_PORTION.search(desc) or re.fullmatch(r"\d+(\.\d+)?", desc):
        return None
    if len(desc) > 40:
        desc = desc[:40].rsplit(" ", 1)[0].rstrip(",")
    return f"{amount_text(p['amount'])} {desc}"


def load_dataset(name, release, z, dtype):
    folder = z[:-4]
    cats = {r["id"]: r["description"] for r in rows(folder, "food_category.csv")}
    units = {r["id"]: r["name"] for r in rows(folder, "measure_unit.csv")}
    foods = {r["fdc_id"]: r for r in rows(folder, "food.csv") if r["data_type"] == dtype}
    nutr = {}
    for r in rows(folder, "food_nutrient.csv"):
        if r["fdc_id"] in foods and r["nutrient_id"] in WANTED:
            v = num(r["amount"])
            if v is not None:
                nutr.setdefault(r["fdc_id"], {})[r["nutrient_id"]] = v
    portions = {}
    for r in rows(folder, "food_portion.csv"):
        if r["fdc_id"] in foods:
            portions.setdefault(r["fdc_id"], []).append(r)
    out = []
    skipped = {"category": 0, "energy": 0}
    for fid, food in foods.items():
        cat = cats.get(food["food_category_id"], "")
        if cat in SKIP_CATEGORIES:
            skipped["category"] += 1
            continue
        n = nutr.get(fid, {})
        kcal = next((n[k] for k in (ENERGY, ATWATER_SPECIFIC, ATWATER_GENERAL) if k in n), None)
        if kcal is None:
            skipped["energy"] += 1
            continue
        fiber = n.get(FIBER, 0.0)
        carb_total = n.get(CARB, n.get(CARB_SUM, 0.0))
        ps, seen = [], set()
        for p in sorted(portions.get(fid, []), key=lambda p: (num(p["seq_num"]) or 999, num(p["id"]) or 0)):
            g = num(p["gram_weight"])
            label = portion_label(p, units)
            if not g or g <= 0 or not label or label.lower() in seen:
                continue
            seen.add(label.lower())
            ps.append([label, r1(g)])
            if len(ps) >= MAX_PORTIONS:
                break
        out.append({
            "id": int(fid), "raw": food["description"], "name": clean_name(food["description"]), "cat": cat,
            "kcal": round(kcal), "p": r1(n.get(PROTEIN, 0)), "f": r1(n.get(FAT, 0)),
            "c": r1(max(0.0, carb_total - fiber)), "fiber": r1(fiber), "portions": ps, "src": name,
        })
    print(f"{name} {release}: {len(out)} foods (skipped {skipped['category']} by category, {skipped['energy']} without energy)")
    return out


def build():
    all_foods = []
    for d in DATASETS:
        all_foods += load_dataset(*d)
    # A food in both datasets keeps the newer Foundation analysis; SR Legacy lends its portions.
    by_name = {}
    for f in all_foods:
        key = f["name"].lower()
        if key in by_name:
            keep = by_name[key]
            if not keep["portions"]:
                keep["portions"] = f["portions"]
            continue
        by_name[key] = f
    foods = sorted(by_name.values(), key=lambda f: f["name"].lower())

    names = {f["name"].lower() for f in foods}
    missing = [c for c in COMMON if clean_name(c).lower() not in names]
    if missing:
        sys.exit("COMMON foods not found in the data:\n  " + "\n  ".join(missing))
    common_rank = {clean_name(c).lower(): i for i, c in enumerate(COMMON)}

    cats = sorted({f["cat"] for f in foods})
    cat_ix = {c: i for i, c in enumerate(cats)}
    rows_out = []
    for f in foods:
        common = len(COMMON) - common_rank[f["name"].lower()] if f["name"].lower() in common_rank else 0
        rows_out.append([f["id"], f["name"], cat_ix[f["cat"]], f["kcal"], f["p"], f["f"], f["c"], f["fiber"], common, f["portions"]])

    doc = {
        "source": "USDA FoodData Central: " + ", ".join(f"{n} ({r})" for n, r, _, _ in DATASETS),
        "releases": {n: r for n, r, _, _ in DATASETS},
        "url": "https://fdc.nal.usda.gov/",
        "licence": "CC0 1.0 (public domain)",
        "credit": "U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.",
        "notes": "Values per 100 g of the food as described (raw or cooked). kcal: Energy (1008), else Atwater "
                 "specific (2048) or general (2047) energy. c is available carbohydrate: carbohydrate by difference "
                 "(1005, else 1050) minus total dietary fibre (1079), as on EU/UK labels; US total carbohydrate = c + fiber. "
                 "common: rank among everyday foods for search (0 = not listed). Built by apple/mediatools/usda_foods.py.",
        "fields": ["fdcId", "name", "category", "kcal", "p", "f", "c", "fiber", "common", "portions"],
        "categories": cats,
        "foods": rows_out,
    }
    return doc


def write(doc, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        # One food per line: compact, but diffs stay readable.
        head = {k: v for k, v in doc.items() if k != "foods"}
        body = json.dumps(head, ensure_ascii=False, separators=(",", ":"))[:-1]
        f.write(body + ',"foods":[\n')
        f.write(",\n".join(json.dumps(r, ensure_ascii=False, separators=(",", ":")) for r in doc["foods"]))
        f.write("\n]}\n")


def main():
    download()
    doc = build()
    if "--check" in sys.argv:
        tmp = OUT + ".check"
        write(doc, tmp)
        same = open(tmp, "rb").read() == open(OUT, "rb").read()
        os.remove(tmp)
        print("up to date" if same else "differs from the committed file")
        sys.exit(0 if same else 1)
    write(doc, OUT)
    print(f"{len(doc['foods'])} foods → {os.path.relpath(OUT)} ({os.path.getsize(OUT) / 1e6:.2f} MB)")


if __name__ == "__main__":
    main()
