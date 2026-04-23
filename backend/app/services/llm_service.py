"""
TestPilot – LLM Service
=========================
LLM entegrasyonu için soyutlama katmanı.

Desteklenen provider'lar:
  - mock   : Deterministik generator (API key gerektirmez, her zaman çalışır)
  - gemini : Google Gemini API (GEMINI_API_KEY gerekli)

Geçiş: LLM_PROVIDER env değişkeni ile kontrol edilir.
Fallback: LLM_FALLBACK_TO_MOCK=true ise Gemini hata verirse mock'a düşer.
"""

from __future__ import annotations

import hashlib
import json
import logging
import re

from app.config import settings

logger = logging.getLogger(__name__)


# ── Public Interface ────────────────────────────────────

def generate_with_llm(mode: str, inputs: dict, plan: str = "free") -> dict:
    """LLM ile üretim yap.

    Args:
        mode  : "mod_a", "mod_b" veya "bug_report"
        inputs: Mod'a göre değişen input dict
        plan  : "free" veya "premium" (prompt kalitesini etkiler)

    Returns:
        Üretilmiş artifacts dict

    Raises:
        RuntimeError: Hem Gemini hem fallback başarısız olursa
    """
    if settings.LLM_PROVIDER == "gemini" and settings.GEMINI_API_KEY:
        try:
            return _generate_with_gemini(mode, inputs, plan)
        except Exception as exc:
            if settings.LLM_FALLBACK_TO_MOCK:
                logger.warning(
                    "Gemini call failed (mode=%s), falling back to mock: %s",
                    mode, exc,
                )
                return _generate_mock(mode, inputs, plan)
            raise RuntimeError(
                f"Gemini generation failed: {exc}. "
                "Set LLM_FALLBACK_TO_MOCK=true to enable mock fallback."
            ) from exc

    if settings.LLM_PROVIDER == "gemini" and not settings.GEMINI_API_KEY:
        logger.warning("LLM_PROVIDER=gemini but GEMINI_API_KEY is empty, using mock.")

    return _generate_mock(mode, inputs, plan)


# ── Gemini Provider ─────────────────────────────────────

def _generate_with_gemini(mode: str, inputs: dict, plan: str) -> dict:
    """Gerçek Gemini API çağrısı.

    google-genai SDK kullanır.
    JSON çıktı için response_mime_type='application/json' parametresi ile
    structured output talep eder, parse başarısız olursa tek retry yapar.
    """
    try:
        from google import genai
        from google.genai import types as genai_types
    except ImportError as exc:
        raise RuntimeError(
            "google-genai package not installed. "
            "Run: pip install google-genai"
        ) from exc

    client = genai.Client(api_key=settings.GEMINI_API_KEY)

    system_prompt, user_prompt = _build_prompts(mode, inputs, plan)

    config = genai_types.GenerateContentConfig(
        system_instruction=system_prompt,
        response_mime_type="application/json",
        temperature=0.4,
        max_output_tokens=4096,
    )

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=user_prompt,
        config=config,
    )

    raw_text = response.text.strip()

    # Parse & validate
    try:
        parsed = _parse_and_validate(mode, raw_text, plan, inputs)
        return parsed
    except (json.JSONDecodeError, ValueError, KeyError) as first_err:
        logger.warning("First Gemini parse failed: %s — retrying with stricter prompt.", first_err)
        # Single retry with explicit reminder
        retry_prompt = (
            user_prompt
            + "\n\nIMPORTANT: Your previous response could not be parsed. "
            "Return ONLY the raw JSON object. No markdown fences, no explanation text."
        )
        retry_response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=retry_prompt,
            config=config,
        )
        return _parse_and_validate(mode, retry_response.text.strip(), plan, inputs)


