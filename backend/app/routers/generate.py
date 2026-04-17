"""
TestPilot – Generate Router
==============================
Test üretimi endpoint'leri.
"""

from fastapi import APIRouter, Depends, HTTPException, status

from app.models.schemas import GenerateRequest, GenerateResponse, GenerationMode
from app.services.generation_service import run_generation
from app.utils.auth import check_usage_limit, get_api_key_info, increment_usage

router = APIRouter(tags=["Generate"])


@router.post(
    "/generate",
    response_model=GenerateResponse,
    summary="Test Üretimi",
    description=(
        "Mod A: feature_idea → user story + AC + test plan + test cases.\n\n"
        "Mod B: user_story + acceptance_criteria → test plan + test cases."
    ),
    responses={
        401: {"description": "Invalid or missing API key"},
        422: {"description": "Validation error"},
        429: {"description": "Monthly usage limit exceeded"},
    },
)
def generate(
    request: GenerateRequest,
    key_info: dict = Depends(get_api_key_info),
):
    """Test üretimi yap.

    1. Input doğrulama (mode'a göre gerekli alanlar)
    2. Kullanım limiti kontrolü
    3. LLM/Mock ile üretim
    4. DB'ye kayıt
    5. Kullanım sayacını artır
    """
    # ── 1. Mode-specific validation ────────────────
    if request.mode == GenerationMode.MOD_A:
        if not request.feature_idea:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'feature_idea' is required for mod_a",
            )
        inputs = {"feature_idea": request.feature_idea}

    elif request.mode == GenerationMode.MOD_B:
        if not request.user_story:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'user_story' is required for mod_b",
            )
        if not request.acceptance_criteria:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="'acceptance_criteria' is required for mod_b",
            )
        inputs = {
            "user_story": request.user_story,
            "acceptance_criteria": request.acceptance_criteria,
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Unsupported mode: {request.mode}",
        )

    # ── 2. Usage limit check ──────────────────────
    check_usage_limit(key_info)

    # ── 3. Generate ───────────────────────────────
    result = run_generation(
        mode=request.mode.value,
        inputs=inputs,
        key_info=key_info,
    )

    # ── 4. Increment usage counter ────────────────
    increment_usage(key_info["id"])

    # ── 5. Response ───────────────────────────────
    return GenerateResponse(**result)
