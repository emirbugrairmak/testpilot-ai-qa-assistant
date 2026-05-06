"""
TestPilot – Export Router
==========================
Generation export endpoint'leri.
"""

from collections.abc import Callable

from fastapi import APIRouter, Depends, HTTPException, Response, status

from app.services.export_service import (
    export_filename,
    get_owned_generation,
    to_csv_export,
    to_jira_export,
    to_json_export,
    to_markdown_export,
)
from app.utils.auth import get_api_key_info

router = APIRouter(prefix="/export", tags=["Export"])


@router.get("/{generation_id}/json", summary="JSON export")
def export_json(
    generation_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """JSON export: free ve premium için açık."""
    return _export_record(
        generation_id=generation_id,
        key_info=key_info,
        renderer=to_json_export,
        extension="json",
        media_type="application/json",
    )


@router.get("/{generation_id}/markdown", summary="Markdown export")
def export_markdown(
    generation_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """Markdown export: free ve premium için açık."""
    return _export_record(
        generation_id=generation_id,
        key_info=key_info,
        renderer=to_markdown_export,
        extension="md",
        media_type="text/markdown; charset=utf-8",
    )


@router.get("/{generation_id}/csv", summary="CSV export")
def export_csv(
    generation_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """CSV export: sadece premium."""
    _require_premium(key_info)
    return _export_record(
        generation_id=generation_id,
        key_info=key_info,
        renderer=to_csv_export,
        extension="csv",
        media_type="text/csv; charset=utf-8",
    )


@router.get("/{generation_id}/jira", summary="Jira-friendly export")
def export_jira(
    generation_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """Jira-friendly export: sadece premium."""
    _require_premium(key_info)
    return _export_record(
        generation_id=generation_id,
        key_info=key_info,
        renderer=to_jira_export,
        extension="txt",
        suffix="jira",
        media_type="text/plain; charset=utf-8",
    )


def _export_record(
    generation_id: int,
    key_info: dict,
    renderer: Callable[[dict], str],
    extension: str,
    media_type: str,
    suffix: str | None = None,
) -> Response:
    record = get_owned_generation(key_info["id"], generation_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Generation not found",
        )

    content = renderer(record)
    headers = {
        "Content-Disposition": f'attachment; filename="{export_filename(record, extension, suffix=suffix)}"'
    }
    return Response(content=content, media_type=media_type, headers=headers)


def _require_premium(key_info: dict) -> None:
    if key_info["plan"] != "premium":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This export format is available for premium plans only",
        )