def _build_prompts(mode: str, inputs: dict, plan: str) -> tuple[str, str]:
    """Mode ve plan'a göre system + user prompt döndür."""
    from app.prompts.mod_a_prompt import (
        MOD_A_SYSTEM_PROMPT_FREE,
        MOD_A_SYSTEM_PROMPT_PREMIUM,
        MOD_A_USER_PROMPT_TEMPLATE,
    )
    from app.prompts.mod_b_prompt import (
        MOD_B_SYSTEM_PROMPT_FREE,
        MOD_B_SYSTEM_PROMPT_PREMIUM,
        MOD_B_USER_PROMPT_TEMPLATE,
    )
    from app.prompts.bug_report_prompt import (
        BUG_REPORT_SYSTEM_PROMPT_FREE,
        BUG_REPORT_SYSTEM_PROMPT_PREMIUM,
        BUG_REPORT_USER_PROMPT_TEMPLATE,
        BUG_REPORT_USER_PROMPT_TEMPLATE_PREMIUM,
    )

    is_premium = plan == "premium"

    if mode == "mod_a":
        system = MOD_A_SYSTEM_PROMPT_PREMIUM if is_premium else MOD_A_SYSTEM_PROMPT_FREE
        user = MOD_A_USER_PROMPT_TEMPLATE.format(
            feature_idea=inputs["feature_idea"]
        )

    elif mode == "mod_b":
        system = MOD_B_SYSTEM_PROMPT_PREMIUM if is_premium else MOD_B_SYSTEM_PROMPT_FREE
        user = MOD_B_USER_PROMPT_TEMPLATE.format(
            user_story=inputs["user_story"],
            acceptance_criteria=inputs["acceptance_criteria"],
        )

    elif mode == "bug_report":
        system = BUG_REPORT_SYSTEM_PROMPT_PREMIUM if is_premium else BUG_REPORT_SYSTEM_PROMPT_FREE
        template = (
            BUG_REPORT_USER_PROMPT_TEMPLATE_PREMIUM
            if is_premium
            else BUG_REPORT_USER_PROMPT_TEMPLATE
        )
        user = template.format(
            title=inputs.get("title", ""),
            steps_to_reproduce=inputs.get("steps_to_reproduce", ""),
            actual_result=inputs.get("actual_result", ""),
            expected_result=inputs.get("expected_result", ""),
            environment=inputs.get("environment", "Not specified"),
            severity=inputs.get("severity", "major"),
        )
    else:
        raise ValueError(f"Unknown mode: {mode}")

    return system, user


def _extract_json(text: str) -> dict:
    """Metin içinden JSON obje çıkar.

    Gemini bazen JSON etrafına metin/markdown ekler — bunu temizler.
    """
    # Önce direkt parse dene
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Markdown kod bloğu içinde olabilir
    fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if fenced:
        return json.loads(fenced.group(1))

    # Metin içindeki ilk { ... } bloğunu bul
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end != -1 and end > start:
        return json.loads(text[start:end + 1])

    raise json.JSONDecodeError("No JSON object found in response", text, 0)


def _parse_and_validate(mode: str, raw_text: str, plan: str, inputs: dict) -> dict:
    """Gemini çıktısını parse et ve şema uyumunu doğrula."""
    data = _extract_json(raw_text)

    if mode == "mod_a":
        return _validate_mod_a(data)
    elif mode == "mod_b":
        return _validate_mod_b(data, inputs)
    elif mode == "bug_report":
        return _validate_bug_report(data)
    else:
        raise ValueError(f"Unknown mode: {mode}")


def _validate_test_cases(test_cases: list) -> list:
    """Test case listesini normalize et."""
    valid = []
    for i, tc in enumerate(test_cases, 1):
        if not isinstance(tc, dict):
            continue
        valid.append({
            "id": str(tc.get("id", f"TC-GEN-{i:03d}")),
            "title": str(tc.get("title", f"Test Case {i}")),
            "type": str(tc.get("type", "positive")),
            "priority": str(tc.get("priority", "P1")),
            "preconditions": str(tc.get("preconditions", "")),
            "steps": [str(s) for s in tc.get("steps", [])],
            "expected_result": str(tc.get("expected_result", "")),
            "tags": [str(t) for t in tc.get("tags", [])],
        })
    if not valid:
        raise ValueError("test_cases list is empty or invalid")
    return valid


def _validate_test_plan(tp: dict) -> dict:
    """Test plan dict'i normalize et."""
    return {
        "objective": str(tp.get("objective", "")),
        "scope": str(tp.get("scope", "")),
        "test_types": [str(t) for t in tp.get("test_types", ["functional"])],
        "approach": str(tp.get("approach", "")),
    }


