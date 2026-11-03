from rest_framework import serializers

from apps.accounts.models import User


class GoogleLoginSerializer(serializers.Serializer):
    id_token = serializers.CharField()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "first_name", "last_name", "avatar_url", "role")
        read_only_fields = fields
