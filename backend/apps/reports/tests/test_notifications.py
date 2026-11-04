from urllib.parse import parse_qs

import pytest

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
    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def read(self):
        return b"{}"


def make_report(reporter):
    pothole = Pothole.objects.create(
        location=point_from_lat_lon(CENTER_LAT, CENTER_LON),
        name="El cráter",
    )
    return Report.objects.create(
        pothole=pothole,
        reporter=reporter,
        location=pothole.location,
        photo="reports/test.webp",
        severity=2,
    )


def test_telegram_message_contains_report_and_admin_link(settings, monkeypatch, citizen):
    settings.TELEGRAM_API_KEY = "test-token"
    settings.USER_TELEGRAM = "123456"
    settings.WEB_URL = "https://example.test"
    captured = {}

    def fake_urlopen(request, timeout):
        captured["url"] = request.full_url
        captured["payload"] = parse_qs(request.data.decode())
        captured["timeout"] = timeout
        return FakeResponse()

    monkeypatch.setattr("apps.reports.notifications.urlopen", fake_urlopen)
    report = make_report(citizen)

    notify_manual_moderation(report, "La IA no está segura.")

    assert captured["url"].endswith("/sendMessage")
    assert captured["payload"]["chat_id"] == ["123456"]
    assert "Expediente: #" in captured["payload"]["text"][0]
    assert "Reporte: #" in captured["payload"]["text"][0]
    assert f"/admin/reports/report/{report.pk}/change/" in captured["payload"]["text"][0]


def test_telegram_is_skipped_without_configuration(settings, monkeypatch, citizen):
    settings.TELEGRAM_API_KEY = ""
    settings.USER_TELEGRAM = ""
    called = False

    def fake_urlopen(request, timeout):
        nonlocal called
        called = True
        return FakeResponse()

    monkeypatch.setattr("apps.reports.notifications.urlopen", fake_urlopen)

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
