SEVERITY_CHOICES = [
    (1, "Leve"),
    (2, "Moderado"),
    (3, "Grave"),
    (4, "Muy grave"),
]

# Un bache con uno de estos estados puede recibir reportes nuevos.
OPEN_STATUSES = ("reported", "verified", "scheduled", "in_progress")

MAX_PHOTO_BYTES = 8 * 1024 * 1024
MAX_PHOTO_SIDE = 1600
ALLOWED_PHOTO_FORMATS = {"JPEG", "PNG", "WEBP"}

MAX_GEOJSON_FEATURES = 5000


PUBLIC_REPORTED_STATUSES = ("reported", "verified", "scheduled")
PUBLIC_OFFICIAL_STATUSES = ("in_progress", "fixed")


def public_status(value: str) -> str:
    # El mapa público no afirma que el municipio haya verificado o programado.
    if value in PUBLIC_REPORTED_STATUSES:
        return "reported"
    return value


def public_pothole_status(
    status: str,
    *,
    has_confirmed: bool,
    has_pending: bool,
) -> str:
    # Un estado oficial de obra/reparación manda sobre la moderación.
    if status in PUBLIC_OFFICIAL_STATUSES:
        return status
    if has_confirmed:
        return public_status(status)
    if has_pending:
        return "pending"
    return public_status(status)


def public_report_status(moderation: str, pothole_status: str) -> str:
    if moderation == "rejected":
        return "rejected"
    if moderation == "pending":
        return "pending"
    return public_status(pothole_status)
