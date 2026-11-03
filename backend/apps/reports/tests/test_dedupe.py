import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.reports.models import Pothole, Report

CENTER_LAT = 21.1430
CENTER_LON = -88.1519


def payload(latitude: float, longitude: float, photo):
    return {
        "latitude": latitude,
        "longitude": longitude,
        "severity": 2,
        "description": "Bache en la calle",
        "photo": photo,
    }


@pytest.mark.django_db
def test_first_report_creates_a_pothole(auth_client, report_photo):
    response = auth_client.post(
        "/api/reports/",
        payload(CENTER_LAT, CENTER_LON, report_photo()),
        format="multipart",
    )

    assert response.status_code == 201
    assert response.json()["created"] is True
    assert Pothole.objects.count() == 1
    assert Report.objects.count() == 1
    assert Pothole.objects.get().report_count == 1


@pytest.mark.django_db
def test_reports_within_fifteen_meters_are_merged(auth_client, report_photo):
    auth_client.post(
        "/api/reports/",
        payload(CENTER_LAT, CENTER_LON, report_photo()),
        format="multipart",
    )

    response = auth_client.post(
        "/api/reports/",
        payload(CENTER_LAT + 0.0001, CENTER_LON, report_photo("second.png")),
        format="multipart",
    )

    assert response.status_code == 201
    assert response.json()["created"] is False
    assert response.json()["distance_m"] < 15
    assert Pothole.objects.count() == 1
    assert Report.objects.count() == 2
    assert Pothole.objects.get().report_count == 2


@pytest.mark.django_db
def test_reports_outside_the_radius_create_new_potholes(auth_client, report_photo):
    auth_client.post(
        "/api/reports/",
        payload(CENTER_LAT, CENTER_LON, report_photo()),
        format="multipart",
    )

    response = auth_client.post(
        "/api/reports/",
        payload(CENTER_LAT + 0.0003, CENTER_LON, report_photo("far.png")),
        format="multipart",
    )

    assert response.status_code == 201
    assert response.json()["created"] is True
    assert Pothole.objects.count() == 2


@pytest.mark.django_db
def test_reports_outside_the_city_are_rejected(auth_client, report_photo):
    response = auth_client.post(
        "/api/reports/",
        payload(0, 0, report_photo()),
        format="multipart",
    )

    assert response.status_code == 400
    assert Pothole.objects.count() == 0
    assert Report.objects.count() == 0


@pytest.mark.django_db
def test_reports_require_authentication(api_client, report_photo):
    response = api_client.post(
        "/api/reports/",
        payload(CENTER_LAT, CENTER_LON, report_photo()),
        format="multipart",
    )

    assert response.status_code == 401
    assert Pothole.objects.count() == 0


@pytest.mark.django_db
def test_invalid_photos_are_rejected(auth_client):
    response = auth_client.post(
        "/api/reports/",
        payload(
            CENTER_LAT,
            CENTER_LON,
            SimpleUploadedFile("notes.txt", b"not an image", content_type="text/plain"),
        ),
        format="multipart",
    )

    assert response.status_code == 400
    assert Pothole.objects.count() == 0


@pytest.mark.django_db
def test_mine_lists_only_the_current_user_reports(auth_client, report_photo):
    auth_client.post(
        "/api/reports/",
        payload(CENTER_LAT, CENTER_LON, report_photo()),
        format="multipart",
    )

    other_client = APIClient()
    other = User.objects.create_user(email="other@example.com", password="test-pass-123")
    other_client.force_authenticate(user=other)

    response = other_client.get("/api/reports/mine/")

    assert response.status_code == 200
    assert response.json()["count"] == 0
