#!/usr/bin/env python3
"""
Phase 4B integration test script.
Run from backend/ directory: python3 test_4b.py
Server must be running on localhost:8000.
"""
import json
import sys
import urllib.error
import urllib.request

BASE = "http://localhost:8000/api/v1"
PREMIUM = "tp_premium_demo_key"
FREE = "tp_free_demo_key"

ok = 0
fail = 0


def req(method, path, data=None, token=PREMIUM):
    url = BASE + path
    body = json.dumps(data).encode() if data else None
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {token}"}
    r = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read()
        return e.code, json.loads(raw) if raw else {}


def check(name, cond, detail=""):
    global ok, fail
    if cond:
        ok += 1
        print(f"  ✅ {name}")
    else:
        fail += 1
        print(f"  ❌ {name} — {detail}")


print("\n=== Template CRUD ===")

# free → 403
s, b = req("POST", "/templates", {"name": "T", "prompt_text": "x" * 20}, FREE)
check("Free template create → 403", s == 403, b)

# premium create
s, b = req("POST", "/templates", {"name": "Security Template", "prompt_text": "Always add 2 security test cases."})
check("Premium template create → 201", s == 201, b)
tid = b.get("id")
check("Template has id/name/prompt_text/timestamps", tid and b.get("name") and b.get("prompt_text") and b.get("created_at") and b.get("updated_at"), b)

# list
s, b = req("GET", "/templates")
check("Premium template list → 200", s == 200, b)
check("List contains created template", any(i.get("id") == tid for i in b.get("items", [])), b)

# update
s, b = req("PUT", f"/templates/{tid}", {"name": "Security Template v2", "prompt_text": "Always add 3 security test cases."})
check("Premium template update → 200", s == 200, b)
check("Updated name correct", b.get("name") == "Security Template v2", b)
check("updated_at changed", b.get("updated_at") != b.get("created_at"), b)

# free update another's template → 403
s, b = req("PUT", f"/templates/{tid}", {"name": "Hack"}, FREE)
check("Free update → 403", s == 403, b)

# delete
s, b = req("DELETE", f"/templates/{tid}")
check("Premium template delete → 204", s == 204, str(b))

# list after delete
s, b = req("GET", "/templates")
check("Deleted template not in list", not any(i.get("id") == tid for i in b.get("items", [])), b)

print("\n=== Batch Generate ===")

# free batch → 403
s, b = req("POST", "/generate/batch", {"mode": "mod_a", "items": [{"feature_idea": "Login"}]}, FREE)
check("Free batch → 403", s == 403, b)

# bug_report batch → 422
s, b = req("POST", "/generate/batch", {"mode": "bug_report", "items": [{}]})
check("Bug report batch → 422", s == 422, b)

# premium batch mod_a (2 items)
s, b = req("POST", "/generate/batch", {
    "mode": "mod_a",
    "items": [
        {"feature_idea": "Password reset via email"},
        {"feature_idea": "Two-factor authentication"},
    ],
})
check("Premium batch Mod A → 200", s == 200, b)
check("Batch total_items = 2", b.get("total_items") == 2, b)
check("Batch success_count = 2", b.get("success_count") == 2, b)
check("Batch failed_count = 0", b.get("failed_count") == 0, b)
for r in b.get("results", []):
    check(f"Batch item {r['index']} success + gen_id", r.get("success") and r.get("generation_id"), r)

# premium batch mod_b (2 items)
s, b = req("POST", "/generate/batch", {
    "mode": "mod_b",
    "items": [
        {
            "user_story": "As a user I want to update my profile picture",
            "acceptance_criteria": "Given authenticated user, When they upload JPEG under 5MB, Then profile updates",
        },
        {
            "user_story": "As admin I want to deactivate a user account",
            "acceptance_criteria": "Given admin role, When click Deactivate, Then user cannot login",
        },
    ],
})
check("Premium batch Mod B → 200", s == 200, b)
check("Batch Mod B total_items = 2", b.get("total_items") == 2, b)
check("Batch Mod B success_count = 2", b.get("success_count") == 2, b)

print("\n=== Template + Single Generate ===")

# create template for generate test
s, bt = req("POST", "/templates", {"name": "GenTest", "prompt_text": "Emphasize login flow edge cases."})
check("Template created for generate test", s == 201, bt)
test_tid = bt.get("id")

# premium + template_id generate
s, b = req("POST", "/generate", {
    "mode": "mod_a",
    "feature_idea": "User profile settings",
    "template_id": test_tid,
})
check("Premium generate with template_id → 200", s == 200, b)
check("Has generation_id", bool(b.get("generation_id")), b)
check("Has test_cases", len(b.get("test_cases", [])) > 0, b)

# free + template_id → 403
s, b = req("POST", "/generate", {
    "mode": "mod_a",
    "feature_idea": "User profile settings",
    "template_id": test_tid,
}, FREE)
check("Free generate with template_id → 403", s == 403, b)

# wrong template_id (non-existent) → 404
s, b = req("POST", "/generate", {
    "mode": "mod_a",
    "feature_idea": "User profile settings",
    "template_id": 99999,
})
check("Non-existent template_id → 404", s == 404, b)

# cleanup
req("DELETE", f"/templates/{test_tid}")

print("\n=== Existing Flows Intact ===")

# single generate still works
s, b = req("POST", "/generate", {"mode": "mod_a", "feature_idea": "Shopping cart"}, FREE)
check("Single generate (free, no template) → 200", s == 200, b)
check("Has test_cases", len(b.get("test_cases", [])) > 0, b)
gen_id = b.get("generation_id")

# history still works
s, b = req("GET", "/history", token=FREE)
check("History still works", s == 200, b)
check("History has items", len(b.get("items", [])) > 0, b)

# usage counter increased
s, b = req("GET", "/usage", token=FREE)
check("Usage endpoint still works", s == 200, b)
check("Usage count > 0", b.get("usage_count", 0) > 0, b)

print(f"\n{'=' * 40}")
print(f"Results: ✅ {ok} passed  ❌ {fail} failed")
if fail:
    sys.exit(1)
