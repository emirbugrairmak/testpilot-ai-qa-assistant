"""
TestPilot – LLM Service
=========================
LLM entegrasyonu için soyutlama katmanı.

Şu an MOCK generator aktif. İleride Gemini entegrasyonu eklendiğinde
sadece bu dosya değiştirilecek — router / service katmanına dokunulmayacak.
"""

from __future__ import annotations

import hashlib
from typing import Any

from app.config import settings


# ── Interface ───────────────────────────────────────────

def generate_with_llm(mode: str, inputs: dict) -> dict:
    """LLM ile üretim yap.

    Args:
        mode: "mod_a", "mod_b" veya "bug_report"
        inputs: Mod'a göre değişen input dict

    Returns:
        Üretilmiş test artifacts (user_story, AC, test_plan, test_cases)
    """
    if settings.LLM_PROVIDER == "gemini" and settings.GEMINI_API_KEY:
        return _generate_with_gemini(mode, inputs)
    return _generate_mock(mode, inputs)


# ── Mock Generator ──────────────────────────────────────

def _generate_mock(mode: str, inputs: dict) -> dict:
    """Deterministic mock generator — gerçekçi test çıktıları üretir.

    Gerçek LLM olmadan çalışır. Test ve geliştirme için.
    """
    if mode == "mod_a":
        return _mock_mod_a(inputs["feature_idea"])
    if mode == "mod_b":
        return _mock_mod_b(inputs["user_story"], inputs["acceptance_criteria"])
    return _mock_bug_report(inputs)


def _mock_mod_a(feature_idea: str) -> dict:
    """Mod A: feature_idea → user_story + AC + test_plan + test_cases"""
    # Feature'dan kısa bir ID üret (deterministik)
    seed = hashlib.md5(feature_idea.encode()).hexdigest()[:4].upper()

    user_story = (
        f"As a user, I want to {feature_idea.lower().rstrip('.')} "
        f"so that I can accomplish my task efficiently and with confidence."
    )

    acceptance_criteria = [
        f"Given the system is ready, when the user initiates '{feature_idea}', "
        f"then the feature should complete successfully within acceptable time limits.",
        f"Given valid input is provided, when '{feature_idea}' is triggered, "
        f"then the expected output should be produced without errors.",
        f"Given invalid or missing input, when '{feature_idea}' is attempted, "
        f"then the system should display a clear and actionable error message.",
        f"Given the user has appropriate permissions, when '{feature_idea}' is used, "
        f"then all actions should be logged for audit purposes.",
    ]

    test_plan = {
        "objective": f"Validate the end-to-end functionality, reliability, and edge-case handling of: {feature_idea}",
        "scope": (
            f"Functional testing of the '{feature_idea}' feature including "
            f"positive flows, negative/error handling, boundary conditions, "
            f"and basic performance validation."
        ),
        "test_types": ["functional", "negative", "boundary", "usability"],
        "approach": (
            "1. Verify happy-path scenario works correctly. "
            "2. Test error handling with invalid inputs. "
            "3. Validate boundary conditions. "
            "4. Confirm UI/UX feedback is appropriate. "
            "5. Check audit logging."
        ),
    }

    test_cases = [
        {
            "id": f"TC-{seed}-001",
            "title": f"Verify successful execution of {feature_idea}",
            "type": "positive",
            "priority": "P0",
            "preconditions": "User is authenticated and has necessary permissions. System is in a stable state.",
            "steps": [
                "Navigate to the relevant feature area",
                f"Initiate '{feature_idea}' with valid input data",
                "Observe the system response and output",
                "Verify the result matches expected behavior",
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
                "Navigate to the relevant feature area",
                f"Attempt '{feature_idea}' with invalid/malformed input",
                "Observe the error response",
                "Verify the error message is clear and actionable",
            ],
            "expected_result": "System displays a meaningful error message without crashing. No data corruption occurs.",
            "tags": ["regression", "negative"],
        },
        {
            "id": f"TC-{seed}-003",
            "title": f"Verify {feature_idea} with empty/missing input",
            "type": "edge_case",
            "priority": "P1",
            "preconditions": "User is authenticated.",
            "steps": [
                "Navigate to the relevant feature area",
                f"Attempt '{feature_idea}' without providing required input",
                "Observe the validation response",
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
                "Prepare input data at minimum boundary value",
                f"Execute '{feature_idea}' with minimum boundary input",
                "Prepare input data at maximum boundary value",
                f"Execute '{feature_idea}' with maximum boundary input",
                "Compare results against expected behavior",
            ],
            "expected_result": "Feature handles both minimum and maximum boundary inputs correctly without overflow or truncation.",
            "tags": ["boundary", "regression"],
        },
        {
            "id": f"TC-{seed}-005",
            "title": f"Verify unauthorized access to {feature_idea}",
            "type": "negative",
            "priority": "P1",
            "preconditions": "User without required permissions is logged in.",
            "steps": [
                "Log in as a user without the necessary permissions",
                f"Attempt to access '{feature_idea}'",
                "Observe the access control response",
            ],
            "expected_result": "System denies access with an appropriate 403/401 error message. No data is exposed.",
            "tags": ["security", "negative"],
        },
    ]

    return {
        "user_story": user_story,
        "acceptance_criteria": acceptance_criteria,
        "test_plan": test_plan,
        "test_cases": test_cases,
    }


