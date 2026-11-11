from time import sleep, strftime

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.reports.ai import (
    AIAnalysisError,
    AIUnavailable,
    apply_ai_assessment,
    mark_ai_error,
    verify_report_photo,
)
from apps.reports.models import Report


class Command(BaseCommand):
    help = "Verifica fotos de reportes pendientes con Gemini mediante LangChain."

    def add_arguments(self, parser):
        parser.add_argument("--once", action="store_true", help="Procesa una sola tanda y sale.")
        parser.add_argument("--loop", action="store_true", help="Queda procesando reportes nuevos.")
        parser.add_argument(
            "--sleep",
            type=int,
            default=10,
            help="Segundos entre tandas en --loop.",
        )
        parser.add_argument("--limit", type=int, default=10, help="Máximo de fotos por tanda.")

    def handle(self, *args, **options):
        if not settings.AI_VERIFICATION_ENABLED:
            raise CommandError("Activa AI_VERIFICATION_ENABLED=1 para usar la verificación con IA.")
        if not settings.GEMINI_API_KEY:
            raise CommandError("Falta GEMINIS_KEY o GEMINI_API_KEY en el entorno.")

        mode = "loop" if options["loop"] else "once"
        self.stdout.write(
            self.style.SUCCESS(
                f"[{strftime('%H:%M:%S')}] [AI] worker iniciado "
                f"mode={mode} model={settings.GEMINI_VISION_MODEL} "
                f"sleep={options['sleep']}s limit={options['limit']}"
            )
        )

        while True:
            processed = 0
            for _ in range(max(1, options["limit"])):
                try:
                    if not self._process_next():
                        break
                except AIUnavailable as exc:
                    self.stderr.write(f"[AI] worker detenido: {exc}")
                    raise CommandError(str(exc)) from exc
                processed += 1

            self.stdout.write(
                f"[{strftime('%H:%M:%S')}] [AI] ciclo completado: verificados={processed}"
            )
            if options["once"] or not options["loop"]:
                return
            if processed == 0:
                sleep(max(1, options["sleep"]))

    def _process_next(self) -> bool:
        # La transacción solo sirve para tomar el siguiente pendiente. La
        # llamada a Gemini (hasta 25 s) y el aviso de Telegram corren fuera de
        # ella: mantener el lock durante la espera agota el pool de conexiones.
        with transaction.atomic():
            report_id = (
                Report.objects.select_for_update(skip_locked=True)
                .filter(ai_verdict=Report.AIVerdict.PENDING)
                .order_by("created_at")
                .values_list("pk", flat=True)
                .first()
            )

        if report_id is None:
            return False

        report = Report.objects.select_related("pothole").get(pk=report_id)
        self.stdout.write(
            f"[{strftime('%H:%M:%S')}] [AI] procesando reporte={report.pk} "
            f"pothole={report.pothole_id}"
        )
        try:
            assessment = verify_report_photo(report)
        except AIUnavailable:
            raise
        except AIAnalysisError as exc:
            mark_ai_error(report, exc)
            self.stderr.write(f"[AI] reporte={report.pk} error={exc}")
            return True
        except Exception as exc:
            mark_ai_error(report, exc)
            self.stderr.write(
                f"[AI] reporte={report.pk} error_inesperado={type(exc).__name__}"
            )
            return True

        apply_ai_assessment(report, assessment)
        self.stdout.write(
            f"[{strftime('%H:%M:%S')}] [AI] reporte={report.pk} "
            f"pothole={report.pothole_id} es_bache={assessment.is_pothole} "
            f"confianza={assessment.confidence:.2f} "
            f"moderacion={report.moderation} "
            f"veredicto={report.ai_verdict}"
        )
        return True
