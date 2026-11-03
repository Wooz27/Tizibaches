import random
import shutil
from datetime import timedelta
from pathlib import Path

from django.conf import settings
from django.contrib.gis.geos import Point
from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from apps.accounts.models import User
from apps.reports.models import Pothole, Report, StatusEvent

# Calles y colonias de Tizimín para que las direcciones del demo sean legibles.
STREETS = [
    "Calle 20",
    "Calle 21",
    "Calle 22",
    "Calle 23",
    "Calle 24",
    "Calle 25",
    "Calle 26",
    "Calle 27",
    "Calle 28",
    "Calle 29",
    "Calle 30",
    "Calle 31",
    "Calle 32",
    "Calle 33",
    "Calle 34",
    "Calle 35",
    "Calle 36",
    "Calle 37",
    "Calle 38",
    "Calle 39",
    "Calle 40",
    "Calle 41",
    "Calle 42",
    "Calle 43",
    "Calle 44",
    "Calle 45",
    "Calle 46",
    "Calle 47",
    "Calle 48",
    "Calle 49",
    "Calle 50",
    "Calle 51",
    "Calle 52",
    "Calle 53",
    "Calle 54",
    "Calle 55",
    "Calle 56",
    "Calle 57",
    "Calle 58",
    "Calle 59",
    "Calle 60",
    "Calle 61",
    "Calle 62",
    "Calle 63",
    "Calle 64",
    "Calle 65",
    "Calle 66",
    "Calle 67",
    "Calle 68",
    "Calle 69",
    "Calle 70",
    "Calle 71",
    "Calle 72",
    "Calle 73",
    "Calle 74",
    "Calle 75",
    "Calle 76",
    "Calle 77",
    "Calle 78",
    "Calle 79",
    "Calle 80",
    "Calle 81",
    "Calle 82",
    "Calle 83",
    "Calle 84",
    "Calle 85",
    "Calle 86",
    "Calle 87",
    "Calle 88",
    "Calle 89",
    "Calle 90",
    "Calle 91",
    "Calle 92",
    "Calle 93",
    "Calle 94",
    "Calle 95",
    "Calle 96",
    "Calle 97",
    "Calle 98",
    "Calle 99",
    "Calle 100",
    "Avenida Juárez",
    "Avenida 5 de Mayo",
    "Avenida 20 de Noviembre",
    "Avenida Yucatán",
    "Avenida Tizimín",
]

COLONIAS = [
    "Centro",
    "Santa Cruz",
    "San Martín",
    "San Juan",
    "San Pedro",
    "La Ermita",
    "Las Flores",
    "El Cielo",
    "Los Reyes",
    "Santa Rita",
    "San Miguel",
    "Maya",
    "Benito Juárez",
    "Lázaro Cárdenas",
    "Vicente Guerrero",
    "Francisco Villa",
    "Ampliación Santa Cruz",
    "San José",
    "San Antonio",
    "Nueva Esperanza",
    "El Porvenir",
    "Los Pinos",
    "Santa María",
    "San Isidro",
    "La Guadalupe",
]

DESCRIPTIONS = [
    "Bache profundo en el carril derecho; ya dañó dos llantas.",
    "El hoyo ocupa media calle y se llena de agua cuando llueve.",
    "Bache junto al paso peatonal; los motociclistas tienen que esquivarlo.",
    "Grieta grande con piedras sueltas y concreto levantado.",
    "Hundimiento frente a la escuela, peligroso para los niños.",
    "Bache en la esquina, difícil de ver por la noche.",
    "El pavimento se está desprendiendo alrededor del hoyo.",
    "Hoyo de unos 40 centímetros que ya provocó caídas de ciclistas.",
    "Bache en el carril del transporte público; los camiones frenan de golpe.",
    "Superficie irregular y lodo acumulado en el cruce.",
    "Bache profundo cerca del mercado; el agua estancada atrae mosquitos.",
    "Daño en el pavimento que crece cada semana.",
    "Hoyo con bordes filosos en la entrada de la colonia.",
    "Bache doble en la avenida principal; el tráfico se vuelve lento.",
    "El concreto está levantado y golpea los bajos de los autos.",
]

