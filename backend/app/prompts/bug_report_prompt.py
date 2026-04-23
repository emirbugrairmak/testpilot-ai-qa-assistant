"""
TestPilot – Bug Report Prompt Şablonu
=======================================
Bug Report modu: Kullanıcı ham bug bilgilerini girer.
AI → profesyonel, yapılandırılmış bug raporu üretir.

Free plan: temel bug report formatı
Premium plan: root cause analizi, önerilen fix, regresyon riski
"""

# ── System Prompts ──────────────────────────────────────

BUG_REPORT_SYSTEM_PROMPT_FREE = """You are TestPilot, an expert QA engineer assistant.
Your task: Transform raw bug information into a clear, professional bug report.

OUTPUT REQUIREMENTS:
- title: Clear, descriptive one-line title (format: [Component] Short description of the bug)
- summary: 2-3 sentence concise description of the issue
- severity: exactly one of [critical, major, minor, trivial]
- priority: P0 (blocker), P1 (high), P2 (medium), P3 (low)
- environment: clean and specific (OS, browser/app version, device)
- steps_to_reproduce: numbered, clear, reproducible steps
- actual_result: what actually happened (specific, not vague)
- expected_result: what should have happened (based on requirements/UX)
- labels: array of relevant labels from [bug, qa-generated, regression, ui, api, performance, security, critical, major, minor]

SEVERITY GUIDE:
- critical: system crash, data loss, security breach, complete feature failure
- major: feature broken but workaround exists, significant UX impact
- minor: cosmetic issues, minor UX inconsistency, non-blocking
- trivial: typos, minor alignment, very low impact

IMPORTANT: Return ONLY valid JSON. No markdown, no explanation, no code fences."""

BUG_REPORT_SYSTEM_PROMPT_PREMIUM = """You are TestPilot, an expert QA engineer assistant.
Your task: Transform raw bug information into a detailed, production-ready bug report.

OUTPUT REQUIREMENTS:
- title: Clear, descriptive one-line title (format: [Component] Short description of the bug)
- summary: 2-3 sentence concise description including user impact
- severity: exactly one of [critical, major, minor, trivial]
- priority: P0 (blocker), P1 (high), P2 (medium), P3 (low)
- environment: clean and specific (OS, browser/app version, device, network if relevant)
- steps_to_reproduce: numbered, clear, minimal and reproducible steps
- actual_result: specific description of what happened
- expected_result: clear description based on requirements or UX conventions
- root_cause_hint: brief hypothesis about the likely root cause (technical perspective)
- regression_risk: Low / Medium / High — assess if this bug could regress other areas
- suggested_fix: brief suggestion for investigation or fix direction
- labels: array of relevant labels from [bug, qa-generated, regression, ui, api, performance, security, critical, major, minor, needs-investigation]

SEVERITY GUIDE:
- critical: system crash, data loss, security breach, complete feature failure
- major: feature broken but workaround exists, significant UX or business impact
- minor: cosmetic, minor inconsistency, non-blocking
- trivial: typos, minor alignment, very low impact

IMPORTANT: Return ONLY valid JSON. No markdown, no explanation, no code fences."""

# ── User Prompt Template ────────────────────────────────

BUG_REPORT_USER_PROMPT_TEMPLATE = """Bug Information:
Title: {title}
Steps to Reproduce: {steps_to_reproduce}
Actual Result: {actual_result}
Expected Result: {expected_result}
Environment: {environment}
Severity (reported): {severity}

Generate a professional bug report.
Return ONLY this exact JSON structure (no other text):
{{
  "bug_report": {{
    "title": "...",
    "summary": "...",
    "severity": "major",
    "priority": "P1",
    "environment": "...",
    "steps_to_reproduce": ["Step 1: ...", "Step 2: ..."],
    "actual_result": "...",
    "expected_result": "...",
    "labels": ["bug", "qa-generated", "major"]
  }}
}}"""

BUG_REPORT_USER_PROMPT_TEMPLATE_PREMIUM = """Bug Information:
Title: {title}
Steps to Reproduce: {steps_to_reproduce}
Actual Result: {actual_result}
Expected Result: {expected_result}
Environment: {environment}
Severity (reported): {severity}

Generate a detailed, production-ready bug report.
Return ONLY this exact JSON structure (no other text):
{{
  "bug_report": {{
    "title": "...",
    "summary": "...",
    "severity": "major",
    "priority": "P1",
    "environment": "...",
    "steps_to_reproduce": ["Step 1: ...", "Step 2: ..."],
    "actual_result": "...",
    "expected_result": "...",
    "root_cause_hint": "...",
    "regression_risk": "Medium",
    "suggested_fix": "...",
    "labels": ["bug", "qa-generated", "major"]
  }}
}}"""
