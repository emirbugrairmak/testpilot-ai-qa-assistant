"""
TestPilot – Bug Report Prompt Şablonu
=====================================
Bug report modu: Kısa bug bilgisi → yapılandırılmış JSON + markdown rapor.

İleride gerçek LLM entegrasyonunda bu şablon prompt olarak kullanılacak.
"""

BUG_REPORT_SYSTEM_PROMPT = """You are TestPilot, an expert QA engineer assistant.
Given raw bug information, create a clear and actionable bug report.
The report must include title, summary, severity, priority, environment,
steps to reproduce, actual result, expected result, and labels.

Output must be structured JSON matching the required schema.
Use concise, professional QA language. Do not invent unsupported facts."""

BUG_REPORT_USER_PROMPT_TEMPLATE = """Title: {title}
Summary: {summary}
Steps to Reproduce: {steps_to_reproduce}
Actual Result: {actual_result}
Expected Result: {expected_result}
Environment: {environment}
Severity: {severity}

Generate a complete bug report.
Return a JSON object with the following structure:
{{
  "bug_report": {{
    "title": "...",
    "summary": "...",
    "severity": "Critical|High|Medium|Low",
    "priority": "P0|P1|P2|P3",
    "environment": "...",
    "steps_to_reproduce": ["Step 1", "Step 2"],
    "actual_result": "...",
    "expected_result": "...",
    "labels": ["bug", "qa-generated"]
  }}
}}"""
