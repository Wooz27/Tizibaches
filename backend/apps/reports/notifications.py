import logging
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from django.conf import settings

from apps.reports.models import Report

logger = logging.getLogger(__name__)


def notify_manual_moderation(report: Report, reason: str) -> None:
    token = settings.TELEGRAM_API_KEY
    chat_id = settings.USER_TELEGRAM
    if not token or not chat_id:
        return

    name = report.pothole.name.strip()
    title = f"{name} " if name else ""
    message = (
        "⚠️ Moderación manual requerida\n"
        f"Expediente: #{report.pothole_id} {title}\n"
        f"Reporte: #{report.pk}\n"
        f"Motivo: {reason}\n"
        f"{settings.WEB_URL}/admin/reports/report/{report.pk}/change/"
    )
    payload = urlencode(
        {
            "chat_id": chat_id,
            "text": message,
            "disable_web_page_preview": "true",
        }
    ).encode()
    request = Request(
        f"https://api.telegram.org/bot{token}/sendMessage",
        data=payload,
        method="POST",
    )

    try:
        with urlopen(request, timeout=settings.TELEGRAM_TIMEOUT_SECONDS) as response:
            response.read()
    except Exception as exc:
        # No se registra la URL porque contiene el token del bot.
        logger.warning(
            "No se pudo enviar el aviso de Telegram: %s", type(exc).__name__
        )
