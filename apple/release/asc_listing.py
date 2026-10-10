#!/usr/bin/env python3
"""
Pushes GymFree's store listing to App Store Connect.

    ASC_TOOLS=<dir with asc.py> python apple/release/asc_listing.py [--no-shots] [--only <step>]

Text comes from listing.json (shared fields) and listing_l10n.json (per-locale
name, subtitle, keywords, promotional text, description). Screenshots come from
shots/ (English; other locales fall back to them). Running it twice is safe:
localisations are updated in place and screenshots in the set are replaced.

asc.py lives outside this public repo because it holds the API key settings.
"""
import hashlib
import json
import os
import sys
import urllib.request

sys.path.insert(0, os.environ.get("ASC_TOOLS", os.path.expanduser("~/gal-ios-app/tools")))
import asc  # noqa: E402

APP = "6821372284"
HERE = os.path.dirname(os.path.abspath(__file__))
BASE = json.load(open(os.path.join(HERE, "listing.json")))
L10N = json.load(open(os.path.join(HERE, "listing_l10n.json")))
DISPLAY = "APP_IPHONE_67"


def ok(tag, result):
    status, body = result
    if status >= 300:
        print(f"  ✗ {tag} {status}: {[e.get('detail') for e in body.get('errors', [])]}")
    return status < 300, body


def get(path):
    return asc.call("GET", path)[1]


def by_locale(path):
    return {x["attributes"]["locale"]: x["id"] for x in get(path + "?limit=50").get("data", [])}


def upsert(kind, parent_rel, parent_type, parent_id, existing, locale, attrs):
    if locale in existing:
        ok(f"{kind} {locale}", asc.call("PATCH", f"/v1/{kind}/{existing[locale]}",
           {"data": {"type": kind, "id": existing[locale], "attributes": attrs}}))
        return existing[locale]
    _, body = ok(f"{kind} {locale}", asc.call("POST", f"/v1/{kind}", {"data": {
        "type": kind, "attributes": {"locale": locale, **attrs},
        "relationships": {parent_rel: {"data": {"type": parent_type, "id": parent_id}}}}}))
    return body.get("data", {}).get("id")


def replace_shots(loc_id, folder):
    files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
    sets = get(f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
    set_id = next((s["id"] for s in sets.get("data", [])
                   if s["attributes"]["screenshotDisplayType"] == DISPLAY), None)
    if set_id is None:
        _, body = ok("set", asc.call("POST", "/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": DISPLAY},
            "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}}))
        set_id = body["data"]["id"]
    else:
        for shot in get(f"/v1/appScreenshotSets/{set_id}/appScreenshots").get("data", []):
            asc.call("DELETE", f"/v1/appScreenshots/{shot['id']}")
    for name in files:
        data = open(os.path.join(folder, name), "rb").read()
        good, body = ok(name, asc.call("POST", "/v1/appScreenshots", {"data": {
            "type": "appScreenshots", "attributes": {"fileName": name, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}}))
        if not good:
            continue
        shot = body["data"]
        for op in shot["attributes"]["uploadOperations"]:
            req = urllib.request.Request(op["url"], data=data[op["offset"]:op["offset"] + op["length"]],
                                         method=op["method"], headers={h["name"]: h["value"] for h in op["requestHeaders"]})
            urllib.request.urlopen(req).read()
        ok("commit " + name, asc.call("PATCH", f"/v1/appScreenshots/{shot['id']}", {"data": {
            "type": "appScreenshots", "id": shot["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}}))
        print("  shot", name)


def ids():
    body = get(f"/v1/apps/{APP}?include=appInfos,appStoreVersions")
    info = next(x["id"] for x in body["included"] if x["type"] == "appInfos")
    version = next(x["id"] for x in body["included"] if x["type"] == "appStoreVersions"
                   and x["attributes"]["appStoreState"] != "READY_FOR_SALE")
    return info, version


def text(info, version, shots):
    info_locs = by_locale(f"/v1/appInfos/{info}/appInfoLocalizations")
    version_locs = by_locale(f"/v1/appStoreVersions/{version}/appStoreVersionLocalizations")
    for locale, v in L10N.items():
        print(locale)
        upsert("appInfoLocalizations", "appInfo", "appInfos", info, info_locs, locale,
               {"name": v["name"], "subtitle": v["subtitle"], "privacyPolicyUrl": BASE["privacyUrl"]})
        loc_id = upsert("appStoreVersionLocalizations", "appStoreVersion", "appStoreVersions", version,
                        version_locs, locale, {"description": v["description"], "keywords": v["keywords"],
                                               "promotionalText": v["promotionalText"],
                                               "supportUrl": BASE["supportUrl"], "marketingUrl": BASE["marketingUrl"]})
        if shots and loc_id and locale == "en-US":
            replace_shots(loc_id, os.path.join(HERE, "shots"))


def details(info, version):
    ok("category", asc.call("PATCH", f"/v1/appInfos/{info}", {"data": {"type": "appInfos", "id": info, "relationships": {
        "primaryCategory": {"data": {"type": "appCategories", "id": "HEALTH_AND_FITNESS"}}}}}))
    ok("copyright", asc.call("PATCH", f"/v1/appStoreVersions/{version}", {"data": {
        "type": "appStoreVersions", "id": version, "attributes": {"copyright": BASE["copyright"]}}}))
    ok("content rights", asc.call("PATCH", f"/v1/apps/{APP}", {"data": {
        "type": "apps", "id": APP, "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"}}}))
    review = get(f"/v1/appStoreVersions/{version}/appStoreReviewDetail").get("data")
    attrs = {"notes": BASE["reviewNotes"], "demoAccountRequired": False}
    if review:
        ok("review", asc.call("PATCH", f"/v1/appStoreReviewDetails/{review['id']}", {"data": {
            "type": "appStoreReviewDetails", "id": review["id"], "attributes": attrs}}))
    else:
        ok("review", asc.call("POST", "/v1/appStoreReviewDetails", {"data": {
            "type": "appStoreReviewDetails", "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version}}}}}))


def main():
    only = sys.argv[sys.argv.index("--only") + 1] if "--only" in sys.argv else None
    info, version = ids()
    if only in (None, "text"):
        text(info, version, "--no-shots" not in sys.argv)
    if only in (None, "details"):
        details(info, version)


if __name__ == "__main__":
    main()
