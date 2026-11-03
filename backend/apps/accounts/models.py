from django.contrib.auth.models import AbstractUser
from django.db import models

from apps.accounts.managers import UserManager


class User(AbstractUser):
    # Cuenta de ciudadano o de administración.
    # Las cuentas de Google se identifican por el claim estable "sub".
    # El email puede cambiar, así que no se usa como identificador externo.

    class Role(models.TextChoices):
        CITIZEN = "citizen", "Ciudadano"
        STAFF = "staff", "Administrador"

    username = None
    email = models.EmailField("Correo electrónico", unique=True)
    google_sub = models.CharField(
        "Identificador de Google", max_length=255, unique=True, null=True, blank=True
    )
    avatar_url = models.URLField("URL del avatar", blank=True)
    role = models.CharField("Rol", max_length=20, choices=Role.choices, default=Role.CITIZEN)

    first_name = models.CharField("Nombre", max_length=150, blank=True)
    last_name = models.CharField("Apellido", max_length=150, blank=True)
    is_active = models.BooleanField(
        "Activo",
        default=True,
        help_text="Desmarcá esta opción para deshabilitar la cuenta.",
    )
    is_staff = models.BooleanField(
        "Acceso al admin",
        default=False,
        help_text="Indica si el usuario puede entrar al panel de administración.",
    )
    is_superuser = models.BooleanField(
        "Superusuario",
        default=False,
        help_text="Tiene todos los permisos sin necesidad de asignarlos explícitamente.",
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    class Meta:
        verbose_name = "Usuario"
        verbose_name_plural = "Usuarios"

    def __str__(self) -> str:
        return self.email
