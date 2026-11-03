from django.contrib.auth.forms import UserChangeForm, UserCreationForm

from apps.accounts.models import User


class UserCreateForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("email", "role")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["email"].label = "Correo electrónico"
        self.fields["role"].label = "Rol"
        self.fields["password1"].label = "Contraseña"
        self.fields[
            "password1"
        ].help_text = (
            "La contraseña debe tener al menos 8 caracteres y no puede ser demasiado común."
        )
        self.fields["password2"].label = "Confirmar contraseña"
        self.fields["password2"].help_text = "Ingresá la misma contraseña para verificarla."


class UserUpdateForm(UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User
        fields = "__all__"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        labels = {
            "email": "Correo electrónico",
            "first_name": "Nombre",
            "last_name": "Apellido",
            "avatar_url": "URL del avatar",
            "role": "Rol",
            "is_active": "Activo",
            "is_staff": "Acceso al admin",
            "is_superuser": "Superusuario",
            "groups": "Grupos",
            "user_permissions": "Permisos",
            "last_login": "Último acceso",
            "date_joined": "Fecha de alta",
            "password": "Contraseña",
        }
        for field_name, label in labels.items():
            if field_name in self.fields:
                self.fields[field_name].label = label
