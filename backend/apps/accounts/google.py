from django.conf import settings
from google.auth.exceptions import GoogleAuthError
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token


class InvalidGoogleToken(Exception):
    # Google rechazó el token o faltan claims obligatorios.
    pass


def verify_google_id_token(raw_token: str) -> dict:
    # Valida un ID token de Google y devuelve sus claims.
    # La comprobación de audiencia evita aceptar tokens emitidos para otra app.
    if not settings.GOOGLE_CLIENT_IDS:
        raise InvalidGoogleToken("El inicio de sesión con Google no está configurado.")

    try:
        claims = id_token.verify_oauth2_token(
            raw_token,
            google_requests.Request(),
            audience=settings.GOOGLE_CLIENT_IDS,
        )
    except (ValueError, GoogleAuthError) as exc:
        raise InvalidGoogleToken("El ID token de Google no es válido.") from exc

    if not claims.get("email_verified"):
        raise InvalidGoogleToken("El email de la cuenta de Google no está verificado.")
    if not claims.get("sub") or not claims.get("email"):
        raise InvalidGoogleToken("El token de Google no tiene los datos obligatorios.")

    return claims
