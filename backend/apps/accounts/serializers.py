from rest_framework import serializers

from apps.accounts.models import User


class GoogleLoginSerializer(serializers.Serializer):
    # Un ID token real ronda 1-2 KB. El límite evita que se envíen megabytes
    # que luego se intentan parsear.
    id_token = serializers.CharField(max_length=4096, trim_whitespace=True)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "first_name", "last_name", "avatar_url", "role")
        read_only_fields = fields