def _validate_mod_a(data: dict) -> dict:
    """Mod A çıktısını doğrula ve normalize et."""
    required = ["user_story", "acceptance_criteria", "test_plan", "test_cases"]
    for field in required:
        if field not in data:
            raise KeyError(f"Missing required field: {field}")

    ac = data["acceptance_criteria"]
    if isinstance(ac, str):
        ac = [ac]

    return {
        "user_story": str(data["user_story"]),
        "acceptance_criteria": [str(item) for item in ac],
        "test_plan": _validate_test_plan(data["test_plan"]),
        "test_cases": _validate_test_cases(data["test_cases"]),
    }


def _validate_mod_b(data: dict, inputs: dict) -> dict:
    """Mod B çıktısını doğrula ve normalize et.

    Gemini sadece test_plan + test_cases döner.
    user_story ve acceptance_criteria orijinal input'tan alınır.
    """
    if "test_plan" not in data:
        raise KeyError("Missing required field: test_plan")
    if "test_cases" not in data:
        raise KeyError("Missing required field: test_cases")

    # AC'yi satırlara ayır (orijinal input'tan)
    ac_raw = inputs["acceptance_criteria"]
    if isinstance(ac_raw, list):
        ac_lines = ac_raw
    else:
        ac_lines = [
            line.strip()
            for line in ac_raw.replace("\\n", "\n").split("\n")
            if line.strip()
        ]
    if not ac_lines:
        ac_lines = [ac_raw]

    return {
        "user_story": inputs["user_story"],
        "acceptance_criteria": ac_lines,
        "test_plan": _validate_test_plan(data["test_plan"]),
        "test_cases": _validate_test_cases(data["test_cases"]),
    }


def _validate_bug_report(data: dict) -> dict:
    """Bug report çıktısını doğrula ve normalize et."""
    if "bug_report" not in data:
        # Bazen model doğrudan alanları döner, wrap et
        if "title" in data:
            data = {"bug_report": data}
        else:
            raise KeyError("Missing required field: bug_report")

    br = data["bug_report"]
    steps = br.get("steps_to_reproduce", [])
    if isinstance(steps, str):
        steps = [s.strip() for s in steps.split("\n") if s.strip()]

    return {
        "bug_report": {
            "title": str(br.get("title", "Bug Report")),
            "summary": str(br.get("summary", br.get("title", ""))),
            "severity": str(br.get("severity", "major")).lower(),
            "priority": str(br.get("priority", "P1")),
            "environment": str(br.get("environment", "Not specified")),
            "steps_to_reproduce": [str(s) for s in steps],
            "actual_result": str(br.get("actual_result", "")),
            "expected_result": str(br.get("expected_result", "")),
            "root_cause_hint": str(br.get("root_cause_hint", "")),
            "regression_risk": str(br.get("regression_risk", "")),
            "suggested_fix": str(br.get("suggested_fix", "")),
            "labels": [str(l) for l in br.get("labels", ["bug", "qa-generated"])],
        }
    }


# ── Mock Provider ───────────────────────────────────────

def _generate_mock(mode: str, inputs: dict, plan: str = "free") -> dict:
    """Deterministik mock generator.

    Gerçek LLM olmadan çalışır. Test, geliştirme ve fallback için.
    plan parametresi mock'ta minimal etkisi var (tutarlılık için alınır).
    """
    if mode == "mod_a":
        return _mock_mod_a(inputs["feature_idea"])
    if mode == "mod_b":
        return _mock_mod_b(inputs["user_story"], inputs["acceptance_criteria"])
    if mode == "bug_report":
        return _mock_bug_report(inputs)
    raise ValueError(f"Unsupported mode: {mode}")


