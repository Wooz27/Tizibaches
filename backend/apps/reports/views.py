from datetime import UTC, datetime
from urllib.parse import urlencode

from django.conf import settings
from django.db.models import Exists, OuterRef, Subquery
from django.http import HttpResponseNotModified
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.reports.constants import MAX_GEOJSON_FEATURES
from apps.reports.geo import bbox_from_query
from apps.reports.geojson_cache import (
    get_cached,
    last_modified_from_data,
    last_modified_header,
    make_etag,
    set_cached,
)
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
        # El mapa público solo muestra baches con al menos un reporte confirmado.
        reports = Report.objects.filter(pothole=OuterRef("pk"))
        confirmed_reports = reports.filter(moderation=Report.Moderation.CONFIRMED)
        latest_photo = (
            Report.objects.filter(
                pothole=OuterRef("pk"),
                moderation=Report.Moderation.CONFIRMED,
            )
            .order_by("-created_at")
            .values("photo")[:1]
        )
        queryset = (
            super()
            .get_queryset()
            .exclude(status=Pothole.Status.REJECTED)
            .filter(~Exists(reports) | Exists(confirmed_reports))
            .annotate(
                has_confirmed_reports=Exists(confirmed_reports),
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
        # Cachea por variante de consulta y permite respuestas 304 sin rehacer
        # la consulta espacial ni serializar el mapa completo.
        query = urlencode(sorted(request.query_params.items()))
        cached = get_cached(query)
        if cached is None:
            queryset = self.filter_queryset(self.get_queryset())[:MAX_GEOJSON_FEATURES]
            serializer = PotholeGeoSerializer(
                queryset, many=True, context={"request": request}
            )
            data = serializer.data
            last_modified = last_modified_from_data(data)
            etag = make_etag(data)
            set_cached(query, data, last_modified, etag)
        else:
            data = cached["data"]
            etag = cached["etag"]
            last_modified = (
                datetime.fromtimestamp(cached["last_modified"], tz=UTC)
                if cached["last_modified"]
                else None
            )

        response_status = 200
        if request.headers.get("If-None-Match") == etag:
            response = HttpResponseNotModified()
            response_status = 304
        else:
            response = Response(data, status=response_status)

        response["Cache-Control"] = f"public, max-age={settings.GEOJSON_CACHE_SECONDS}"
        response["ETag"] = etag
        last_modified_value = last_modified_header(last_modified)
        if last_modified_value:
            response["Last-Modified"] = last_modified_value
        return response
