"""
TestPilot – Auth Router
=========================
Kimlik doğrulama endpoint'leri.
"""

from fastapi import APIRouter, Depends

from app.models.schemas import AuthValidateResponse
from app.utils.auth import get_api_key_info

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/validate",
    response_model=AuthValidateResponse,
    summary="API Key Doğrulama",
    description="Bearer token ile API key'i doğrular ve plan bilgisini döndürür.",
)
def validate_api_key(key_info: dict = Depends(get_api_key_info)):
    """API key'in geçerli olup olmadığını kontrol et.

    Başarılı yanıt: plan, kalan kullanım hakkı, sıfırlama tarihi vb.
    """
    return AuthValidateResponse(
        valid=True,
        plan=key_info["plan"],
        owner_name=key_info["owner_name"],
        monthly_limit=key_info["monthly_limit"],
        usage_count=key_info["usage_count"],
        remaining=key_info["monthly_limit"] - key_info["usage_count"],
        usage_resets_at=key_info["usage_reset_at"],
    )
