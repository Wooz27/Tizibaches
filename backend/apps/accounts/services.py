from django.db import transaction

from apps.accounts.models import User


class GoogleAccountConflict(Exception):
    # El email ya está vinculado a otra cuenta de Google.
    pass


@transaction.atomic
def get_or_create_user_from_google(claims: dict) -> User:
    # Busca al usuario por el "sub" de Google o lo crea con los claims verificados.
    sub = claims["sub"]
    user = User.objects.filter(google_sub=sub).first()
    if user:
        return user

    email = claims["email"].strip().lower()
    user = User.objects.filter(email__iexact=email).first()
    if user and user.google_sub and user.google_sub != sub:
        raise GoogleAccountConflict("Este email ya está vinculado a otra cuenta de Google.")

    is_new = user is None
    if is_new:
        user = User(email=email)

    user.google_sub = sub
    user.email = email
    user.first_name = claims.get("given_name", "") or user.first_name
    user.last_name = claims.get("family_name", "") or user.last_name
    user.avatar_url = claims.get("picture", "") or user.avatar_url
    if is_new:
        user.set_unusable_password()
    user.save()
    return user
