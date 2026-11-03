from dataclasses import dataclass

from django.conf import settings
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.db import transaction
from django.db.models import Exists, F, OuterRef
from django.utils import timezone

from apps.reports.constants import OPEN_STATUSES
from apps.reports.models import Pothole, Report


@dataclass(frozen=True)
class ReportCreationResult:
    report: Report
    created: bool
    distance_m: float | None


def find_nearby_open_pothole(point: Point) -> Pothole | None:
    # Devuelve el bache abierto más cercano dentro del radio de deduplicación.
    reports = Report.objects.filter(pothole=OuterRef("pk"))
    visible_reports = reports.exclude(moderation=Report.Moderation.REJECTED)
    return (
        Pothole.objects.filter(status__in=OPEN_STATUSES)
        .filter(~Exists(reports) | Exists(visible_reports))
        .annotate(distance=Distance("location", point))
        .filter(distance__lte=D(m=settings.DEDUPE_RADIUS_M))
        .order_by("distance")
        .first()
    )


@transaction.atomic
def create_report_with_dedupe(
    *,
    reporter,
    point: Point,
    photo,
    severity: int,
    description: str = "",
) -> ReportCreationResult:
    # Asocia el reporte a un bache cercano o crea uno nuevo.
    nearby = find_nearby_open_pothole(point)
    created = nearby is None
    pothole = nearby or Pothole.objects.create(location=point, severity=severity)

    report = Report(
        reporter=reporter,
        pothole=pothole,
        location=point,
        severity=severity,
        description=description,
    )
    report.photo.save(photo.name, photo, save=False)
    report.save()

    Pothole.objects.filter(pk=pothole.pk).update(
        report_count=F("report_count") + 1,
        last_reported_at=timezone.now(),
    )

    return ReportCreationResult(
        report=report,
        created=created,
        distance_m=None if created else nearby.distance.m,
    )
