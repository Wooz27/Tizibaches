import pytest

from apps.reports.geo import point_from_lat_lon
from apps.reports.geojson_cache import invalidate_geojson_cache
from apps.reports.models import Pothole


@pytest.mark.django_db
def test_geojson_returns_cache_headers_and_304(api_client):
    Pothole.objects.create(
        location=point_from_lat_lon(21.1430, -88.1519),
        severity=2,
    )

    first = api_client.get("/api/potholes/geojson/")
    assert first.status_code == 200
    assert first["ETag"].startswith('"')
    assert first["Last-Modified"]
    assert "max-age=30" in first["Cache-Control"]

    second = api_client.get(
        "/api/potholes/geojson/",
        HTTP_IF_NONE_MATCH=first["ETag"],
    )
    assert second.status_code == 304
    assert len(second.content) == 0


@pytest.mark.django_db
def test_geojson_cache_is_invalidated_after_a_change(api_client):
    pothole = Pothole.objects.create(
        location=point_from_lat_lon(21.1430, -88.1519),
        severity=2,
    )
    first = api_client.get("/api/potholes/geojson/")
    etag = first["ETag"]

    pothole.status = Pothole.Status.FIXED
    pothole.save(update_fields=["status"])
    invalidate_geojson_cache()

    changed = api_client.get(
        "/api/potholes/geojson/",
        HTTP_IF_NONE_MATCH=etag,
    )
    assert changed.status_code == 200
    assert changed.json()["features"][0]["properties"]["status"] == "fixed"
