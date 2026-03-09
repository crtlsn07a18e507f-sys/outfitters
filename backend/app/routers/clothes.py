import os
import uuid
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from ..database import get_db
from ..models import ClothingItem
from ..schemas import ClothingResponse, ClothingStats
from ..services.ai_service import analyze_clothing_image
from ..config import settings

router = APIRouter(prefix="/clothes", tags=["clothes"])

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_BYTES = settings.max_image_size_mb * 1024 * 1024


@router.post("/upload", response_model=ClothingResponse)
async def upload_clothing(
    user_id: str = Form(...),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    # Validate extension
    ext = Path(file.filename or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"Unsupported file type: {ext}")

    # Read and validate size
    content = await file.read()
    if len(content) > MAX_BYTES:
        raise HTTPException(413, f"File too large (max {settings.max_image_size_mb}MB)")

    # Save image
    filename = f"{uuid.uuid4()}{ext}"
    image_path = os.path.join(settings.images_dir, filename)
    os.makedirs(settings.images_dir, exist_ok=True)
    with open(image_path, "wb") as f:
        f.write(content)

    # Analyze with AI
    try:
        attrs = await analyze_clothing_image(image_path)
    except Exception as e:
        os.remove(image_path)
        raise HTTPException(500, f"AI analysis failed: {str(e)}")

    # Save to DB
    item = ClothingItem(
        id=str(uuid.uuid4()),
        user_id=user_id,
        image_filename=filename,
        **attrs,
    )
    db.add(item)
    await db.flush()
    await db.refresh(item)
    return item


@router.get("/user/{user_id}", response_model=list[ClothingResponse])
async def get_user_clothes(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ClothingItem)
        .where(ClothingItem.user_id == user_id)
        .order_by(ClothingItem.created_at.desc())
    )
    return result.scalars().all()


@router.get("/user/{user_id}/stats", response_model=ClothingStats)
async def get_stats(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ClothingItem.category, func.count(ClothingItem.id))
        .where(ClothingItem.user_id == user_id)
        .group_by(ClothingItem.category)
    )
    rows = result.all()
    by_cat = {row[0]: row[1] for row in rows}
    return ClothingStats(total=sum(by_cat.values()), by_category=by_cat)


@router.delete("/{item_id}")
async def delete_clothing(item_id: str, user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ClothingItem).where(ClothingItem.id == item_id, ClothingItem.user_id == user_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(404, "Item not found")

    # Delete image file
    image_path = os.path.join(settings.images_dir, item.image_filename)
    if os.path.exists(image_path):
        os.remove(image_path)

    await db.delete(item)
    return {"deleted": True, "id": item_id}
