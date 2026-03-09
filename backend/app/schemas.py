from __future__ import annotations
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ── Clothing ────────────────────────────────────────────────────────────────

class ClothingBase(BaseModel):
    name: str
    category: str
    color: str
    material: str
    temp_min: float
    temp_max: float
    suitable_occasions: list[str] = []
    ai_description: Optional[str] = None


class ClothingCreate(ClothingBase):
    pass


class ClothingResponse(ClothingBase):
    id: str
    user_id: str
    image_filename: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ClothingStats(BaseModel):
    total: int
    by_category: dict[str, int]


# ── Outfit ──────────────────────────────────────────────────────────────────

class OutfitItemResponse(BaseModel):
    clothing_id: str
    layer_order: int
    clothing: ClothingResponse

    model_config = {"from_attributes": True}


class OutfitResponse(BaseModel):
    id: str
    user_id: str
    liked: Optional[bool]
    occasion: Optional[str]
    weather_condition: Optional[str]
    temperature: Optional[float]
    ai_explanation: Optional[str]
    created_at: datetime
    items: list[OutfitItemResponse] = []

    model_config = {"from_attributes": True}


class GenerateOutfitRequest(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    occasion: Optional[str] = None  # if None, infer from calendar


class LikeRequest(BaseModel):
    liked: bool  # True=like, False=dislike


# ── Calendar ─────────────────────────────────────────────────────────────────

class EventCreate(BaseModel):
    user_id: str
    title: str
    occasion_type: str  # casual/formal/sport/business/party
    event_date: datetime
    notes: Optional[str] = None


class EventResponse(EventCreate):
    id: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Weather ──────────────────────────────────────────────────────────────────

class WeatherResponse(BaseModel):
    temperature: float
    feels_like: float
    condition: str
    description: str
    humidity: int
    wind_speed: float
    icon: str
    city: str
