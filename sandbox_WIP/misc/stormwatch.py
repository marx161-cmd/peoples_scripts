#!/usr/bin/env python3
# StormWatch (Termux) — CAPE/Shear/LI + DWD thunderstorm polygons = Action ping

import requests
import math
from typing import List, Tuple, Dict, Any

# ---------------- CONFIG ----------------
LOCATIONS = [
    {"name": "Kassel", "lat": 51.3155, "lon": 9.4924},
    {"name": "Korbach", "lat": 51.2753, "lon": 8.8724},
    {"name": "Bad Hersfeld", "lat": 50.8708, "lon": 9.7084},
    {"name": "Göttingen", "lat": 51.5413, "lon": 9.9158},
    {"name": "Fulda", "lat": 50.5558, "lon": 9.6808},
]
CAPE_THRESHOLD = 1500           # J/kg
SHEAR_THRESHOLD = 20            # m/s (approx from 1km vs 6km wind)
LI_THRESHOLD = -4               # Lifted Index
NEAR_POLY_BUFFER_KM = 25        # count as “in polygon” if within this distance

# DWD warnings JSON (official public feed used by the WarnWetter app)
DWD_WARN_URL = "https://www.dwd.de/DWD/warnungen/warnapp/json/warnings.json"

# ---------------- UTIL ----------------
def haversine_km(lat1, lon1, lat2, lon2) -> float:
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dlmb/2)**2
    return 2 * R * math.asin(math.sqrt(a))

def point_in_poly(lat: float, lon: float, poly: List[Tuple[float, float]]) -> bool:
    # Ray casting (lat=Y, lon=X)
    x, y = lon, lat
    inside = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i-1][1], poly[i-1][0]
        x2, y2 = poly[i][1],  poly[i][0]
        # Check edge intersection
        if ((y1 > y) != (y2 > y)):
            xinters = (x2 - x1) * (y - y1) / ((y2 - y1) if (y2 - y1) != 0 else 1e-12) + x1
            if x < xinters:
                inside = not inside
    return inside

def min_dist_to_poly_km(lat: float, lon: float, poly: List[Tuple[float, float]]) -> float:
    # crude but fast: distance to vertices; cheap fallback for buffer logic
    return min(haversine_km(lat, lon, p[0], p[1]) for p in poly)

# ---------------- DATA FETCH ----------------
def get_model_data(lat: float, lon: float):
    # GFS via Open-Meteo — no API key, hourly CAPE, LI, winds at ~1km/6km to estimate deep-layer shear
    url = (
        "https://api.open-meteo.com/v1/gfs"
        f"?latitude={lat}&longitude={lon}"
        "&hourly=cape,wind_speed_6000m,wind_speed_1000m,lifted_index"
        "&forecast_days=1"
    )
    r = requests.get(url, timeout=20)
    if r.status_code != 200:
        return None
    data = r.json()
    try:
        cape_vals = [c for c in data["hourly"]["cape"] if c is not None]
        li_vals = [li for li in data["hourly"]["lifted_index"] if li is not None]
        w6 = data["hourly"]["wind_speed_6000m"]
        w1 = data["hourly"]["wind_speed_1000m"]
        shear_vals = [abs(a - b) for a, b in zip(w6, w1) if a is not None and b is not None]
        if not cape_vals or not li_vals or not shear_vals:
            return "missing"
        cape = max(cape_vals)
        shear = max(shear_vals)
        li = min(li_vals)
        return cape, shear, li
    except KeyError:
        return "missing"

