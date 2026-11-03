import pytest

from apps.reports.ai import PotholeAssessment, apply_ai_assessment
from apps.reports.geo import point_from_lat_lon
from apps.reports.models import Pothole, Report

CENTER_LAT = 21.1430
CENTER_LON = -88.1519


def make_pothole(**kwargs):
    return Pothole.objects.create(
        location=point_from_lat_lon(CENTER_LAT, CENTER_LON),
        **kwargs,
    )


def make_report(pothole, reporter, moderation):
    return Report.objects.create(
        pothole=pothole,
        reporter=reporter,
        location=pothole.location,
        photo="reports/test.webp",
        severity=2,
        moderation=moderation,
    )


@pytest.mark.django_db
def test_map_hides_pothole_when_all_reports_are_rejected(api_client, citizen):
    pothole = make_pothole()
    make_report(pothole, citizen, Report.Moderation.REJECTED)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    assert response.json()["features"] == []


@pytest.mark.django_db
def test_pending_report_is_visible_as_pending_review(api_client, citizen):
    pothole = make_pothole()
    make_report(pothole, citizen, Report.Moderation.PENDING)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    features = response.json()["features"]
    assert len(features) == 1
    assert features[0]["properties"]["status"] == "pending"


@pytest.mark.django_db
def test_confirming_a_report_changes_public_status_to_reported(api_client, citizen):
    pothole = make_pothole()
    make_report(pothole, citizen, Report.Moderation.PENDING)

    initial = api_client.get("/api/potholes/geojson/").json()["features"][0]
    assert initial["properties"]["status"] == "pending"

    Report.objects.filter(pothole=pothole).update(moderation=Report.Moderation.CONFIRMED)
    confirmed = api_client.get("/api/potholes/geojson/").json()["features"][0]
    assert confirmed["properties"]["status"] == "reported"


@pytest.mark.django_db
def test_map_shows_pothole_again_after_a_report_is_approved(api_client, citizen):
    pothole = make_pothole()
    make_report(pothole, citizen, Report.Moderation.REJECTED)
    make_report(pothole, citizen, Report.Moderation.CONFIRMED)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    assert len(response.json()["features"]) == 1


@pytest.mark.django_db
def test_ai_confirmation_updates_the_report(citizen):
    report = make_report(make_pothole(), citizen, Report.Moderation.PENDING)

    apply_ai_assessment(
        report,
        PotholeAssessment(is_pothole=True, confidence=0.95, reason="Bache visible."),
    )
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.CONFIRMED
    assert report.ai_verdict == Report.AIVerdict.POTHOLE
    assert report.ai_confidence == pytest.approx(0.95)
    assert report.ai_checked_at is not None


@pytest.mark.django_db
def test_ai_rejection_hides_the_only_report(citizen):
    report = make_report(make_pothole(), citizen, Report.Moderation.PENDING)

    apply_ai_assessment(
        report,
        PotholeAssessment(is_pothole=False, confidence=0.95, reason="Es un meme."),
    )
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.REJECTED
    assert report.ai_verdict == Report.AIVerdict.NOT_POTHOLE


@pytest.mark.django_db
def test_uncertain_ai_result_stays_in_review(citizen):
    report = make_report(make_pothole(), citizen, Report.Moderation.PENDING)

    apply_ai_assessment(
        report,
        PotholeAssessment(is_pothole=False, confidence=0.60, reason="No se distingue."),
    )
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.PENDING
    assert report.ai_verdict == Report.AIVerdict.UNCLEAR
