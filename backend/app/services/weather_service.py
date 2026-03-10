import httpx
from ..config import settings
from ..schemas import WeatherResponse


async def get_weather(lat: float, lon: float) -> WeatherResponse:
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": settings.openweather_api_key,
        "units": "metric",
        "lang": "it",
    }

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(url, params=params)
        r.raise_for_status()
        data = r.json()

    return WeatherResponse(
        temperature=round(data["main"]["temp"], 1),
        feels_like=round(data["main"]["feels_like"], 1),
        condition=data["weather"][0]["main"],
        description=data["weather"][0]["description"],
        humidity=data["main"]["humidity"],
        wind_speed=round(data["wind"]["speed"] * 3.6, 1),  # m/s → km/h
        icon=data["weather"][0]["icon"],
        city=data.get("name", ""),
    )
