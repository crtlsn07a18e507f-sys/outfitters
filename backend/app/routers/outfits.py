import uuid
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from ..database import get_db
from ..models import Outfit, OutfitItem, ClothingItem, CalendarEvent
from ..schemas import OutfitResponse, GenerateOutfitRequest, LikeRequest
from ..services.ai_service import generate_outfit
from ..services.weather_service import get_weather

router = APIRouter(prefix="/outfits", tags=["outfits"])


@router.post("/generate", response_model=OutfitResponse)
async def generate_new_outfit(req: GenerateOutfitRequest, db: AsyncSession = Depends(get_db)):
    # 1. Fetch weather
    try:
        weather = await get_weather(req.latitude, req.longitude)
    except Exception as e:
        raise HTTPException(503, f"Weather service unavailable: {e}")

    # 2. Determine occasion (from calendar or request)
    occasion = req.occasion
    if not occasion:
        today_start = datetime.combine(date.today(), datetime.min.time())
        today_end = datetime.combine(date.today(), datetime.max.time())
        result = await db.execute(
            select(CalendarEvent)
            .where(
                CalendarEvent.user_id == req.user_id,
                CalendarEvent.event_date >= today_start,
                CalendarEvent.event_date <= today_end,
            )
            .order_by(CalendarEvent.event_date)
            .limit(1)
        )
        event = result.scalar_one_or_none()
        occasion = event.occasion_type if event else "casual"

    # 3. Fetch wardrobe
    result = await db.execute(
        select(ClothingItem).where(ClothingItem.user_id == req.user_id)
    )
    clothes = result.scalars().all()
    if not clothes:
        raise HTTPException(422, "No clothing items in wardrobe")

    clothes_data = [
        {
            "id": c.id,
            "name": c.name,
            "category": c.category,
            "color": c.color,
            "material": c.material,
            "temp_min": c.temp_min,
            "temp_max": c.temp_max,
            "suitable_occasions": c.suitable_occasions,
        }
        for c in clothes
    ]

    # 4. Collect disliked combinations
    result = await db.execute(
        select(Outfit)
        .options(selectinload(Outfit.items))
        .where(Outfit.user_id == req.user_id, Outfit.liked == False)  # noqa: E712
    )
    disliked_outfits = result.scalars().all()
    disliked_combos = [
        sorted([i.clothing_id for i in o.items]) for o in disliked_outfits
    ]

    # 5. Call AI
    try:
        ai_result = await generate_outfit(
            clothes=clothes_data,
            temperature=weather.temperature,
            weather_condition=weather.condition,
            occasion=occasion,
            disliked_combos=disliked_combos,
        )
    except Exception as e:
        raise HTTPException(500, f"Outfit generation failed: {e}")

    selected_ids = ai_result["clothing_ids"]
    if not selected_ids:
        raise HTTPException(500, "AI returned no clothing items")

    # 6. Save outfit
    outfit_id = str(uuid.uuid4())
    outfit = Outfit(
        id=outfit_id,
        user_id=req.user_id,
        occasion=occasion,
        weather_condition=weather.condition,
        temperature=weather.temperature,
        ai_explanation=ai_result["explanation"],
    )
    db.add(outfit)

    for order, cid in enumerate(selected_ids):
        oi = OutfitItem(outfit_id=outfit_id, clothing_id=cid, layer_order=order)
        db.add(oi)

    await db.flush()

    # Reload with relationships
    result = await db.execute(
        select(Outfit)
        .options(selectinload(Outfit.items).selectinload(OutfitItem.clothing))
        .where(Outfit.id == outfit_id)
    )
    return result.scalar_one()


@router.post("/{outfit_id}/react")
async def react_to_outfit(outfit_id: str, req: LikeRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Outfit).where(Outfit.id == outfit_id))
    outfit = result.scalar_one_or_none()
    if not outfit:
        raise HTTPException(404, "Outfit not found")
    outfit.liked = req.liked
    await db.flush()
    return {"outfit_id": outfit_id, "liked": req.liked}


@router.get("/liked/{user_id}", response_model=list[OutfitResponse])
async def get_liked_outfits(user_id: str, temp: float = 20.0, limit: int = 10, db: AsyncSession = Depends(get_db)):
    """
    Returns liked outfits sorted by temperature proximity to current temp.
    """
    result = await db.execute(
        select(Outfit)
        .options(selectinload(Outfit.items).selectinload(OutfitItem.clothing))
        .where(Outfit.user_id == user_id, Outfit.liked == True)  # noqa: E712
        .order_by(Outfit.created_at.desc())
    )
    outfits = result.scalars().all()

    # Sort by temperature proximity
    def temp_diff(o: Outfit) -> float:
        if o.temperature is None:
            return 999.0
        return abs(o.temperature - temp)

    outfits.sort(key=temp_diff)
    return outfits[:limit]


@router.get("/user/{user_id}", response_model=list[OutfitResponse])
async def get_user_outfits(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Outfit)
        .options(selectinload(Outfit.items).selectinload(OutfitItem.clothing))
        .where(Outfit.user_id == user_id)
        .order_by(Outfit.created_at.desc())
    )
    return result.scalars().all()
