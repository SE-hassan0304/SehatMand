"""
============================================================
  firestore_service.py — RAILWAY VERSION
  Firestore REST (NO AUTH)
  Uses FIREBASE_PROJECT_ID from environment variables
============================================================
"""

import json, os, time, requests

CACHE_FILE = "doctors_cache.json"

# ── Load project ID from ENV (Railway safe) ───────────────
PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")

if PROJECT_ID:
    print(f"✅ Loaded Firebase project: {PROJECT_ID}")
else:
    print("❌ FIREBASE_PROJECT_ID environment variable not set")

FIRESTORE_BASE = (
    f"https://firestore.googleapis.com/v1/"
    f"projects/{PROJECT_ID}/databases/(default)/documents"
)

# ── Value parser ──────────────────────────────────────────
def _parse_value(v):
    if "stringValue"  in v: return v["stringValue"]
    if "integerValue" in v: return int(v["integerValue"])
    if "doubleValue"  in v: return float(v["doubleValue"])
    if "booleanValue" in v: return v["booleanValue"]
    if "nullValue"    in v: return None
    if "mapValue"     in v:
        return {k: _parse_value(val) for k, val in v["mapValue"].get("fields", {}).items()}
    if "arrayValue"   in v:
        return [_parse_value(i) for i in v["arrayValue"].get("values", [])]
    return None

def _parse_doc(doc):
    return {k: _parse_value(v) for k, v in doc.get("fields", {}).items()}

# ── In-memory cache ───────────────────────────────────────
_cache = {}
_cache_ttl = 300

def _get_cache(key):
    if key in _cache:
        data, ts = _cache[key]
        if time.time() - ts < _cache_ttl:
            return data
    return None

def _set_cache(key, data):
    _cache[key] = (data, time.time())

# ── Local file cache ──────────────────────────────────────
def _save_to_disk(docs):
    try:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(docs, f, ensure_ascii=False)
        print(f"[Cache] 💾 Saved {len(docs)} doctors to {CACHE_FILE}")
    except Exception as e:
        print(f"[Cache] ⚠️ Could not save to disk: {e}")

def _load_from_disk():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                docs = json.load(f)
            print(f"[Cache] ✅ Loaded {len(docs)} doctors from local cache")
            return docs
        except Exception as e:
            print(f"[Cache] ⚠️ Could not read cache file: {e}")
    return None

# ── Fetch all docs via REST (no auth) ─────────────────────
def _fetch_all_docs(timeout_sec=15):
    if not PROJECT_ID:
        print("[Firestore] ❌ No FIREBASE_PROJECT_ID set")
        return []

    url = f"{FIRESTORE_BASE}/doctors"
    all_docs, page_tok = [], None

    print("[Firestore] Fetching via REST...")

    while True:
        params = {"pageSize": 300}
        if page_tok:
            params["pageToken"] = page_tok

        try:
            resp = requests.get(url, params=params, timeout=timeout_sec)
        except Exception as e:
            print(f"[Firestore] ❌ Request error: {e}")
            break

        if resp.status_code != 200:
            print(f"[Firestore] ❌ HTTP {resp.status_code}: {resp.text[:200]}")
            break

        data = resp.json()
        docs = data.get("documents", [])

        for doc in docs:
            parsed = _parse_doc(doc)
            if parsed:
                all_docs.append(parsed)

        page_tok = data.get("nextPageToken")
        if not page_tok:
            break

    print(f"[Firestore] ✅ Loaded {len(all_docs)} doctors")
    return all_docs

# ── Warm up ───────────────────────────────────────────────
def warm_up():
    print("[Firestore] 🔥 Warming up...")

    docs = _load_from_disk()

    if not docs:
        print("[Cache] No local cache — fetching from Firestore...")
        docs = _fetch_all_docs()
        if docs:
            _save_to_disk(docs)

    if docs:
        _set_cache("all_doctors", docs)
        print(f"[Firestore] ✅ Ready — {len(docs)} doctors in memory")
    else:
        print("[Firestore] ⚠️ Warm-up failed")

# ── Query ─────────────────────────────────────────────────
def get_doctors_by_specialization(specialization, city="karachi", limit=5):
    all_docs = _get_cache("all_doctors")

    if all_docs is None:
        all_docs = _load_from_disk() or _fetch_all_docs()
        if all_docs:
            _set_cache("all_doctors", all_docs)
        else:
            return []

    kw = specialization.lower().strip()

    matched = [
        _fmt(d) for d in all_docs
        if kw in str(d.get("specialization","")).lower()
    ]

    print(f"[Firestore] '{kw}' → {len(matched)} matched")
    return _prioritize(matched, limit)

def _fmt(d):
    return {
        "name"          : d.get("name", "N/A"),
        "hospital_name" : d.get("hospital_name", "N/A"),
        "specialization": d.get("specialization", "N/A"),
        "phone"         : d.get("phone"),
        "pmdc"          : d.get("pmdc"),
        "city"          : d.get("city", "karachi"),
    }

def _prioritize(doctors, limit):
    with_phone    = [d for d in doctors if d.get("phone")]
    without_phone = [d for d in doctors if not d.get("phone")]
    return (with_phone + without_phone)[:limit]

def get_all_specializations():
    all_docs = _load_from_disk() or _fetch_all_docs()
    return sorted({
        str(d.get("specialization","")).strip()
        for d in all_docs
        if d.get("specialization")
    })
