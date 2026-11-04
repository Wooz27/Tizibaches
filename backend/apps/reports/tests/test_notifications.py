from io import BytesIO

import pytest
from django.core.files.base import ContentFile
from PIL import Image

from apps.reports.ai import (
    PhotoSource,
    PotholeAssessment,
    apply_ai_assessment,
    mark_ai_error,
)
from apps.reports.geo import point_from_lat_lon
from apps.reports.models import Pothole, Report
from apps.reports.notifications import notify_manual_moderation

CENTER_LAT = 21.1430
CENTER_LON = -88.1519


class FakeResponse:
    def raise_for_status(self):
        return None


def make_report(reporter, *, with_photo=False):
    pothole = Pothole.objects.create(
        location=point_from_lat_lon(CENTER_LAT, CENTER_LON),
        name="El cráter",
        address="Calle 55 #350, Colonia San Pedro, Tizimín, Yucatán",
    )
    report = Report(
        pothole=pothole,
        reporter=reporter,
        location=pothole.location,
        photo="reports/test.webp",
        severity=2,
    )
    if with_photo:
        buffer = BytesIO()
        Image.new("RGB", (40, 30), (120, 120, 120)).save(buffer, "JPEG")
        report.photo.save(
            "telegram-test.jpg",
            ContentFile(buffer.getvalue()),
            save=False,
        )
    report.save()
    return report


def test_telegram_message_contains_report_location_and_admin_link(
    settings, monkeypatch, citizen
):
    settings.TELEGRAM_API_KEY = "test-token"
    settings.USER_TELEGRAM = "123456"
    settings.WEB_URL = "https://example.test"
    captured = {}

    def fake_post(url, data=None, files=None, timeout=None):
        captured["url"] = url
        captured["data"] = data
        captured["files"] = files
        captured["timeout"] = timeout
        return FakeResponse()

    monkeypatch.setattr("apps.reports.notifications.requests.post", fake_post)
    report = make_report(citizen)

    notify_manual_moderation(report, "La IA no está segura.")

    assert captured["url"].endswith("/sendMessage")
    assert captured["data"]["chat_id"] == "123456"
    assert "Expediente: #" in captured["data"]["text"]
    assert "El cráter" in captured["data"]["text"]
    assert "Calle 55 #350" in captured["data"]["text"]
    assert "Reporte: #" in captured["data"]["text"]
    assert f"/admin/reports/report/{report.pk}/change/" in captured["data"]["text"]


def test_telegram_sends_the_photo_with_caption(settings, monkeypatch, citizen):
    settings.TELEGRAM_API_KEY = "test-token"
    settings.USER_TELEGRAM = "123456"
    settings.WEB_URL = "https://example.test"
    captured = {}

    def fake_post(url, data=None, files=None, timeout=None):
        captured["url"] = url
        captured["data"] = data
        captured["files"] = files
        return FakeResponse()

    monkeypatch.setattr("apps.reports.notifications.requests.post", fake_post)
    report = make_report(citizen, with_photo=True)

    notify_manual_moderation(report, "La IA no está segura.")

    assert captured["url"].endswith("/sendPhoto")
    assert captured["data"]["chat_id"] == "123456"
    assert "El cráter" in captured["data"]["caption"]
    assert "Calle 55 #350" in captured["data"]["caption"]
    assert captured["files"]["photo"][0] == "reporte.jpg"
    assert captured["files"]["photo"][2] == "image/jpeg"


def test_telegram_is_skipped_without_configuration(settings, monkeypatch, citizen):
    settings.TELEGRAM_API_KEY = ""
    settings.USER_TELEGRAM = ""
    called = False

    def fake_post(*args, **kwargs):
        nonlocal called
        called = True
        return FakeResponse()

    monkeypatch.setattr("apps.reports.notifications.requests.post", fake_post)

    notify_manual_moderation(make_report(citizen), "La IA no está segura.")

    assert called is False


def test_uncertain_assessment_notifies_manual_moderation(monkeypatch, citizen):
    called = {}
    monkeypatch.setattr(
        "apps.reports.ai.notify_manual_moderation",
        lambda report, reason: called.update(report_id=report.pk, reason=reason),
    )
    report = make_report(citizen)

    apply_ai_assessment(
        report,
        PotholeAssessment(
            is_pothole=True,
            confidence=0.95,
            reason="Podría ser una imagen descargada.",
            source=PhotoSource.UNKNOWN,
            is_authentic=False,
            authenticity_confidence=0.60,
        ),
    )

    assert called["report_id"] == report.pk


def test_confirmed_assessment_does_not_notify(monkeypatch, citizen):
    called = False

    def fake_notify(report, reason):
        nonlocal called
        called = True

    monkeypatch.setattr("apps.reports.ai.notify_manual_moderation", fake_notify)
    report = make_report(citizen)

    apply_ai_assessment(
        report,
        PotholeAssessment(
            is_pothole=True,
            confidence=0.95,
            reason="Bache visible.",
            source=PhotoSource.CAMERA,
            is_authentic=True,
            authenticity_confidence=0.95,
        ),
    )

    assert called is False


def test_ai_error_notifies_manual_moderation(monkeypatch, citizen):
    called = {}
    monkeypatch.setattr(
        "apps.reports.ai.notify_manual_moderation",
        lambda report, reason: called.update(report_id=report.pk, reason=reason),
    )
    report = make_report(citizen)

    mark_ai_error(report, RuntimeError("falló Gemini"))

    assert called["report_id"] == report.pk
