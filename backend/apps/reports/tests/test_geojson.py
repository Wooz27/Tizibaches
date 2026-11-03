import pytest

from apps.reports.geo import point_from_lat_lon
from apps.reports.models import Pothole

CENTER_LAT = 21.1430
CENTER_LON = -88.1519


def make_pothole(lat: float = CENTER_LAT, lon: float = CENTER_LON, **kwargs) -> Pothole:
    return Pothole.objects.create(location=point_from_lat_lon(lat, lon), **kwargs)


@pytest.mark.django_db
def test_geojson_returns_a_feature_collection(api_client):
    make_pothole(status=Pothole.Status.REPORTED, severity=3)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    data = response.json()
    assert data["type"] == "FeatureCollection"
    assert len(data["features"]) == 1

    feature = data["features"][0]
    assert feature["geometry"]["type"] == "Point"
    longitude, latitude = feature["geometry"]["coordinates"]
    assert longitude == pytest.approx(CENTER_LON)
    assert latitude == pytest.approx(CENTER_LAT)
    assert feature["properties"]["status"] == "reported"
    assert feature["properties"]["severity"] == 3


@pytest.mark.django_db
def test_geojson_bbox_filters_potholes(api_client):
    make_pothole()
    make_pothole(lat=21.10, lon=-88.30)

    response = api_client.get(
        "/api/potholes/geojson/",
        {"bbox": "-88.17,21.12,-88.13,21.17"},
    )

    assert response.status_code == 200
    assert len(response.json()["features"]) == 1


@pytest.mark.django_db
def test_geojson_rejects_invalid_bbox(api_client):
    response = api_client.get("/api/potholes/geojson/", {"bbox": "1,2,3"})

    assert response.status_code == 400


@pytest.mark.django_db
def test_geojson_filters_by_status(api_client):
    make_pothole(status=Pothole.Status.REPORTED)
    make_pothole(status=Pothole.Status.FIXED, lat=21.16, lon=-88.13)

    response = api_client.get("/api/potholes/geojson/", {"status": "fixed"})

    assert response.status_code == 200
    features = response.json()["features"]
    assert len(features) == 1
    assert features[0]["properties"]["status"] == "fixed"


@pytest.mark.django_db
def test_pothole_detail_includes_latitude_and_longitude(api_client):
    pothole = make_pothole()

    response = api_client.get(f"/api/potholes/{pothole.pk}/")

    assert response.status_code == 200
    assert response.json()["latitude"] == pytest.approx(CENTER_LAT)
    assert response.json()["longitude"] == pytest.approx(CENTER_LON)


@pytest.mark.django_db
def test_geojson_hides_rejected_potholes(api_client):
    make_pothole(status=Pothole.Status.REJECTED)
    make_pothole(status=Pothole.Status.REPORTED, lat=21.16, lon=-88.13)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    features = response.json()["features"]
    assert len(features) == 1
    assert features[0]["properties"]["status"] == "reported"


@pytest.mark.django_db
def test_public_status_collapses_verified_and_scheduled(api_client):
    make_pothole(status=Pothole.Status.VERIFIED)
    make_pothole(status=Pothole.Status.SCHEDULED, lat=21.16, lon=-88.13)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    statuses = [feature["properties"]["status"] for feature in response.json()["features"]]
    assert statuses == ["reported", "reported"]
