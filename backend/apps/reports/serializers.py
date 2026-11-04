from django.conf import settings
from rest_framework import serializers
from rest_framework_gis.serializers import GeoFeatureModelSerializer

from apps.reports.constants import (
    SEVERITY_CHOICES,
    public_pothole_status,
    public_report_status,
)
from apps.reports.geo import is_inside_city, point_from_lat_lon
from apps.reports.models import Pothole, Report
from apps.reports.photos import InvalidPhoto, process_uploaded_photo


def media_url(request, path: str | None) -> str | None:
    if not path:
        return None
    url = f"{settings.MEDIA_URL}{path}"
    return request.build_absolute_uri(url) if request else url


def confirmed_reporter_count(pothole: Pothole) -> int:
    if hasattr(pothole, "confirmed_reporter_count"):
        return pothole.confirmed_reporter_count
    return (
        pothole.reports.filter(moderation=Report.Moderation.CONFIRMED)
        .values("reporter_id")
        .distinct()
        .count()
    )


def latest_note_text(pothole: Pothole) -> str:
    if hasattr(pothole, "latest_note"):
        return pothole.latest_note or ""
    return (
        pothole.reports.filter(moderation=Report.Moderation.CONFIRMED)
        .exclude(description="")
        .order_by("-created_at")
        .values_list("description", flat=True)
        .first()
        or ""
    )


def latest_photo_path(pothole: Pothole) -> str | None:
    if hasattr(pothole, "latest_photo"):
        return pothole.latest_photo
    return (
        pothole.reports.exclude(moderation=Report.Moderation.REJECTED)
        .order_by("-created_at")
        .values_list("photo", flat=True)
        .first()
    )


class PotholeSerializer(serializers.ModelSerializer):
    status = serializers.SerializerMethodField()
    report_count = serializers.SerializerMethodField()
    note = serializers.SerializerMethodField()
    latitude = serializers.SerializerMethodField()
    longitude = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Pothole
        fields = (
            "id",
            "name",
            "status",
            "severity",
            "report_count",
            "note",
            "latitude",
            "longitude",
            "address",
            "first_reported_at",
            "last_reported_at",
            "fixed_at",
            "photo_url",
        )

    def get_status(self, obj: Pothole) -> str:
        return public_pothole_status(
            obj.status,
            has_confirmed=getattr(obj, "has_confirmed_reports", False),
            has_pending=getattr(obj, "has_pending_reports", False),
        )

    def get_report_count(self, obj: Pothole) -> int:
        return confirmed_reporter_count(obj)

    def get_note(self, obj: Pothole) -> str:
        return latest_note_text(obj)

    def get_latitude(self, obj: Pothole) -> float:
        return obj.location.y

    def get_longitude(self, obj: Pothole) -> float:
        return obj.location.x

    def get_photo_url(self, obj: Pothole) -> str | None:
        return media_url(self.context.get("request"), latest_photo_path(obj))


class PotholeGeoSerializer(GeoFeatureModelSerializer):
    status = serializers.SerializerMethodField()
    report_count = serializers.SerializerMethodField()
    note = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Pothole
        geo_field = "location"
        fields = (
            "id",
            "name",
            "status",
            "severity",
            "report_count",
            "note",
            "address",
            "first_reported_at",
            "last_reported_at",
            "fixed_at",
            "photo_url",
        )

    def get_status(self, obj: Pothole) -> str:
        return public_pothole_status(
            obj.status,
            has_confirmed=getattr(obj, "has_confirmed_reports", False),
            has_pending=getattr(obj, "has_pending_reports", False),
        )

    def get_report_count(self, obj: Pothole) -> int:
        return confirmed_reporter_count(obj)

    def get_note(self, obj: Pothole) -> str:
        return latest_note_text(obj)

    def get_photo_url(self, obj: Pothole) -> str | None:
        return media_url(self.context.get("request"), getattr(obj, "latest_photo", None))


class ReportCreateSerializer(serializers.Serializer):
    latitude = serializers.FloatField(min_value=-90, max_value=90)
    longitude = serializers.FloatField(min_value=-180, max_value=180)
    severity = serializers.ChoiceField(choices=[value for value, _ in SEVERITY_CHOICES])
    name = serializers.CharField(required=False, allow_blank=True, max_length=80)
    description = serializers.CharField(required=False, allow_blank=True, max_length=500)
    photo = serializers.ImageField()

    def validate(self, attrs):
        point = point_from_lat_lon(attrs["latitude"], attrs["longitude"])
        if not is_inside_city(point):
            raise serializers.ValidationError(
                {"location": "La ubicación está fuera del área de la ciudad."}
            )

        try:
            attrs["processed_photo"] = process_uploaded_photo(attrs["photo"])
        except InvalidPhoto as exc:
            raise serializers.ValidationError({"photo": str(exc)}) from exc

        attrs["point"] = point
        return attrs


class ReportReadSerializer(serializers.ModelSerializer):
    pothole_id = serializers.IntegerField(read_only=True)
    status = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Report
        fields = (
            "id",
            "pothole_id",
            "status",
            "severity",
            "description",
            "photo_url",
            "created_at",
        )

    def get_status(self, obj: Report) -> str:
        return public_report_status(obj.moderation, obj.pothole.status)

    def get_photo_url(self, obj: Report) -> str | None:
        return media_url(self.context.get("request"), obj.photo.name if obj.photo else None)
