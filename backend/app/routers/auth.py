"""
TestPilot – Auth Router
=========================
Kimlik doğrulama endpoint'leri.
"""

from fastapi import APIRouter, Depends, HTTPException, status

from app.models.schemas import (
    AccessKeyCreateResponse,
    AuthValidateResponse,
    FreeAccessCreateRequest,
    PremiumAccessCreateRequest,
)
from app.services.access_key_service import create_access_key
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
        issued_via=key_info.get("issued_via"),
        monthly_limit=key_info["monthly_limit"],
        usage_count=key_info["usage_count"],
        remaining=key_info["monthly_limit"] - key_info["usage_count"],
        usage_resets_at=key_info["usage_reset_at"],
    )


@router.post(
    "/access/free",
    response_model=AccessKeyCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Free access key oluştur",
    description="Hesap sistemi kurmadan yeni ve kalıcı bir Free erişim anahtarı üretir.",
)
def create_free_access(body: FreeAccessCreateRequest):
    """Free plan için boş usage/history/template alanına sahip key oluştur."""
    owner_name = (body.owner_name or "").strip() or "Free Workspace"
    row = create_access_key(
        plan="free",
        owner_name=owner_name,
        issued_via="free_access",
    )
    return _to_access_key_response(row)


@router.post(
    "/access/premium",
    response_model=AccessKeyCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Premium purchase simulation access key oluştur",
    description=(
        "Gerçek ödeme almadan Premium satın alma simülasyonunu tamamlar ve "
        "kalıcı Premium erişim anahtarı üretir."
    ),
)
def create_premium_access(body: PremiumAccessCreateRequest):
    """Premium plan simülasyonu sonrası key oluştur."""
    owner_name = body.owner_name.strip()
    if not owner_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="owner_name is required",
        )

    row = create_access_key(
        plan="premium",
        owner_name=owner_name,
        issued_via="premium_simulation",
    )
    return _to_access_key_response(row)


def _to_access_key_response(row: dict) -> AccessKeyCreateResponse:
    return AccessKeyCreateResponse(
        access_key=row["key"],
        plan=row["plan"],
        owner_name=row["owner_name"],
        issued_via=row["issued_via"],
        monthly_limit=row["monthly_limit"],
        usage_count=row["usage_count"],
        remaining=row["monthly_limit"] - row["usage_count"],
        usage_resets_at=row["usage_reset_at"],
        created_at=row["created_at"],
    )
