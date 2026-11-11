from django.contrib import admin
from django.contrib.admin.sites import NotRegistered
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken

from apps.security.models import BlockedToken, IssuedToken

# Oculta la sección original en inglés y muestra los mismos datos en español.
for model in (OutstandingToken, BlacklistedToken):
    try:
        admin.site.unregister(model)
    except NotRegistered:
        pass


@admin.register(IssuedToken)
class IssuedTokenAdmin(admin.ModelAdmin):
    list_display = ("usuario", "identificador", "creado", "vence")
    list_select_related = ("user",)
    search_fields = ("user__email", "jti")
    list_per_page = 50
    # El campo token guarda el JWT completo. Mostrarlo permitiría a cualquiera
    # con permiso de solo lectura suplantar al usuario durante 30 días.
    exclude = ("token",)
    readonly_fields = ("jti", "user", "created_at", "expires_at")

    def has_view_permission(self, request, obj=None):
        return request.user.is_superuser

    def has_module_permission(self, request):
        return request.user.is_superuser

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    @admin.display(description="Usuario", ordering="user")
    def usuario(self, obj):
        return obj.user or "Sin usuario"

    @admin.display(description="Identificador", ordering="jti")
    def identificador(self, obj):
        return obj.jti

    @admin.display(description="Creado", ordering="created_at")
    def creado(self, obj):
        return obj.created_at

    @admin.display(description="Vence", ordering="expires_at")
    def vence(self, obj):
        return obj.expires_at


@admin.register(BlockedToken)
class BlockedTokenAdmin(admin.ModelAdmin):
    list_display = ("token_emitido", "bloqueado")
    list_select_related = ("token", "token__user")
    list_per_page = 50
    exclude = ("token",)

    def has_view_permission(self, request, obj=None):
        return request.user.is_superuser

    def has_module_permission(self, request):
        return request.user.is_superuser

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    @admin.display(description="Token emitido", ordering="token")
    def token_emitido(self, obj):
        return obj.token

    @admin.display(description="Bloqueado", ordering="blacklisted_at")
    def bloqueado(self, obj):
        return obj.blacklisted_at
