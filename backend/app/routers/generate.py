"""
TestPilot – Generate Router
==============================
Test üretimi endpoint'leri: single generate + batch generate.
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.models.schemas import (
    BatchGenerateRequest,
    BatchGenerateResponse,
    BatchResultItem,
    GenerateRequest,
    GenerateResponse,
    GenerationMode,
)
from app.services.generation_service import run_generation
from app.services.template_service import get_template_prompt
from app.utils.auth import check_usage_limit, get_api_key_info, increment_usage

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Generate"])


# ── Helpers ─────────────────────────────────────────────

def _validate_and_build_inputs(mode: GenerationMode, request_data: dict) -> dict:
    """Mode-specific alan doğrulaması yap ve inputs dict oluştur.

    Args:
        mode: GenerationMode
        request_data: request alanlarını içeren dict (feature_idea, user_story vb.)

    Returns:
        LLM'e gönderilecek inputs dict

    Raises:
        HTTPException 422: Gerekli alan eksikse
    """
    if mode == GenerationMode.MOD_A:
        feature_idea = request_data.get("feature_idea")
        if not feature_idea:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'feature_idea' is required for mod_a",
            )
        return {"feature_idea": feature_idea}

    elif mode == GenerationMode.MOD_B:
        user_story = request_data.get("user_story")
        acceptance_criteria = request_data.get("acceptance_criteria")
        if not user_story:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'user_story' is required for mod_b",
            )
        if not acceptance_criteria:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'acceptance_criteria' is required for mod_b",
            )
        return {"user_story": user_story, "acceptance_criteria": acceptance_criteria}

    elif mode == GenerationMode.BUG_REPORT:
        title = request_data.get("title")
        summary = request_data.get("summary")
        steps = request_data.get("steps_to_reproduce")
        actual = request_data.get("actual_result")
        expected = request_data.get("expected_result")
        environment = request_data.get("environment")

        if not title and not summary:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'title' or 'summary' is required for bug_report",
            )
        if not steps:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'steps_to_reproduce' is required for bug_report",
            )
        if not actual:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'actual_result' is required for bug_report",
            )
        if not expected:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'expected_result' is required for bug_report",
            )
        if not environment:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'environment' is required for bug_report",
            )
        return {
            "title": title,
            "summary": summary,
            "steps_to_reproduce": steps,
            "actual_result": actual,
            "expected_result": expected,
            "environment": environment,
            "severity": request_data.get("severity"),
        }

    raise HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail=f"Unsupported mode: {mode}",
    )


def _apply_template(inputs: dict, template_prompt: str) -> dict:
    """Template prompt'unu inputs'a ekle.

    LLM'e gidecek inputs dict'e 'custom_template_hint' anahtarı olarak eklenir.
    llm_service bu alanı görürse system prompt'a append eder.
    """
    inputs = dict(inputs)
    inputs["custom_template_hint"] = template_prompt
    return inputs


# ── Single Generate ─────────────────────────────────────

@router.post(
    "/generate",
    response_model=GenerateResponse,
    response_model_exclude_none=True,
    response_model_exclude_defaults=True,
    summary="Test / Bug Report Üretimi",
    description=(
        "Mod A: feature_idea → user story + AC + test plan + test cases.\n\n"
        "Mod B: user_story + acceptance_criteria → test plan + test cases.\n\n"
        "Bug Report: bug bilgileri → yapılandırılmış bug report.\n\n"
        "Premium: `template_id` ile custom template kullanılabilir."
    ),
    responses={
        401: {"description": "Invalid or missing API key"},
        403: {"description": "Premium required (template_id kullanımı)"},
        422: {"description": "Validation error"},
        429: {"description": "Monthly usage limit exceeded"},
    },
)
def generate(
    request: GenerateRequest,
    key_info: dict = Depends(get_api_key_info),
):
    """Test üretimi yap.

    1. Input doğrulama
    2. Template çözümle (varsa, premium only)
    3. Kullanım limiti kontrolü
    4. LLM/Mock ile üretim
    5. DB'ye kayıt + kullanım sayacını artır
    """
    # ── 1. Input validation ───────────────────────────
    inputs = _validate_and_build_inputs(request.mode, request.model_dump())

    # ── 2. Template entegrasyonu (premium only) ───────
    if request.template_id is not None:
        template_prompt = get_template_prompt(key_info, request.template_id)
        inputs = _apply_template(inputs, template_prompt)

    # ── 3. Usage limit check ──────────────────────────
    check_usage_limit(key_info)

    # ── 4. Generate ───────────────────────────────────
    try:
        result = run_generation(
            mode=request.mode.value,
            inputs=inputs,
            key_info=key_info,
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc

    # ── 5. Increment usage counter ────────────────────
    increment_usage(key_info["id"])

    return GenerateResponse(**result)


# ── Batch Generate ──────────────────────────────────────

@router.post(
    "/generate/batch",
    response_model=BatchGenerateResponse,
    summary="Batch Test Üretimi (Premium)",
    description=(
        "Birden fazla girdi için sequential test üretimi. Sadece Premium.\n\n"
        "Max 10 öğe. Mod A veya Mod B desteklenir (bug_report batch desteklenmiyor).\n\n"
        "Her öğe ayrı ayrı işlenir. Bir öğe hata verirse diğerleri etkilenmez.\n\n"
        "Her başarılı üretim usage sayacını 1 artırır."
    ),
    responses={
        401: {"description": "Invalid or missing API key"},
        403: {"description": "Premium plan required"},
        422: {"description": "Validation error"},
        429: {"description": "Monthly usage limit exceeded"},
    },
)
def batch_generate(
    request: BatchGenerateRequest,
    key_info: dict = Depends(get_api_key_info),
):
    """Batch test üretimi (Premium only, sequential).

    1. Premium kontrolü
    2. Bug report mode block
    3. Her öğe için:
       a. Input doğrulama
       b. Template çözümle
       c. Usage limit kontrolü
       d. Üretim + kayıt + sayaç artırımı
    """
    # ── 1. Premium kontrolü ───────────────────────────
    if key_info.get("plan") != "premium":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Batch generation is available for Premium plan users only.",
        )

    # ── 2. Bug report batch desteklenmiyor ───────────
    if request.mode == GenerationMode.BUG_REPORT:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Batch mode is not supported for bug_report. Use single /generate instead.",
        )

    # ── 3. Batch template (isteğe bağlı) ─────────────
    batch_template_prompt: str | None = None
    if request.template_id is not None:
        batch_template_prompt = get_template_prompt(key_info, request.template_id)

    # ── 4. Sequential işle ────────────────────────────
    results: list[BatchResultItem] = []
    success_count = 0
    failed_count = 0

    for idx, item in enumerate(request.items):
        try:
            # Item-level input build
            item_data = {
                "feature_idea": item.feature_idea,
                "user_story": item.user_story,
                "acceptance_criteria": item.acceptance_criteria,
            }
            inputs = _validate_and_build_inputs(request.mode, item_data)

            # Item-level template override (yoksa batch-level template kullan)
            effective_template_prompt = batch_template_prompt
            if item.template_id is not None:
                effective_template_prompt = get_template_prompt(key_info, item.template_id)

            if effective_template_prompt:
                inputs = _apply_template(inputs, effective_template_prompt)

            # Usage limit — her öğeden önce kontrol
            check_usage_limit(key_info)

            # Üret
            result = run_generation(
                mode=request.mode.value,
                inputs=inputs,
                key_info=key_info,
            )

            # Sayacı artır ve key_info'yu güncelle (sonraki iteration için)
            increment_usage(key_info["id"])
            key_info["usage_count"] = key_info.get("usage_count", 0) + 1

            results.append(BatchResultItem(
                index=idx,
                success=True,
                generation_id=result.get("generation_id"),
                display_id=result.get("display_id"),
                result=result,
            ))
            success_count += 1

        except HTTPException as exc:
            # 429 (limit) veya 422 (validation) → bu item başarısız, devam et
            results.append(BatchResultItem(
                index=idx,
                success=False,
                error=exc.detail,
            ))
            failed_count += 1
            # 429 gelirse sonraki item'lar da başarısız olacak ama işlemeye devam et
            logger.warning("Batch item %d failed: %s", idx, exc.detail)

        except Exception as exc:
            results.append(BatchResultItem(
                index=idx,
                success=False,
                error=str(exc),
            ))
            failed_count += 1
            logger.exception("Batch item %d unexpected error", idx)

    return BatchGenerateResponse(
        mode=request.mode,
        total_items=len(request.items),
        success_count=success_count,
        failed_count=failed_count,
        results=results,
    )
