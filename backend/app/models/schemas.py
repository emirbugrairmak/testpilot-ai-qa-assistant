"""
TestPilot – Pydantic Şemaları
==============================
API request / response modelleri.
"""

from __future__ import annotations

from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


# ── Enums ───────────────────────────────────────────────

class GenerationMode(str, Enum):
    """Desteklenen üretim modları."""
    MOD_A = "mod_a"
    MOD_B = "mod_b"
    BUG_REPORT = "bug_report"


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
    title: Optional[str] = Field(
        None,
        min_length=3,
        max_length=300,
        description="Bug report için başlık",
    )
    summary: Optional[str] = Field(
        None,
        min_length=5,
        max_length=1000,
        description="Bug report için kısa özet",
    )
    steps_to_reproduce: Optional[str | list[str]] = Field(
        None,
        description="Bug report için yeniden üretme adımları",
    )
    actual_result: Optional[str] = Field(
        None,
        min_length=3,
        max_length=3000,
        description="Bug report için mevcut/gerçek sonuç",
    )
    expected_result: Optional[str] = Field(
        None,
        min_length=3,
        max_length=3000,
        description="Bug report için beklenen sonuç",
    )
    environment: Optional[str] = Field(
        None,
        min_length=2,
        max_length=1000,
        description="Bug report için ortam bilgisi",
    )
    severity: Optional[str] = Field(
        None,
        min_length=2,
        max_length=50,
        description="Bug report severity değeri (opsiyonel)",
    )

    template_id: Optional[int] = Field(
        None,
        description="Premium: kullanmak istediğiniz template ID'si",
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
                {
                    "mode": "bug_report",
                    "title": "Login button stays disabled",
                    "steps_to_reproduce": [
                        "Open the login page",
                        "Enter a valid email and password",
                        "Try to click Login",
                    ],
                    "actual_result": "The Login button remains disabled.",
                    "expected_result": "The user can submit the login form.",
                    "environment": "Chrome 123, macOS",
                    "severity": "High",
                },
            ]
        }


class FreeAccessCreateRequest(BaseModel):
    """POST /api/v1/auth/access/free isteği."""
    owner_name: Optional[str] = Field(
        None,
        max_length=120,
        description="Anahtar etiketi: ad, ekip veya çalışma alanı adı",
    )


class PremiumAccessCreateRequest(BaseModel):
    """POST /api/v1/auth/access/premium isteği."""
    owner_name: str = Field(
        ...,
        min_length=2,
        max_length=120,
        description="Satın alma simülasyonu için ad, ekip veya kurum adı",
    )
    plan_summary: Optional[str] = Field(
        "Premium monthly simulation",
        max_length=200,
        description="UI'da onaylanan plan özeti",
    )


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


class BugReportSchema(BaseModel):
    """Bug report üretim çıktısı."""
    title: str
    summary: str
    severity: str
    priority: str
    environment: str
    steps_to_reproduce: list[str]
    actual_result: str
    expected_result: str
    labels: list[str]


class GenerateResponse(BaseModel):
    """POST /api/v1/generate yanıtı."""
    generation_id: int
    display_id: int
    mode: GenerationMode
    provider: Optional[str] = None
    user_story: Optional[str] = None
    acceptance_criteria: list[str] = Field(default_factory=list)
    test_plan: Optional[TestPlanSchema] = None
    test_cases: list[TestCaseSchema] = Field(default_factory=list)
    bug_report: Optional[BugReportSchema] = None
    tags: list[str] = Field(default_factory=list)
    markdown: Optional[str] = None
    watermark: Optional[str] = None
    plan_stamp: Optional[dict[str, str]] = None
    created_at: str


class HistoryItem(BaseModel):
    """History liste elemanı."""
    generation_id: int
    display_id: int
    mode: GenerationMode
    input: dict[str, Any]
    output_summary: str
    created_at: str


class HistoryListResponse(BaseModel):
    """GET /api/v1/history yanıtı."""
    items: list[HistoryItem]
    count: int
    plan: PlanType
    limit: Optional[int] = None


