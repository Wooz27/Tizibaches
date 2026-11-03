import hashlib
import json
from datetime import datetime

from django.conf import settings
from django.core.cache import cache
from django.utils.http import http_date

VERSION_KEY = "reports:geojson:version"
CACHE_PREFIX = "reports:geojson"


def _version() -> int:
    version = cache.get(VERSION_KEY)
    if version is None:
        cache.add(VERSION_KEY, 1, timeout=None)
        version = cache.get(VERSION_KEY, 1)
    return int(version)


def invalidate_geojson_cache() -> None:
    try:
        cache.incr(VERSION_KEY)
    except ValueError:
        cache.set(VERSION_KEY, 2, timeout=None)


def _key(query: str) -> str:
    digest = hashlib.sha256(query.encode("utf-8")).hexdigest()[:20]
    return f"{CACHE_PREFIX}:{_version()}:{digest}"


def get_cached(query: str):
    return cache.get(_key(query))


def set_cached(query: str, data: dict, last_modified: datetime | None, etag: str) -> None:
    payload = {
        "data": data,
        "etag": etag,
        "last_modified": last_modified.timestamp() if last_modified else None,
    }
    cache.set(_key(query), payload, timeout=settings.GEOJSON_CACHE_SECONDS)


def make_etag(data: dict) -> str:
    encoded = json.dumps(data, sort_keys=True, separators=(",", ":"), default=str)
    return f'"{hashlib.sha256(encoded.encode("utf-8")).hexdigest()}"'


def last_modified_from_data(data: dict) -> datetime | None:
    dates = []
    for feature in data.get("features", []):
        value = feature.get("properties", {}).get("last_reported_at")
        if not value:
            continue
        try:
            dates.append(datetime.fromisoformat(value.replace("Z", "+00:00")))
        except (TypeError, ValueError):
            continue
    return max(dates, default=None)


def last_modified_header(value: datetime | None) -> str | None:
    return http_date(value.timestamp()) if value else None
