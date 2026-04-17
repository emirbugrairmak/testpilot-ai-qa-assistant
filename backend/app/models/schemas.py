"""
TestPilot – Pydantic Şemaları
==============================
API request / response modelleri.
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


# ── Enums ───────────────────────────────────────────────

class GenerationMode(str, Enum):
    """Desteklenen üretim modları."""
    MOD_A = "mod_a"
    MOD_B = "mod_b"


class PlanType(str, Enum):
    """Kullanıcı plan türleri."""
    FREE = "free"
    PREMIUM = "premium"


# ── Request Schemas ─────────────────────────────────────

class GenerateRequest(BaseModel):
    """POST /api/v1/generate isteği."""
    mode: GenerationMode
    feature_idea: Optional[str] = Field(
        None,
        min_length=5,
        max_length=2000,
        description="Mod A için özellik fikri",
    )
    user_story: Optional[str] = Field(
        None,
        min_length=10,
        max_length=3000,
        description="Mod B için user story",
    )
    acceptance_criteria: Optional[str] = Field(
        None,
        min_length=10,
        max_length=5000,
        description="Mod B için kabul kriterleri",
    )

    class Config:
        json_schema_extra = {
            "examples": [
                {
                    "mode": "mod_a",
                    "feature_idea": "User login with email and password",
                },
                {
                    "mode": "mod_b",
                    "user_story": "As a user, I want to reset my password so that I can regain access to my account",
                    "acceptance_criteria": "Given a registered user, when they click 'Forgot Password' and enter their email, then they receive a reset link within 5 minutes",
                },
            ]
        }


# ── Response Schemas ────────────────────────────────────

class TestCaseSchema(BaseModel):
    """Tek bir test case."""
    id: str
    title: str
    type: str = Field(..., description="positive | negative | edge_case | boundary")
    priority: str = Field(..., description="P0 | P1 | P2")
    preconditions: str
    steps: list[str]
    expected_result: str
    tags: list[str]


class TestPlanSchema(BaseModel):
    """Test planı özeti."""
    objective: str
    scope: str
    test_types: list[str]
    approach: str


class GenerateResponse(BaseModel):
    """POST /api/v1/generate yanıtı."""
    generation_id: int
    mode: GenerationMode
    user_story: str
    acceptance_criteria: list[str]
    test_plan: TestPlanSchema
    test_cases: list[TestCaseSchema]
    tags: list[str]
    watermark: Optional[str] = None
    created_at: str


class AuthValidateResponse(BaseModel):
    """POST /api/v1/auth/validate yanıtı."""
    valid: bool
    plan: str
    owner_name: str
    monthly_limit: int
    usage_count: int
    remaining: int
    usage_resets_at: str


class ErrorResponse(BaseModel):
    """Hata yanıtı."""
    detail: str