def _mock_mod_a(feature_idea: str) -> dict:
    """Mod A mock: feature_idea → user_story + AC + test_plan + test_cases"""
    seed = hashlib.md5(feature_idea.encode()).hexdigest()[:4].upper()

    user_story = (
        f"As a user, I want to {feature_idea.lower().rstrip('.')} "
        f"so that I can accomplish my task efficiently and with confidence."
    )

    acceptance_criteria = [
        f"Given the system is ready, When the user initiates '{feature_idea}', "
        f"Then the feature should complete successfully within acceptable time limits.",
        f"Given valid input is provided, When '{feature_idea}' is triggered, "
        f"Then the expected output should be produced without errors.",
        f"Given invalid or missing input, When '{feature_idea}' is attempted, "
        f"Then the system should display a clear and actionable error message.",
        f"Given the user has appropriate permissions, When '{feature_idea}' is used, "
        f"Then all actions should be logged for audit purposes.",
    ]

    test_plan = {
        "objective": f"Validate the end-to-end functionality and edge-case handling of: {feature_idea}",
        "scope": (
            f"Functional testing of '{feature_idea}' including positive flows, "
            f"negative/error handling, boundary conditions, and basic security validation."
        ),
        "test_types": ["functional", "negative", "boundary", "security"],
        "approach": (
            "1. Verify happy-path scenario works correctly. "
            "2. Test error handling with invalid inputs. "
            "3. Validate boundary conditions. "
            "4. Check authorization and audit logging."
        ),
    }

    test_cases = [
        {
            "id": f"TC-{seed}-001",
            "title": f"[HAPPY PATH] Verify successful execution of {feature_idea}",
            "type": "positive",
            "priority": "P0",
            "preconditions": "User is authenticated and has necessary permissions. System is in a stable state.",
            "steps": [
                f"Step 1: Navigate to the relevant feature area for '{feature_idea}'",
                "Step 2: Initiate the feature with valid input data",
                "Step 3: Observe the system response and output",
                "Step 4: Verify the result matches expected behavior",
            ],
            "expected_result": f"'{feature_idea}' completes successfully. Expected output is produced and displayed correctly.",
            "tags": ["smoke", "regression", "functional"],
        },
        {
            "id": f"TC-{seed}-002",
            "title": f"Verify error handling with invalid input for {feature_idea}",
            "type": "negative",
            "priority": "P0",
            "preconditions": "User is authenticated. System is in a stable state.",
            "steps": [
                f"Step 1: Navigate to the feature area for '{feature_idea}'",
                "Step 2: Attempt the feature with invalid/malformed input",
                "Step 3: Observe the error response",
                "Step 4: Verify the error message is clear and actionable",
            ],
            "expected_result": "System displays a meaningful error message without crashing. No data corruption occurs.",
            "tags": ["regression", "negative"],
        },
        {
            "id": f"TC-{seed}-003",
            "title": f"Verify {feature_idea} with empty/missing required input",
            "type": "edge_case",
            "priority": "P1",
            "preconditions": "User is authenticated.",
            "steps": [
                f"Step 1: Navigate to the feature area for '{feature_idea}'",
                "Step 2: Attempt the feature without providing required input",
                "Step 3: Observe the validation response",
            ],
            "expected_result": "System shows a validation error indicating required fields. Feature does not execute.",
            "tags": ["edge_case", "validation"],
        },
        {
            "id": f"TC-{seed}-004",
            "title": f"Verify boundary values for {feature_idea}",
            "type": "boundary",
            "priority": "P1",
            "preconditions": "User is authenticated. Test data with boundary values is prepared.",
            "steps": [
                "Step 1: Prepare input data at minimum boundary value",
                f"Step 2: Execute '{feature_idea}' with minimum boundary input",
                "Step 3: Prepare input data at maximum boundary value",
                f"Step 4: Execute '{feature_idea}' with maximum boundary input",
                "Step 5: Compare both results against expected behavior",
            ],
            "expected_result": "Feature handles both min and max boundary inputs correctly without overflow or truncation.",
            "tags": ["boundary", "regression"],
        },
        {
            "id": f"TC-{seed}-005",
            "title": f"Verify unauthorized access to {feature_idea}",
            "type": "negative",
            "priority": "P1",
            "preconditions": "User without required permissions is logged in.",
            "steps": [
                "Step 1: Log in as a user without the necessary permissions",
                f"Step 2: Attempt to access '{feature_idea}'",
                "Step 3: Observe the access control response",
            ],
            "expected_result": "System denies access with a 403/401 error. No data is exposed.",
            "tags": ["security", "negative", "regression"],
        },
    ]

    return {
        "user_story": user_story,
        "acceptance_criteria": acceptance_criteria,
        "test_plan": test_plan,
        "test_cases": test_cases,
    }


