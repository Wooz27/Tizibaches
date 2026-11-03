from django.contrib.auth.base_user import BaseUserManager


class UserManager(BaseUserManager):
    # Crea usuarios con email en lugar de nombre de usuario.

    use_in_migrations = True

    def create_user(self, email: str, password: str | None = None, **extra_fields):
        if not email:
            raise ValueError("El email es obligatorio.")
        user = self.model(email=self.normalize_email(email), **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email: str, password: str | None = None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)

        if not extra_fields["is_staff"] or not extra_fields["is_superuser"]:
            raise ValueError("Un superusuario debe tener is_staff=True e is_superuser=True.")

        return self.create_user(email, password, **extra_fields)
