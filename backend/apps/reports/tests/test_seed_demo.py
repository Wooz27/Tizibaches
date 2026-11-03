import pytest
from django.core.management import call_command
from django.db.models import Count

from apps.accounts.models import User
from apps.reports.models import Pothole, Report


@pytest.mark.django_db
def test_seed_demo_creates_complete_data():
    call_command("seed_demo", count=6, reset=True, allow_production=True)

    assert Pothole.objects.count() == 6
    assert Report.objects.count() >= 6
    assert Pothole.objects.filter(address="").count() == 0
    assert Pothole.objects.filter(reports__isnull=True).count() == 0
    assert Pothole.objects.filter(status_events__isnull=True).count() == 0
    assert Pothole.objects.filter(status=Pothole.Status.FIXED, fixed_at__isnull=True).count() == 0
    assert Report.objects.filter(description="").count() == 0
    assert Report.objects.filter(photo="").count() == 0
    assert User.objects.filter(role=User.Role.CITIZEN, first_name="").count() == 0
    assert set(Pothole.objects.values_list("status", flat=True)) == set(Pothole.Status.values)

    for pothole in Pothole.objects.annotate(total_reports=Count("reports")):
        assert pothole.report_count == pothole.total_reports
        assert pothole.first_reported_at <= pothole.last_reported_at
        assert all(report.photo for report in pothole.reports.all())
