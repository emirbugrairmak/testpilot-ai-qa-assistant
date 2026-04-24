"""
TestPilot – Templates Router
==============================
Custom template CRUD endpoint'leri (Premium only).
"""

from fastapi import APIRouter, Depends, status

from app.models.schemas import (
    TemplateCreate,
    TemplateListResponse,
    TemplateResponse,
    TemplateUpdate,
)
from app.services.template_service import (
    create_template,
    delete_template,
    list_templates,
    update_template,
)
from app.utils.auth import get_api_key_info

router = APIRouter(prefix="/templates", tags=["Templates"])


@router.get(
    "",
    response_model=TemplateListResponse,
    summary="Template Listesi (Premium)",
    description="Kullanıcının kendi custom template'lerini listele. Sadece Premium.",
)
def get_templates(key_info: dict = Depends(get_api_key_info)):
    """Kullanıcının template'lerini getir."""
    items = list_templates(key_info)
    return TemplateListResponse(
        items=[TemplateResponse(**t) for t in items],
        count=len(items),
    )


@router.post(
    "",
    response_model=TemplateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Template Oluştur (Premium)",
    description="Yeni custom template oluştur. Sadece Premium.",
    responses={403: {"description": "Premium plan required"}},
)
def post_template(
    body: TemplateCreate,
    key_info: dict = Depends(get_api_key_info),
):
    """Yeni template oluştur."""
    template = create_template(key_info, name=body.name, prompt_text=body.prompt_text)
    return TemplateResponse(**template)


@router.put(
    "/{template_id}",
    response_model=TemplateResponse,
    summary="Template Güncelle (Premium)",
    description="Mevcut template'i güncelle. Sadece sahibi ve Premium.",
    responses={
        403: {"description": "Premium plan required"},
        404: {"description": "Template not found"},
    },
)
def put_template(
    template_id: int,
    body: TemplateUpdate,
    key_info: dict = Depends(get_api_key_info),
):
    """Template güncelle."""
    template = update_template(key_info, template_id, name=body.name, prompt_text=body.prompt_text)
    return TemplateResponse(**template)


@router.delete(
    "/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Template Sil (Premium)",
    description="Template'i sil. Sadece sahibi ve Premium.",
    responses={
        403: {"description": "Premium plan required"},
        404: {"description": "Template not found"},
    },
)
def remove_template(
    template_id: int,
    key_info: dict = Depends(get_api_key_info),
):
    """Template sil."""
    delete_template(key_info, template_id)
    # 204 No Content — body yok
