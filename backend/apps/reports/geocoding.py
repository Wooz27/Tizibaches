from __future__ import annotations

from typing import Any

import requests
from django.conf import settings
from django.contrib.gis.geos import Point
from django.core.cache import cache

CACHE_SECONDS = 60 * 60 * 24 * 30


def _address_from_result(data: dict[str, Any]) -> str:
    address = data.get("address") or {}
    road = address.get("road") or address.get("pedestrian") or address.get("path")
    number = address.get("house_number")
    locality = address.get("suburb") or address.get("neighbourhood")
    city = address.get("city") or address.get("town") or address.get("village")
    state = address.get("state")

    if road:
        street = f"{road} {number}".strip() if number else road
        parts = [street, locality, city, state]
        return ", ".join(part for part in parts if part)
    return data.get("display_name", "")


def reverse_geocode(point: Point) -> str:
    if not settings.GEOCODING_ENABLED:
        return ""

    latitude = round(point.y, 5)
    longitude = round(point.x, 5)
    cache_key = f"geocode:{latitude}:{longitude}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        response = requests.get(
            settings.GEOCODING_URL,
            params={
                "format": "jsonv2",
                "lat": latitude,
                "lon": longitude,
                "zoom": 18,
                "addressdetails": 1,
                "accept-language": "es",
            },
            headers={"User-Agent": settings.GEOCODING_USER_AGENT},
            timeout=settings.GEOCODING_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        value = _address_from_result(response.json()).strip()[:255]
    except (requests.RequestException, ValueError, TypeError):
        value = ""

    cache.set(cache_key, value, timeout=CACHE_SECONDS)
    return value