def _mock_mod_b(user_story: str, acceptance_criteria: str) -> dict:
    """Mod B mock: user_story + AC → test_plan + test_cases"""
    seed = hashlib.md5((user_story + acceptance_criteria).encode()).hexdigest()[:4].upper()

    ac_lines = [
        line.strip()
        for line in acceptance_criteria.replace("\\n", "\n").split("\n")
        if line.strip()
    ]
    if not ac_lines:
        ac_lines = [acceptance_criteria.strip()]

    test_plan = {
        "objective": "Validate the acceptance criteria for the given user story through comprehensive test coverage.",
        "scope": (
            f"Functional and edge-case testing of the user story. "
            f"Covers {len(ac_lines)} acceptance criteria with positive, negative, and boundary scenarios."
        ),
        "test_types": ["functional", "acceptance", "negative", "edge_case"],
        "approach": (
            "1. Map each acceptance criterion to at least one test case. "
            "2. Add negative test cases for each criterion. "
            "3. Identify and test boundary conditions. "
            "4. Validate error messages and edge cases."
        ),
    }

    test_cases = []
    for i, ac in enumerate(ac_lines[:5], start=1):
        test_cases.append({
            "id": f"TC-{seed}-{i:03d}",
            "title": f"Verify: {ac[:80]}{'...' if len(ac) > 80 else ''}",
            "type": "positive",
            "priority": "P0" if i <= 2 else "P1",
            "preconditions": "System is configured and user is authenticated per the user story context.",
            "steps": [
                "Step 1: Set up the preconditions as described in the acceptance criteria",
                f"Step 2: Execute the action: {ac[:100]}",
                "Step 3: Observe the system response",
                "Step 4: Verify the outcome matches acceptance criteria",
            ],
            "expected_result": f"The acceptance criterion is satisfied: {ac[:120]}",
            "tags": ["acceptance", "regression", "functional"],
        })

    test_cases.append({
        "id": f"TC-{seed}-{len(test_cases)+1:03d}",
        "title": "Verify system behavior with invalid preconditions",
        "type": "negative",
        "priority": "P1",
        "preconditions": "System state does NOT meet the required preconditions.",
        "steps": [
            "Step 1: Intentionally violate one or more preconditions",
            "Step 2: Attempt to perform the action described in the user story",
            "Step 3: Observe the system response",
        ],
        "expected_result": "System gracefully handles the invalid state with clear error messaging. No data corruption.",
        "tags": ["negative", "regression"],
    })

    test_cases.append({
        "id": f"TC-{seed}-{len(test_cases)+1:03d}",
        "title": "Verify edge case with boundary input values",
        "type": "edge_case",
        "priority": "P2",
        "preconditions": "System is ready. Boundary test data is prepared.",
        "steps": [
            "Step 1: Prepare boundary/extreme input values",
            "Step 2: Execute the user story flow with these values",
            "Step 3: Verify the system handles them correctly",
        ],
        "expected_result": "System processes boundary values without errors, overflow, or data loss.",
        "tags": ["edge_case", "boundary"],
    })

    return {
        "user_story": user_story,
        "acceptance_criteria": ac_lines,
        "test_plan": test_plan,
        "test_cases": test_cases,
    }


def _mock_bug_report(inputs: dict) -> dict:
    """Bug Report mock: ham bilgilerden deterministik bug raporu üret."""
    raw_steps = inputs.get("steps_to_reproduce", "")
    if isinstance(raw_steps, list):
        steps = [str(s).strip() for s in raw_steps if str(s).strip()]
    else:
        steps = [
            line.strip(" -\t")
            for line in str(raw_steps).replace("\\n", "\n").split("\n")
            if line.strip(" -\t")
        ]
    if not steps:
        steps = ["Reproduce the issue using the reported user flow."]

    severity = (inputs.get("severity") or "major").strip().lower()
    severity_priority_map = {
        "critical": "P0",
        "blocker": "P0",
        "major": "P1",
        "high": "P1",
        "medium": "P2",
        "minor": "P2",
        "low": "P3",
        "trivial": "P3",
    }
    priority = severity_priority_map.get(severity, "P1")
    title = (inputs.get("title") or "Bug report").strip()
    labels = ["bug", "qa-generated", severity]

    return {
        "bug_report": {
            "title": title,
            "summary": (
                f"{title}. "
                f"Actual behavior differs from expected: {inputs.get('expected_result', '').strip()[:120]}"
            ),
            "severity": severity,
            "priority": priority,
            "environment": inputs.get("environment", "Not specified").strip(),
            "steps_to_reproduce": steps,
            "actual_result": inputs.get("actual_result", "").strip(),
            "expected_result": inputs.get("expected_result", "").strip(),
            "root_cause_hint": "",
            "regression_risk": "",
            "suggested_fix": "",
            "labels": labels,
        }
    }
