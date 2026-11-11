from django.db import transaction

from apps.accounts.models import User


class GoogleAccountConflict(Exception):
    # El email ya está vinculado a otra cuenta de Google.
    pass


MAX_NAME_LENGTH = 150
MAX_AVATAR_URL_LENGTH = 200


def _claim_text(claims: dict, key: str, limit: int) -> str:
    # Los claims vienen de Google, pero se recortan igual: un valor más largo
    # que la columna provoca un error al guardar.
    value = claims.get(key) or ""
    return str(value)[:limit].strip()


@transaction.atomic
def get_or_create_user_from_google(claims: dict) -> User:
    # Busca al usuario por el "sub" de Google o lo crea con los claims verificados.
    sub = claims["sub"]
    user = User.objects.select_for_update().filter(google_sub=sub).first()
    if user:
        return user

    email = claims["email"].strip().lower()
    user = User.objects.select_for_update().filter(email__iexact=email).first()
    if user and user.google_sub and user.google_sub != sub:
        raise GoogleAccountConflict("Este email ya está vinculado a otra cuenta de Google.")

    # Nunca se vincula automáticamente una cuenta con privilegios por coincidir
    # el email: quien controle ese buzón obtendría el rol completo (incluido
    # acceso al admin). Las cuentas de ciudadano sí se vinculan.
    if user is not None and user.google_sub is None:
        privileged = (
            user.is_staff or user.is_superuser or user.role != User.Role.CITIZEN
        )
        if privileged:
            raise GoogleAccountConflict(
                "Esta cuenta es de administración y no puede vincularse con Google. "
                "Entra con tu método original."
            )

    is_new = user is None
    if is_new:
        user = User(email=email)

    user.google_sub = sub
    user.email = email
    user.first_name = _claim_text(claims, "given_name", MAX_NAME_LENGTH) or user.first_name
    user.last_name = _claim_text(claims, "family_name", MAX_NAME_LENGTH) or user.last_name
    user.avatar_url = (
        _claim_text(claims, "picture", MAX_AVATAR_URL_LENGTH) or user.avatar_url
    )
    if is_new:
        user.set_unusable_password()
    user.save()
    return user