def fetch_dwd_warning_polygons() -> List[Dict[str, Any]]:
    """
    Returns a list of thunderstorm warning areas:
    [
      {
        "level": int (1..4),
        "regionName": str,
        "poly": [(lat, lon), ...]
      }, ...
    ]
    """
    r = requests.get(DWD_WARN_URL, timeout=20)
    if r.status_code != 200:
        return []

    data = r.json()
    areas = []
    # The JSON is split by state keys, then have "warnings" lists
    for state_key, state_payload in data.items():
        if not isinstance(state_payload, dict):
            continue
        warnings = state_payload.get("warnings") or []
        for w in warnings:
            # Filter thunderstorm types; DWD “EVENT” text often contains GEWITTER/THUNDERSTORM
            event = (w.get("event") or "").lower()
            # include strong/severe thunderstorm wording
            if not any(k in event for k in ["gewitter", "thunderstorm", "severe thunderstorm"]):
                continue

            level = int(w.get("level", 0))
            # keep levels 2+ (Stufe 2 is already noteworthy), tweak if you want
            if level < 2:
                continue

            # Polygons are in the "polygon" field as "lat lon lat lon ..." strings (space-separated)
            poly_raw = w.get("polygon") or ""
            if not poly_raw.strip():
                continue

            coords = poly_raw.strip().split(" ")
            # DWD sometimes gives "lat,lon lat,lon" or "lat lon lat lon" depending on feed;
            # handle both by normalizing separators:
            pts = []
            for token in coords:
                token = token.strip().replace(",", " ")
                if not token:
                    continue
                # token might actually be two numbers merged from split by spaces; handle pairs
                # We'll rebuild pairs by walking 2 at a time:
            # rebuild list of floats robustly
            nums = []
            for token in poly_raw.replace(",", " ").split():
                try:
                    nums.append(float(token))
                except:
                    pass
            # Expect pairs: (lat, lon)
            it = iter(nums)
            try:
                while True:
                    lat = next(it)
                    lon = next(it)
                    pts.append((lat, lon))
            except StopIteration:
                pass

            if len(pts) >= 3:
                areas.append({
                    "level": level,
                    "regionName": w.get("regionName") or state_key,
                    "poly": pts
                })
    return areas

# ---------------- LOGIC ----------------
def location_in_warn_area(lat: float, lon: float, areas: List[Dict[str, Any]]) -> Tuple[bool, int, str]:
    """
    Return (covered, level, regionName) — covered True if inside or within NEAR_POLY_BUFFER_KM.
    Picks the highest level covering area if multiple.
    """
    best = (False, 0, "")
    for a in areas:
        poly = a["poly"]
        if point_in_poly(lat, lon, poly):
            if a["level"] > best[1]:
                best = (True, a["level"], a["regionName"])
        else:
            # near polygon?
            if min_dist_to_poly_km(lat, lon, poly) <= NEAR_POLY_BUFFER_KM:
                if a["level"] > best[1]:
                    best = (True, a["level"], a["regionName"])
    return best

def main():
    try:
        warn_areas = fetch_dwd_warning_polygons()
    except Exception as e:
        warn_areas = []
        print(f"⚠️ DWD warnings fetch failed: {e}")

    alerts = []
    for loc in LOCATIONS:
        model = get_model_data(loc["lat"], loc["lon"])
        if model == "missing":
            print(f"⚠️ Skipping {loc['name']} — missing model fields")
            continue
        if not model:
            print(f"⚠️ Error retrieving model data for {loc['name']}")
            continue

        cape, shear, li = model
        meets = (cape >= CAPE_THRESHOLD and shear >= SHEAR_THRESHOLD and li <= LI_THRESHOLD)

        covered, lvl, region = (False, 0, "")
        if warn_areas:
            covered, lvl, region = location_in_warn_area(loc["lat"], loc["lon"], warn_areas)

        if meets and covered:
            alerts.append(
                f"⚡ {loc['name']}: CAPE {cape:.0f}, Shear {shear:.1f} m/s, LI {li:.1f} — "
                f"GO (DWD Gewitter Warnstufe {lvl} / {region})"
            )
        elif meets and not warn_areas:
            # If DWD feed is down, still tell you ingredients are there
            alerts.append(
                f"⚡ {loc['name']}: CAPE {cape:.0f}, Shear {shear:.1f} m/s, LI {li:.1f} — "
                f"Ingredients READY (DWD feed unavailable)"
            )
        else:
            # stay quiet unless you want verbose
            pass

    if alerts:
        print("\n".join(alerts))
    else:
        print("No chase-worthy setups detected today.")

if __name__ == "__main__":
    main()
