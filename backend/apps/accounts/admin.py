from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from apps.accounts.forms import UserCreateForm, UserUpdateForm
from apps.accounts.models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    form = UserUpdateForm
    add_form = UserCreateForm
    ordering = ("email",)
    list_display = ("email", "first_name", "last_name", "role", "is_staff")
    list_filter = ("role", "is_staff", "is_superuser", "is_active")
    search_fields = ("email", "first_name", "last_name")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Datos personales", {"fields": ("first_name", "last_name", "avatar_url")}),
        (
            "Permisos",
            {
                "fields": (
                    "role",
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Fechas", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "role", "password1", "password2"),
            },
        ),
    )
