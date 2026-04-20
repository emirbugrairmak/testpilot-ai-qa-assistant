"""
TestPilot – Usage Router
=========================
Plan ve aylık kullanım bilgisi endpoint'i.
"""

from fastapi import APIRouter, Depends

from app.models.schemas import UsageResponse
from app.utils.auth import get_api_key_info

router = APIRouter(tags=["Usage"])


@router.get(
    "/usage",
    response_model=UsageResponse,
    summary="Kullanım bilgisi",
    description="API key planı, aylık limit, kullanılan hak ve kalan hakkı döndürür.",
)
def usage(key_info: dict = Depends(get_api_key_info)):
    """Aktif API key'in kullanım özetini döndür."""
    return UsageResponse(
        plan=key_info["plan"],
        monthly_limit=key_info["monthly_limit"],
        usage_count=key_info["usage_count"],
        remaining=max(key_info["monthly_limit"] - key_info["usage_count"], 0),
        usage_reset_at=key_info["usage_reset_at"],
    )
