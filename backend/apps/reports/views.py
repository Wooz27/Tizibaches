from django.db.models import Exists, OuterRef, Subquery
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.reports.constants import MAX_GEOJSON_FEATURES
from apps.reports.geo import bbox_from_query
from apps.reports.models import Pothole, Report
from apps.reports.serializers import (
    PotholeGeoSerializer,
    PotholeSerializer,
    ReportCreateSerializer,
    ReportReadSerializer,
)
from apps.reports.services import create_report_with_dedupe


class ReportViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    # Crea reportes y lista los envíos del usuario actual.

    permission_classes = [IsAuthenticated]
    serializer_class = ReportCreateSerializer

    @action(detail=False, methods=["get"])
    def mine(self, request):
        reports = Report.objects.filter(reporter=request.user).select_related("pothole")
        page = self.paginate_queryset(reports)
        serializer = ReportReadSerializer(page, many=True, context={"request": request})
        return self.get_paginated_response(serializer.data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = create_report_with_dedupe(
            reporter=request.user,
            point=serializer.validated_data["point"],
            photo=serializer.validated_data["processed_photo"],
            severity=serializer.validated_data["severity"],
            description=serializer.validated_data.get("description", ""),
        )

        data = ReportReadSerializer(result.report, context={"request": request}).data
        data["created"] = result.created
        data["distance_m"] = result.distance_m
        return Response(data, status=status.HTTP_201_CREATED)


class PotholeViewSet(viewsets.ReadOnlyModelViewSet):
    # Lee baches como JSON normal o como una colección GeoJSON.

    queryset = Pothole.objects.all()
    serializer_class = PotholeSerializer
    filterset_fields = ["status", "severity"]

    def get_queryset(self):
        # Un bache sin reportes aprobados no debe aparecer en el mapa público.
        reports = Report.objects.filter(pothole=OuterRef("pk"))
        visible_reports = reports.exclude(moderation=Report.Moderation.REJECTED)
        confirmed_reports = reports.filter(moderation=Report.Moderation.CONFIRMED)
        pending_reports = reports.filter(moderation=Report.Moderation.PENDING)
        latest_photo = (
            Report.objects.filter(pothole=OuterRef("pk"))
            .exclude(moderation=Report.Moderation.REJECTED)
            .order_by("-created_at")
            .values("photo")[:1]
        )
        queryset = (
            super()
            .get_queryset()
            .exclude(status=Pothole.Status.REJECTED)
            .filter(~Exists(reports) | Exists(visible_reports))
            .annotate(
                has_confirmed_reports=Exists(confirmed_reports),
                has_pending_reports=Exists(pending_reports),
                latest_photo=Subquery(latest_photo),
            )
        )

        bbox = self.request.query_params.get("bbox")
        if not bbox:
            return queryset

        try:
            polygon = bbox_from_query(bbox)
        except ValueError as exc:
            raise ValidationError({"bbox": str(exc)}) from exc
        return queryset.filter(location__bboverlaps=polygon)

    @action(detail=False, methods=["get"], url_path="geojson")
    def geojson(self, request):
        # Limita la respuesta para no enviar un GeoJSON enorme al mapa.
        queryset = self.filter_queryset(self.get_queryset())[:MAX_GEOJSON_FEATURES]
        serializer = PotholeGeoSerializer(queryset, many=True, context={"request": request})
        response = Response(serializer.data)
        response["Cache-Control"] = "public, max-age=60"
        return response