def _mock_mod_b(user_story: str, acceptance_criteria: str) -> dict:
    """Mod B: user_story + AC → test_plan + test_cases (story/AC olduğu gibi geçer)"""
    seed = hashlib.md5((user_story + acceptance_criteria).encode()).hexdigest()[:4].upper()

    # AC'yi satırlara ayır
    ac_lines = [
        line.strip()
        for line in acceptance_criteria.replace("\\n", "\n").split("\n")
        if line.strip()
    ]
    if not ac_lines:
        ac_lines = [acceptance_criteria.strip()]

    test_plan = {
        "objective": f"Validate the acceptance criteria for the given user story through comprehensive test coverage.",
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

    # Her AC satırı için en az bir positive test case
    for i, ac in enumerate(ac_lines[:5], start=1):  # Max 5 AC
        test_cases.append({
            "id": f"TC-{seed}-{i:03d}",
            "title": f"Verify: {ac[:80]}{'...' if len(ac) > 80 else ''}",
            "type": "positive",
            "priority": "P0" if i <= 2 else "P1",
            "preconditions": "System is configured and user is authenticated per the user story context.",
            "steps": [
                "Set up the preconditions as described in the acceptance criteria",
                f"Execute the action: {ac[:100]}",
                "Observe the system response",
                "Verify the outcome matches acceptance criteria",
            ],
            "expected_result": f"The acceptance criterion is satisfied: {ac[:120]}",
            "tags": ["acceptance", "regression", "functional"],
        })

    # Negatif test case
    test_cases.append({
        "id": f"TC-{seed}-{len(test_cases)+1:03d}",
        "title": "Verify system behavior with invalid preconditions",
        "type": "negative",
        "priority": "P1",
        "preconditions": "System state does NOT meet the required preconditions.",
        "steps": [
            "Intentionally violate one or more preconditions",
            "Attempt to perform the action described in the user story",
            "Observe the system response",
        ],
        "expected_result": "System gracefully handles the invalid state with clear error messaging. No data corruption.",
        "tags": ["negative", "regression"],
    })

    # Edge case
    test_cases.append({
        "id": f"TC-{seed}-{len(test_cases)+1:03d}",
        "title": "Verify edge case with boundary input values",
        "type": "edge_case",
        "priority": "P2",
        "preconditions": "System is ready. Boundary test data is prepared.",
        "steps": [
            "Prepare boundary/extreme input values",
            "Execute the user story flow with these values",
            "Verify the system handles them correctly",
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
    """Bug report inputlarından deterministic, yapılandırılmış rapor üret."""
    raw_steps = inputs["steps_to_reproduce"]
    if isinstance(raw_steps, list):
        steps = [str(step).strip() for step in raw_steps if str(step).strip()]
    else:
        steps = [
            line.strip(" -\t")
            for line in str(raw_steps).replace("\\n", "\n").split("\n")
            if line.strip(" -\t")
        ]
    if not steps:
        steps = ["Reproduce the issue using the reported user flow."]

    severity = (inputs.get("severity") or "Medium").strip().title()
    severity_priority_map = {
        "Critical": "P0",
        "Blocker": "P0",
        "High": "P1",
        "Major": "P1",
        "Medium": "P2",
        "Minor": "P3",
        "Low": "P3",
    }
    priority = severity_priority_map.get(severity, "P2")

    title = (inputs.get("title") or inputs.get("summary") or "Bug report").strip()
    summary = (
        inputs.get("summary")
        or f"{title}. Actual behavior differs from the expected result and should be investigated."
    ).strip()

    labels = ["bug", "qa-generated", severity.lower().replace(" ", "-")]

    return {
        "bug_report": {
            "title": title,
            "summary": summary,
            "severity": severity,
            "priority": priority,
            "environment": inputs["environment"].strip(),
            "steps_to_reproduce": steps,
            "actual_result": inputs["actual_result"].strip(),
            "expected_result": inputs["expected_result"].strip(),
            "labels": labels,
        }
    }


# ── Gemini Placeholder ─────────────────────────────────

def _generate_with_gemini(mode: str, inputs: dict) -> dict:
    """Gemini API ile üretim yap.

    TODO (Faz 1B): google-generativeai SDK entegrasyonu.
    Prompt şablonları app/prompts/ altında hazır.
    """
    raise NotImplementedError(
        "Gemini integration is not yet implemented. "
        "Set LLM_PROVIDER=mock or provide GEMINI_API_KEY in environment."
    )
