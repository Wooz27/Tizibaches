import pytest

from apps.accounts.models import User
from apps.reports.ai import PhotoSource, PotholeAssessment, apply_ai_assessment
from apps.reports.geo import point_from_lat_lon
from apps.reports.geojson_cache import invalidate_geojson_cache
from apps.reports.models import Pothole, Report

CENTER_LAT = 21.1430
CENTER_LON = -88.1519


def make_pothole(**kwargs):
    return Pothole.objects.create(
        location=point_from_lat_lon(CENTER_LAT, CENTER_LON),
        **kwargs,
    )


def make_report(pothole, reporter, moderation, description=""):
    return Report.objects.create(
        pothole=pothole,
        reporter=reporter,
        location=pothole.location,
        photo="reports/test.webp",
        severity=2,
        description=description,
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
def test_pending_report_is_hidden_from_the_public_map(api_client, citizen):
    pothole = make_pothole()
    make_report(pothole, citizen, Report.Moderation.PENDING)

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    assert response.json()["features"] == []


@pytest.mark.django_db
def test_confirming_a_report_publishes_it_to_the_map(api_client, citizen):
    pothole = make_pothole()
    make_report(pothole, citizen, Report.Moderation.PENDING)

    assert api_client.get("/api/potholes/geojson/").json()["features"] == []

    Report.objects.filter(pothole=pothole).update(moderation=Report.Moderation.CONFIRMED)
    invalidate_geojson_cache()
    confirmed = api_client.get("/api/potholes/geojson/").json()["features"][0]
    assert confirmed["properties"]["status"] == "reported"


@pytest.mark.django_db
def test_map_counts_only_distinct_confirmed_reporters(api_client, citizen):
    pothole = make_pothole(name="El cráter")
    other = User.objects.create_user(email="other@example.com", password="test-pass-123")
    make_report(
        pothole,
        citizen,
        Report.Moderation.CONFIRMED,
        description="Nota vieja.",
    )
    make_report(
        pothole,
        citizen,
        Report.Moderation.CONFIRMED,
        description="Nota confirmada más reciente.",
    )
    make_report(
        pothole,
        citizen,
        Report.Moderation.REJECTED,
        description="Nota rechazada que no debe salir.",
    )
    make_report(
        pothole,
        other,
        Report.Moderation.CONFIRMED,
        description="Nota de otra persona.",
    )

    response = api_client.get("/api/potholes/geojson/")

    assert response.status_code == 200
    feature = response.json()["features"][0]
    assert feature["properties"]["name"] == "El cráter"
    assert feature["properties"]["report_count"] == 2
    assert feature["properties"]["note"] == "Nota de otra persona."


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
        PotholeAssessment(
            is_pothole=True,
            confidence=0.95,
            reason="Bache visible.",
            source=PhotoSource.CAMERA,
            is_authentic=True,
            authenticity_confidence=0.95,
        ),
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
        PotholeAssessment(
            is_pothole=False,
            confidence=0.95,
            reason="Es una persona.",
            source=PhotoSource.CAMERA,
            is_authentic=True,
            authenticity_confidence=0.95,
        ),
    )
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.REJECTED
    assert report.ai_verdict == Report.AIVerdict.NOT_POTHOLE


@pytest.mark.django_db
def test_uncertain_ai_result_stays_in_review(citizen):
    report = make_report(make_pothole(), citizen, Report.Moderation.PENDING)

    apply_ai_assessment(
        report,
        PotholeAssessment(
            is_pothole=False,
            confidence=0.60,
            reason="No se distingue.",
            source=PhotoSource.UNKNOWN,
            is_authentic=True,
            authenticity_confidence=0.60,
        ),
    )
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.PENDING
    assert report.ai_verdict == Report.AIVerdict.UNCLEAR


@pytest.mark.django_db
def test_stock_photo_is_rejected_even_if_it_shows_a_pothole(citizen):
    report = make_report(make_pothole(), citizen, Report.Moderation.PENDING)

    apply_ai_assessment(
        report,
        PotholeAssessment(
            is_pothole=True,
            confidence=0.98,
            reason="Bache con composición de catálogo.",
            source=PhotoSource.STOCK,
            is_authentic=False,
            authenticity_confidence=0.96,
        ),
    )
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.REJECTED
    assert report.ai_verdict == Report.AIVerdict.NOT_AUTHENTIC


@pytest.mark.django_db
def test_uncertain_authenticity_does_not_publish_the_report(citizen):
    report = make_report(make_pothole(), citizen, Report.Moderation.PENDING)

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
    report.refresh_from_db()

    assert report.moderation == Report.Moderation.PENDING
    assert report.ai_verdict == Report.AIVerdict.UNCLEAR
