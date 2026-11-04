from django.conf import settings
from django.contrib import admin
from django.contrib.admin.widgets import AdminFileWidget
from django.contrib.gis.admin import GISModelAdmin
from django.db.models import ImageField, OuterRef, Subquery
from django.utils import timezone
from django.utils.html import format_html

from apps.reports.geojson_cache import invalidate_geojson_cache
from apps.reports.models import Pothole, Report, StatusEvent


class ImagePreviewWidget(AdminFileWidget):
    # Muestra la foto actual arriba del selector de archivo.
    def render(self, name, value, attrs=None, renderer=None):
        preview = ""
        if value and getattr(value, "url", None):
            preview = format_html(
                '<a href="{0}" target="_blank" rel="noopener">'
                '<img src="{0}" class="admin-file-preview" alt="Vista previa de la foto"></a>',
                value.url,
            )
        return format_html("{}{}", preview, super().render(name, value, attrs, renderer))


@admin.register(Pothole)
class PotholeAdmin(GISModelAdmin):
    list_display = (
        "id",
        "photo_thumb",
        "name",
        "address",
        "status",
        "severity",
        "report_count",
        "last_reported_at",
    )
    list_filter = ("status", "severity")
    search_fields = ("name", "address")
    readonly_fields = ("first_reported_at", "last_reported_at", "latest_photo_preview")
    fieldsets = (
        ("Ubicación", {"fields": ("name", "location", "address")}),
        ("Estado", {"fields": ("status", "severity", "report_count", "fixed_at")}),
        ("Fechas", {"fields": ("first_reported_at", "last_reported_at")}),
        ("Foto más reciente", {"fields": ("latest_photo_preview",)}),
    )
    gis_widget_kwargs = {
        "attrs": {
            "default_lon": (settings.CITY_BBOX[0] + settings.CITY_BBOX[2]) / 2,
            "default_lat": (settings.CITY_BBOX[1] + settings.CITY_BBOX[3]) / 2,
            "default_zoom": 13,
        }
    }

    def get_queryset(self, request):
        # Anota la última foto para mostrar miniaturas sin consultas por fila.
        latest_photo = (
            Report.objects.filter(pothole=OuterRef("pk"))
            .order_by("-created_at")
            .values("photo")[:1]
        )
        return super().get_queryset(request).annotate(latest_photo=Subquery(latest_photo))

    @admin.display(description="Foto")
    def photo_thumb(self, obj):
        path = getattr(obj, "latest_photo", None)
        if not path and obj.pk:
            report = obj.reports.order_by("-created_at").first()
            path = report.photo.name if report and report.photo else None
        if not path:
            return "Sin foto"
        url = f"{settings.MEDIA_URL}{path}"
        return format_html(
            '<a href="{0}" target="_blank" rel="noopener">'
            '<img src="{0}" class="admin-thumb" alt="Foto del bache"></a>',
            url,
        )

    @admin.display(description="Foto más reciente")
    def latest_photo_preview(self, obj):
        if not obj or not obj.pk:
            return "La vista previa aparece después de guardar."
        path = getattr(obj, "latest_photo", None)
        if not path:
            report = obj.reports.order_by("-created_at").first()
            path = report.photo.name if report and report.photo else None
        if not path:
            return "Sin foto."
        url = f"{settings.MEDIA_URL}{path}"
        return format_html(
            '<a href="{0}" target="_blank" rel="noopener">'
            '<img src="{0}" class="admin-photo-preview" alt="Foto más reciente del bache"></a>',
            url,
        )

    def save_model(self, request, obj, form, change):
        previous_status = None
        if change:
            previous_status = (
                Pothole.objects.filter(pk=obj.pk).values_list("status", flat=True).first()
            )

        if obj.status == Pothole.Status.FIXED and obj.fixed_at is None:
            obj.fixed_at = timezone.now()

        super().save_model(request, obj, form, change)

        if previous_status and previous_status != obj.status:
            StatusEvent.objects.create(
                pothole=obj,
                from_status=previous_status,
                to_status=obj.status,
                changed_by=request.user,
            )
        invalidate_geojson_cache()


@admin.register(Report)
class ReportAdmin(GISModelAdmin):
    list_display = (
        "id",
        "photo_thumb",
        "pothole",
        "reporter",
        "severity",
        "moderation",
        "ai_confidence",
        "created_at",
    )
    list_filter = ("moderation", "ai_verdict", "severity", "created_at")
    search_fields = ("reporter__email", "description", "ai_reason")
    readonly_fields = (
        "created_at",
        "ai_verdict",
        "ai_confidence",
        "ai_reason",
        "ai_model",
        "ai_checked_at",
    )
    formfield_overrides = {ImageField: {"widget": ImagePreviewWidget}}
    actions = ("approve_reports", "reject_reports", "reverify_reports")

    @admin.action(description="Aprobar y mostrar reportes seleccionados")
    def approve_reports(self, request, queryset):
        updated = queryset.update(moderation=Report.Moderation.CONFIRMED)
        invalidate_geojson_cache()
        self.message_user(request, f"{updated} reportes aprobados.")

    @admin.action(description="Rechazar y ocultar reportes seleccionados")
    def reject_reports(self, request, queryset):
        updated = queryset.update(moderation=Report.Moderation.REJECTED)
        invalidate_geojson_cache()
        self.message_user(request, f"{updated} reportes rechazados.")

    @admin.action(description="Volver a verificar con IA")
    def reverify_reports(self, request, queryset):
        updated = queryset.update(
            moderation=Report.Moderation.PENDING,
            ai_verdict=Report.AIVerdict.PENDING,
            ai_confidence=None,
            ai_reason="",
            ai_model="",
            ai_checked_at=None,
        )
        self.message_user(request, f"{updated} reportes enviados a la cola de IA.")

    @admin.display(description="Foto")
    def photo_thumb(self, obj):
        if not obj.photo:
            return "Sin foto"
        return format_html(
            '<a href="{0}" target="_blank" rel="noopener">'
            '<img src="{0}" class="admin-thumb" alt="Foto del reporte"></a>',
            obj.photo.url,
        )


@admin.register(StatusEvent)
class StatusEventAdmin(admin.ModelAdmin):
    list_display = ("pothole", "from_status", "to_status", "changed_by", "created_at")
    list_filter = ("to_status",)
    readonly_fields = ("pothole", "from_status", "to_status", "changed_by", "created_at")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
