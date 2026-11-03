from django.contrib.gis.db import models
from django.utils import timezone

from apps.reports.constants import SEVERITY_CHOICES


class Pothole(models.Model):
    # Un bache físico que se muestra una sola vez en el mapa.

    class Status(models.TextChoices):
        REPORTED = "reported", "Reportado"
        VERIFIED = "verified", "Verificado"
        SCHEDULED = "scheduled", "Programado"
        IN_PROGRESS = "in_progress", "En obra"
        FIXED = "fixed", "Reparado"
        REJECTED = "rejected", "Rechazado"

    location = models.PointField("Ubicación", srid=4326, geography=True)
    status = models.CharField(
        "Estado", max_length=20, choices=Status.choices, default=Status.REPORTED
    )
    severity = models.PositiveSmallIntegerField("Severidad", choices=SEVERITY_CHOICES, default=2)
    report_count = models.PositiveIntegerField("Cantidad de reportes", default=0)
    address = models.CharField("Dirección", max_length=255, blank=True)
    first_reported_at = models.DateTimeField("Primer reporte", auto_now_add=True)
    last_reported_at = models.DateTimeField("Último reporte", default=timezone.now)
    fixed_at = models.DateTimeField("Fecha de reparación", null=True, blank=True)

    class Meta:
        ordering = ("-last_reported_at",)
        indexes = [models.Index(fields=["status"])]
        verbose_name = "Bache"
        verbose_name_plural = "Baches"

    def __str__(self) -> str:
        return f"Bache {self.pk} ({self.status})"


class Report(models.Model):
    # Un reporte ciudadano asociado a un bache.

    class Moderation(models.TextChoices):
        PENDING = "pending", "Pendiente"
        CONFIRMED = "confirmed", "Confirmado"
        REJECTED = "rejected", "Rechazado"

    class AIVerdict(models.TextChoices):
        PENDING = "pending", "Pendiente"
        POTHOLE = "pothole", "Bache"
        NOT_POTHOLE = "not_pothole", "No es un bache"
        UNCLEAR = "unclear", "Poco claro"
        ERROR = "error", "Error"

    pothole = models.ForeignKey(
        Pothole,
        verbose_name="Bache",
        related_name="reports",
        on_delete=models.CASCADE,
    )
    reporter = models.ForeignKey(
        "accounts.User",
        verbose_name="Ciudadano",
        related_name="reports",
        on_delete=models.PROTECT,
    )
    location = models.PointField("Ubicación", srid=4326, geography=True)
    photo = models.ImageField("Foto", upload_to="reports/%Y/%m/")
    description = models.TextField("Descripción", max_length=500, blank=True)
    severity = models.PositiveSmallIntegerField("Severidad", choices=SEVERITY_CHOICES)
    moderation = models.CharField(
        "Moderación",
        max_length=20,
        choices=Moderation.choices,
        default=Moderation.PENDING,
        db_index=True,
    )
    ai_verdict = models.CharField(
        "Veredicto IA",
        max_length=20,
        choices=AIVerdict.choices,
        default=AIVerdict.PENDING,
        db_index=True,
    )
    ai_confidence = models.FloatField("Confianza IA", null=True, blank=True)
    ai_reason = models.TextField("Motivo IA", max_length=500, blank=True)
    ai_model = models.CharField("Modelo IA", max_length=100, blank=True)
    ai_checked_at = models.DateTimeField("Verificado por IA", null=True, blank=True)
    created_at = models.DateTimeField("Fecha de creación", auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        verbose_name = "Reporte"
        verbose_name_plural = "Reportes"

    def __str__(self) -> str:
        return f"Reporte {self.pk} del bache {self.pothole_id}"


class StatusEvent(models.Model):
    # Historial de cambios de estado de un bache.

    pothole = models.ForeignKey(
        Pothole,
        verbose_name="Bache",
        related_name="status_events",
        on_delete=models.CASCADE,
    )
    from_status = models.CharField("Estado anterior", max_length=20)
    to_status = models.CharField("Estado nuevo", max_length=20)
    changed_by = models.ForeignKey(
        "accounts.User",
        verbose_name="Cambiado por",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
    )
    note = models.TextField("Nota", blank=True)
    created_at = models.DateTimeField("Fecha", auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        verbose_name = "Cambio de estado"
        verbose_name_plural = "Cambios de estado"
