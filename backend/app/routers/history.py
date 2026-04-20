"""
TestPilot – History Router
===========================
Generation geçmişi endpoint'leri.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.models.schemas import (
    DeleteHistoryResponse,
    GenerationMode,
    HistoryDetailResponse,
    HistoryListResponse,
)
from app.services.history_service import (
    delete_generation,
    get_generation_detail,
    list_generations,
)
from app.utils.auth import get_api_key_info

router = APIRouter(prefix="/history", tags=["History"])


@router.get(
    "",
    response_model=HistoryListResponse,
    summary="Generation geçmişi",
    description="API key'e ait generation kayıtlarını listeler. Free plan son 15 kayıtla sınırlıdır.",
)
def history_list(
    mode: GenerationMode | None = Query(None, description="mod_a, mod_b veya bug_report"),
    q: str | None = Query(None, min_length=1, max_length=200, description="Input/output içinde basit arama"),
    key_info: dict = Depends(get_api_key_info),
):
    """Sadece ilgili API key'in kayıtlarını listeler."""
    result = list_generations(
        api_key_id=key_info["id"],
        plan=key_info["plan"],
        mode=mode.value if mode else None,
        q=q,
    )
    return HistoryListResponse(**result)


@router.get(
    "/{generation_id}",
    response_model=HistoryDetailResponse,
    summary="Generation detayı",
)
def history_detail(
    generation_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """Sadece ilgili API key'in kendi kaydını döndürür."""
    record = get_generation_detail(key_info["id"], generation_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Generation not found",
        )
    return HistoryDetailResponse(**record)


@router.delete(
    "/{generation_id}",
    response_model=DeleteHistoryResponse,
    summary="Generation sil",
)
def history_delete(
    generation_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """Sadece ilgili API key'in kendi kaydını siler."""
    deleted = delete_generation(key_info["id"], generation_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Generation not found",
        )
    return DeleteHistoryResponse(deleted=True, generation_id=generation_id)
