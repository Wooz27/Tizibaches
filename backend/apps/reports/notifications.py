import logging
from io import BytesIO

import requests
from django.conf import settings
from PIL import Image, ImageOps

from apps.reports.models import Report

logger = logging.getLogger(__name__)


def _photo_jpeg(report: Report) -> bytes | None:
    if not report.photo:
        return None
    try:
        with report.photo.open("rb") as source:
            with Image.open(source) as image:
                image = ImageOps.exif_transpose(image).convert("RGB")
                image.thumbnail((1280, 1280))
                output = BytesIO()
                image.save(output, format="JPEG", quality=85)
                return output.getvalue()
    except Exception as exc:
        logger.warning("No se pudo preparar la foto para Telegram: %s", type(exc).__name__)
        return None


def _message(report: Report, reason: str) -> str:
    name = report.pothole.name.strip() or f"Bache #{report.pothole_id}"
    address = report.pothole.address.strip() or "Ubicación sin dirección"
    return (
        "⚠️ Moderación manual requerida\n"
        f"Expediente: #{report.pothole_id} — {name}\n"
        f"Ubicación: {address}\n"
        f"Reporte: #{report.pk}\n"
        f"Motivo: {reason}\n"
        f"{settings.WEB_URL}/admin/reports/report/{report.pk}/change/"
    )


def notify_manual_moderation(report: Report, reason: str) -> None:
    token = settings.TELEGRAM_API_KEY
    chat_id = settings.USER_TELEGRAM
    if not token or not chat_id:
        return

    message = _message(report, reason)
    photo = _photo_jpeg(report)

    try:
        if photo:
            response = requests.post(
                f"https://api.telegram.org/bot{token}/sendPhoto",
                data={"chat_id": chat_id, "caption": message},
                files={"photo": ("reporte.jpg", photo, "image/jpeg")},
                timeout=settings.TELEGRAM_TIMEOUT_SECONDS,
            )
        else:
            response = requests.post(
                f"https://api.telegram.org/bot{token}/sendMessage",
                data={
                    "chat_id": chat_id,
                    "text": message,
                    "disable_web_page_preview": "true",
                },
                timeout=settings.TELEGRAM_TIMEOUT_SECONDS,
            )
        response.raise_for_status()
    except Exception as exc:
        # No se registra la URL porque contiene el token del bot.
        logger.warning("No se pudo enviar el aviso de Telegram: %s", type(exc).__name__)
