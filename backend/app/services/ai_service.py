import base64
import json
import re
from pathlib import Path
import anthropic
from ..config import settings

_client = anthropic.Anthropic(api_key=settings.anthropic_api_key)


def _image_to_base64(image_path: str) -> tuple[str, str]:
    """Returns (base64_data, media_type)."""
    path = Path(image_path)
    suffix = path.suffix.lower()
    media_map = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}
    media_type = media_map.get(suffix, "image/jpeg")
    with open(path, "rb") as f:
        return base64.standard_b64encode(f.read()).decode("utf-8"), media_type


def _parse_json_from_response(text: str) -> dict:
    """Extract JSON block from Claude's response."""
    match = re.search(r"```json\s*(.*?)\s*```", text, re.DOTALL)
    if match:
        return json.loads(match.group(1))
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        return json.loads(match.group(0))
    raise ValueError(f"No JSON found in response: {text[:200]}")


async def analyze_clothing_image(image_path: str) -> dict:
    """
    Analyze a clothing photo and extract structured attributes.
    Returns dict with: name, category, color, material, temp_min, temp_max,
    suitable_occasions, ai_description.
    """
    b64, media_type = _image_to_base64(image_path)

    response = _client.messages.create(
        model="claude-opus-4-5",
        max_tokens=800,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {"type": "base64", "media_type": media_type, "data": b64},
                    },
                    {
                        "type": "text",
                        "text": (
                            "Analyze this clothing item and return ONLY a JSON block with these exact fields:\n"
                            "- name: short descriptive name (e.g. 'White Oxford Shirt')\n"
                            "- category: one of [top, bottom, shoes, jacket, accessory]\n"
                            "- color: main color(s) description\n"
                            "- material: fabric/material description\n"
                            "- temp_min: minimum comfortable temperature in °C (integer)\n"
                            "- temp_max: maximum comfortable temperature in °C (integer)\n"
                            "- suitable_occasions: array, subset of [casual, formal, sport, business, party, beach]\n"
                            "- ai_description: one sentence style description\n\n"
                            "Return ONLY ```json { ... } ``` with no other text."
                        ),
                    },
                ],
            }
        ],
    )

    raw = response.content[0].text
    data = _parse_json_from_response(raw)

    # Validate and coerce types
    return {
        "name": str(data.get("name", "Clothing item")),
        "category": str(data.get("category", "top")).lower(),
        "color": str(data.get("color", "unknown")),
        "material": str(data.get("material", "unknown")),
        "temp_min": float(data.get("temp_min", 5)),
        "temp_max": float(data.get("temp_max", 30)),
        "suitable_occasions": list(data.get("suitable_occasions", ["casual"])),
        "ai_description": str(data.get("ai_description", "")),
    }


async def generate_outfit(
    clothes: list[dict],
    temperature: float,
    weather_condition: str,
    occasion: str,
    disliked_combos: list[list[str]],
) -> dict:
    """
    Given the wardrobe and context, ask Claude to select the best outfit.
    Returns dict with: clothing_ids (list), explanation.
    """
    disliked_str = ""
    if disliked_combos:
        combos = [", ".join(c) for c in disliked_combos[:20]]
        disliked_str = f"\n\nNEVER use these exact combinations of IDs (user disliked them):\n" + "\n".join(combos)

    wardrobe_json = json.dumps(clothes, indent=2)

    prompt = (
        f"You are a professional fashion stylist AI.\n\n"
        f"Current conditions:\n"
        f"- Temperature: {temperature}°C\n"
        f"- Weather: {weather_condition}\n"
        f"- Occasion: {occasion}\n\n"
        f"User's wardrobe (JSON):\n{wardrobe_json}\n"
        f"{disliked_str}\n\n"
        f"Select a complete, stylish outfit appropriate for the conditions. "
        f"Include: 1 bottom, 1 top, optionally 1 jacket (if cold/rainy), 1 shoes, optionally 1 accessory. "
        f"Return ONLY a JSON block with:\n"
        f"- clothing_ids: array of selected item IDs in display order (shoes first, then bottom, top, jacket, accessory)\n"
        f"- explanation: 2-3 sentence explanation of the outfit choice\n\n"
        f"Return ONLY ```json {{ ... }} ``` with no other text."
    )

    response = _client.messages.create(
        model="claude-opus-4-5",
        max_tokens=600,
        messages=[{"role": "user", "content": prompt}],
    )

    data = _parse_json_from_response(response.content[0].text)
    return {
        "clothing_ids": list(data.get("clothing_ids", [])),
        "explanation": str(data.get("explanation", "")),
    }
