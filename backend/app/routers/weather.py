from fastapi import APIRouter, HTTPException
from ..services.weather_service import get_weather
from ..schemas import WeatherResponse

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("/", response_model=WeatherResponse)
async def weather(lat: float, lon: float):
    try:
        return await get_weather(lat, lon)
    except Exception as e:
        raise HTTPException(503, f"Weather unavailable: {e}")
