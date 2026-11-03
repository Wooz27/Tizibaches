import pytest
from rest_framework.test import APIClient
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(email="logout@example.com")


@pytest.mark.django_db
def test_logout_blacklists_refresh_token(api_client, user):
    refresh = RefreshToken.for_user(user)

    response = api_client.post(
        "/api/auth/logout/",
        {"refresh": str(refresh)},
        format="json",
    )

    assert response.status_code == 204
    assert BlacklistedToken.objects.filter(token__jti=refresh["jti"]).exists()


@pytest.mark.django_db
def test_logout_rejects_invalid_refresh(api_client):
    response = api_client.post(
        "/api/auth/logout/",
        {"refresh": "not-a-jwt"},
        format="json",
    )

    assert response.status_code == 400


@pytest.mark.django_db
def test_logout_requires_refresh(api_client):
    response = api_client.post("/api/auth/logout/", {}, format="json")

    assert response.status_code == 400