class HistoryDetailResponse(BaseModel):
    """GET /api/v1/history/{id} yanıtı."""
    generation_id: int
    display_id: int
    mode: GenerationMode
    input: dict[str, Any]
    output: dict[str, Any]
    markdown: str
    created_at: str


class DeleteHistoryResponse(BaseModel):
    """DELETE /api/v1/history/{id} yanıtı."""
    deleted: bool
    generation_id: int


class UsageResponse(BaseModel):
    """GET /api/v1/usage yanıtı."""
    plan: PlanType
    monthly_limit: int
    usage_count: int
    remaining: int
    usage_reset_at: str


class AuthValidateResponse(BaseModel):
    """POST /api/v1/auth/validate yanıtı."""
    valid: bool
    plan: str
    owner_name: str
    issued_via: Optional[str] = None
    monthly_limit: int
    usage_count: int
    remaining: int
    usage_resets_at: str


class AccessKeyCreateResponse(BaseModel):
    """Yeni access key oluşturma yanıtı."""
    access_key: str
    plan: PlanType
    owner_name: str
    issued_via: str
    monthly_limit: int
    usage_count: int
    remaining: int
    usage_resets_at: str
    created_at: str


class ExportVerifyRequest(BaseModel):
    """POST /api/v1/export/verify isteği."""
    content: str = Field(..., min_length=1, description="JSON veya Markdown export içeriği")
    format: Optional[str] = Field(
        None,
        description="Opsiyonel format ipucu: json veya markdown",
    )


class ExportVerifyResponse(BaseModel):
    """Export provenance doğrulama yanıtı."""
    valid: bool
    signature_valid: bool
    payload_changed: bool
    is_testpilot_free_export: bool
    format: str
    reason: str
    export_meta: Optional[dict[str, str]] = None


# ── Template Schemas ────────────────────────────────────

class TemplateCreate(BaseModel):
    """POST /api/v1/templates isteği."""
    name: str = Field(..., min_length=1, max_length=200, description="Template adı")
    prompt_text: str = Field(..., min_length=10, max_length=10000, description="Prompt metni")


class TemplateUpdate(BaseModel):
    """PUT /api/v1/templates/{id} isteği."""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    prompt_text: Optional[str] = Field(None, min_length=10, max_length=10000)


class TemplateResponse(BaseModel):
    """Tekil template yanıtı."""
    id: int
    name: str
    prompt_text: str
    created_at: str
    updated_at: str


class TemplateListResponse(BaseModel):
    """GET /api/v1/templates yanıtı."""
    items: list[TemplateResponse]
    count: int


# ── Batch Schemas ───────────────────────────────────────

class BatchItem(BaseModel):
    """Batch içindeki tek bir üretim girdisi."""
    feature_idea: Optional[str] = Field(None, min_length=5, max_length=2000)
    user_story: Optional[str] = Field(None, min_length=10, max_length=3000)
    acceptance_criteria: Optional[str] = Field(None, min_length=10, max_length=5000)
    template_id: Optional[int] = None


class BatchGenerateRequest(BaseModel):
    """POST /api/v1/generate/batch isteği."""
    mode: GenerationMode = Field(..., description="mod_a veya mod_b (batch bug_report desteklenmiyor)")
    items: list[BatchItem] = Field(..., min_length=1, max_length=10, description="Max 10 öğe")
    template_id: Optional[int] = Field(None, description="Tüm batch için ortak template (item seviyesinde override edilebilir)")


class BatchResultItem(BaseModel):
    """Batch sonuçlarından tek bir öğe."""
    index: int
    success: bool
    generation_id: Optional[int] = None
    display_id: Optional[int] = None
    result: Optional[dict[str, Any]] = None
    error: Optional[str] = None


class BatchGenerateResponse(BaseModel):
    """POST /api/v1/generate/batch yanıtı."""
    mode: GenerationMode
    total_items: int
    success_count: int
    failed_count: int
    results: list[BatchResultItem]


# ── Error ───────────────────────────────────────────────

class ErrorResponse(BaseModel):
    """Hata yanıtı."""
    detail: str