STATUS_NOTES = {
    ("reported", "reported"): "Reporte ciudadano recibido.",
    ("reported", "verified"): "Se confirmó el bache en campo.",
    ("verified", "scheduled"): "Se programó la reparación con la cuadrilla de bacheo.",
    ("scheduled", "in_progress"): "La cuadrilla inició los trabajos en el lugar.",
    ("in_progress", "fixed"): "Bache reparado y superficie nivelada.",
    ("reported", "rejected"): "El reporte se descartó después de la inspección.",
}

CITIZENS = [
    ("citizen@example.com", "Ciudadano", "Demo"),
    ("maria.chan@example.com", "María", "Chan"),
    ("jorge.cauich@example.com", "Jorge", "Cauich"),
    ("ana.pool@example.com", "Ana", "Pool"),
    ("luis.canul@example.com", "Luis", "Canul"),
    ("sofia.uc@example.com", "Sofía", "Uc"),
]


class Command(BaseCommand):
    help = "Crea usuarios, baches, reportes e historial de demostración dentro de CITY_BBOX."

    def add_arguments(self, parser):
        parser.add_argument("--count", type=int, default=50)
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Borra los baches existentes antes de crear los datos de demostración.",
        )
        parser.add_argument(
            "--allow-production",
            action="store_true",
            help="Permite cargar datos demo fuera de DEBUG. Usar solo en un entorno controlado.",
        )

    def handle(self, *args, **options):
        if not settings.DEBUG and not options["allow_production"]:
            raise CommandError(
                "seed_demo crea usuarios y datos de demostración. "
                "Usa --allow-production solo en un entorno controlado."
            )
        if options["reset"]:
            Pothole.objects.all().delete()
            self.stdout.write("Se borraron los baches existentes.")

        staff = self._get_or_create_user(
            "staff@example.com",
            User.Role.STAFF,
            "Laura",
            "Pech",
            is_staff=True,
        )
        citizens = [
            self._get_or_create_user(email, User.Role.CITIZEN, first_name, last_name)
            for email, first_name, last_name in CITIZENS
        ]

        # Semilla fija para que los datos de demostración sean reproducibles.
        rng = random.Random(42)
        min_lon, min_lat, max_lon, max_lat = settings.CITY_BBOX
        now = timezone.now()
        photos = sorted((settings.BASE_DIR / "static" / "demo" / "potholes").glob("*.webp"))
        photo_names = self._prepare_photos(photos)
        if not photo_names:
            self.stdout.write(
                self.style.WARNING(
                    "No se encontraron fotos en static/demo/potholes; "
                    "los reportes se crearán sin foto."
                )
            )

        status_values = list(Pothole.Status.values)
        for index in range(options["count"]):
            # Recorre todos los estados una vez y después elige al azar.
            status = (
                status_values[index % len(status_values)]
                if index < len(status_values)
                else rng.choice(status_values)
            )

            first_report = now - timedelta(days=rng.randint(30, 120))
            max_span = max(1, min(90, (now - first_report).days))
            report_dates = sorted(
                first_report + timedelta(days=rng.randint(0, max_span), hours=rng.randint(0, 23))
                for _ in range(rng.randint(1, 3))
            )
            report_dates = [min(now, report_date) for report_date in report_dates]
            last_report = report_dates[-1]
            fixed_at = None
            if status == Pothole.Status.FIXED:
                fixed_at = min(now, last_report + timedelta(days=rng.randint(1, 10)))

            address = self._address(rng)
            pothole = Pothole.objects.create(
                location=Point(
                    rng.uniform(min_lon, max_lon),
                    rng.uniform(min_lat, max_lat),
                    srid=4326,
                ),
                status=status,
                severity=1,
                address=address,
                last_reported_at=last_report,
                fixed_at=fixed_at,
            )

            report_severities = []
            first_reporter = None
            for report_date in report_dates:
                reporter = rng.choice(citizens)
                if first_reporter is None:
                    first_reporter = reporter

                severity = max(1, min(4, rng.randint(1, 4)))
                report_severities.append(severity)
                report = Report(
                    pothole=pothole,
                    reporter=reporter,
                    location=pothole.location,
                    severity=severity,
                    description=rng.choice(DESCRIPTIONS),
                )
                if photo_names:
                    report.photo.name = rng.choice(photo_names)
                report.save()
                Report.objects.filter(pk=report.pk).update(created_at=report_date)

            pothole.severity = max(report_severities)
            pothole.report_count = len(report_dates)
            pothole.first_reported_at = report_dates[0]
            pothole.last_reported_at = last_report
            pothole.save(
                update_fields=[
                    "severity",
                    "report_count",
                    "first_reported_at",
                    "last_reported_at",
                ]
            )

            self._create_status_events(
                pothole=pothole,
                status=status,
                first_report=report_dates[0],
                last_report=last_report,
                fixed_at=fixed_at,
                now=now,
                staff=staff,
                first_reporter=first_reporter,
            )

        self.stdout.write(
            self.style.SUCCESS(
                f"Se crearon {options['count']} baches con "
                f"{Report.objects.count()} reportes de demostración."
            )
        )

    def _get_or_create_user(
        self,
        email: str,
        role: str,
        first_name: str,
        last_name: str,
        **extra_fields,
    ):
        user, created = User.objects.get_or_create(email=email)
        changed = created
        if user.role != role:
            user.role = role
            changed = True
        if user.first_name != first_name:
            user.first_name = first_name
            changed = True
        if user.last_name != last_name:
            user.last_name = last_name
            changed = True
        for field, value in extra_fields.items():
            if getattr(user, field) != value:
                setattr(user, field, value)
                changed = True
        if created:
            user.set_unusable_password()
        if changed:
            user.save()
        return user

    def _prepare_photos(self, photos):
        if not photos:
            return []
        destination = Path(settings.MEDIA_ROOT) / "reports" / "demo"
        destination.mkdir(parents=True, exist_ok=True)
        names = []
        for photo in photos:
            target = destination / photo.name
            if not target.exists():
                shutil.copyfile(photo, target)
            names.append(f"reports/demo/{photo.name}")
        return names

    def _address(self, rng):
        street = rng.choice(STREETS)
        number = rng.randint(100, 999)
        suffix = rng.choice(["", "", "-A", "-B", " Int. 2"])
        colonia = rng.choice(COLONIAS)
        return f"{street} #{number}{suffix}, Colonia {colonia}, Tizimín, Yucatán"

    def _status_sequence(self, status):
        if status == Pothole.Status.REPORTED:
            return [("reported", "reported")]
        if status == Pothole.Status.REJECTED:
            return [("reported", "rejected")]

        sequence = [("reported", "verified")]
        if status in (
            Pothole.Status.SCHEDULED,
            Pothole.Status.IN_PROGRESS,
            Pothole.Status.FIXED,
        ):
            sequence.append(("verified", "scheduled"))
        if status in (Pothole.Status.IN_PROGRESS, Pothole.Status.FIXED):
            sequence.append(("scheduled", "in_progress"))
        if status == Pothole.Status.FIXED:
            sequence.append(("in_progress", "fixed"))
        return sequence

    def _create_status_events(
        self,
        *,
        pothole,
        status,
        first_report,
        last_report,
        fixed_at,
        now,
        staff,
        first_reporter,
    ):
        sequence = self._status_sequence(status)
        if len(sequence) == 1:
            event_dates = [first_report]
        else:
            end = fixed_at or min(now, last_report + timedelta(days=7))
            if end <= first_report:
                end = first_report + timedelta(days=1)
            span = (end - first_report).total_seconds()
            event_dates = [
                first_report + timedelta(seconds=span * index / (len(sequence) - 1))
                for index in range(len(sequence))
            ]

        for (from_status, to_status), event_date in zip(sequence, event_dates, strict=True):
            # El primer registro lo genera el ciudadano; los demás, el personal.
            changed_by = first_reporter if to_status == Pothole.Status.REPORTED else staff
            event = StatusEvent.objects.create(
                pothole=pothole,
                from_status=from_status,
                to_status=to_status,
                changed_by=changed_by,
                note=STATUS_NOTES[(from_status, to_status)],
            )
            StatusEvent.objects.filter(pk=event.pk).update(created_at=event_date)
