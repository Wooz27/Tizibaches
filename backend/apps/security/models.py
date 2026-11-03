from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken


class IssuedToken(OutstandingToken):
    # Token JWT emitido y todavía vigente.
    class Meta:
        proxy = True
        verbose_name = "Token emitido"
        verbose_name_plural = "Tokens emitidos"


class BlockedToken(BlacklistedToken):
    # Token JWT revocado.
    class Meta:
        proxy = True
        verbose_name = "Token bloqueado"
        verbose_name_plural = "Tokens bloqueados"
