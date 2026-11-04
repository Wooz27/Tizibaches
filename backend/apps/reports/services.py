from dataclasses import dataclass
from datetime import timedelta
from hashlib import sha256

from django.conf import settings
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.db import IntegrityError, transaction
from django.db.models import Exists, F, OuterRef
from django.utils import timezone

from apps.reports.constants import OPEN_STATUSES
from apps.reports.geocoding import reverse_geocode
from apps.reports.geojson_cache import invalidate_geojson_cache
from apps.reports.models import Pothole, Report


class DuplicateReport(RuntimeError):
    pass


class DuplicatePhoto(RuntimeError):
    pass


@dataclass(frozen=True)
class ReportCreationResult:
    report: Report
    created: bool
    distance_m: float | None


def _photo_sha256(photo) -> str:
    photo.seek(0)
    digest = sha256(photo.read()).hexdigest()
    photo.seek(0)
    return digest


def _recent_duplicate_report(reporter, pothole: Pothole) -> bool:
    return Report.objects.filter(
        reporter=reporter,
        pothole=pothole,
        created_at__gte=timezone.now()
        - timedelta(hours=settings.REPORT_DUPLICATE_WINDOW_HOURS),
    ).exists()


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
    name: str = "",
    description: str = "",
) -> ReportCreationResult:
    # Asocia el reporte a un bache cercano o crea uno nuevo.
    nearby = find_nearby_open_pothole(point)
    if nearby is not None and _recent_duplicate_report(reporter, nearby):
        raise DuplicateReport(
            "Ya reportaste este bache en las últimas "
            f"{settings.REPORT_DUPLICATE_WINDOW_HOURS} horas."
        )

    photo_hash = _photo_sha256(photo)
    if Report.objects.filter(photo_sha256=photo_hash).exists():
        raise DuplicatePhoto("Esta foto ya fue usada en otro reporte.")

    created = nearby is None
    pothole = nearby or Pothole.objects.create(
        location=point,
        severity=severity,
        name=name.strip(),
    )

    if not pothole.address:
        address = reverse_geocode(point) or f"{settings.CITY_NAME}, Yucatán"
        Pothole.objects.filter(pk=pothole.pk).update(address=address)
        pothole.address = address

    report = Report(
        reporter=reporter,
        pothole=pothole,
        location=point,
        severity=severity,
        description=description,
        photo_sha256=photo_hash,
    )
    report.photo.save(photo.name, photo, save=False)
    try:
        with transaction.atomic():
            report.save()
    except IntegrityError as exc:
        raise DuplicatePhoto("Esta foto ya fue usada en otro reporte.") from exc

    Pothole.objects.filter(pk=pothole.pk).update(
        report_count=F("report_count") + 1,
        last_reported_at=timezone.now(),
    )
    transaction.on_commit(invalidate_geojson_cache)

    return ReportCreationResult(
        report=report,
        created=created,
        distance_m=None if created else nearby.distance.m,
    )
