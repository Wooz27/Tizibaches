import pytest
from django.test import override_settings
from rest_framework.test import APIClient

from apps.accounts.models import User

CLAIMS = {
    "sub": "google-sub-123",
    "email": "citizen@example.com",
    "email_verified": True,
    "given_name": "Ada",
    "family_name": "Lovelace",
    "picture": "https://example.com/avatar.png",
}


@pytest.fixture
def mock_google(mocker):
    return mocker.patch("apps.accounts.google.id_token.verify_oauth2_token", return_value=CLAIMS)


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_google_login_creates_user_and_returns_tokens(api_client, mock_google):
    response = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    assert response.status_code == 200
    body = response.json()
    assert body["access"]
    assert body["refresh"]
    assert body["user"]["email"] == "citizen@example.com"
    assert body["user"]["role"] == "citizen"
    assert User.objects.count() == 1
    assert User.objects.get().google_sub == "google-sub-123"


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_google_login_is_idempotent(api_client, mock_google):
    api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")
    response = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    assert response.status_code == 200
    assert User.objects.count() == 1


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_google_login_links_an_existing_verified_email(api_client, mock_google):
    existing = User.objects.create_user(email="citizen@example.com", password="test-pass-123")

    response = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    assert response.status_code == 200
    existing.refresh_from_db()
    assert existing.google_sub == "google-sub-123"
    assert existing.has_usable_password() is True
    assert User.objects.count() == 1


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_google_login_rejects_an_email_linked_to_another_account(api_client, mock_google):
    User.objects.create_user(
        email="citizen@example.com",
        password="test-pass-123",
        google_sub="another-sub",
    )

    response = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    assert response.status_code == 409
    assert User.objects.count() == 1


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_invalid_google_token_returns_401(api_client, mocker):
    mocker.patch(
        "apps.accounts.google.id_token.verify_oauth2_token",
        side_effect=ValueError("bad token"),
    )

    response = api_client.post("/api/auth/google/", {"id_token": "invalid"}, format="json")

    assert response.status_code == 401
    assert User.objects.count() == 0


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_unverified_email_returns_401(api_client, mocker):
    mocker.patch(
        "apps.accounts.google.id_token.verify_oauth2_token",
        return_value={**CLAIMS, "email_verified": False},
    )

    response = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    assert response.status_code == 401
    assert User.objects.count() == 0


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=[])
def test_google_login_without_configuration_returns_401(api_client):
    response = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    assert response.status_code == 401
    assert User.objects.count() == 0


@pytest.mark.django_db
@override_settings(GOOGLE_CLIENT_IDS=["test-client"])
def test_login_access_token_authenticates_requests(api_client, mock_google):
    login = api_client.post("/api/auth/google/", {"id_token": "valid"}, format="json")

    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.json()['access']}")
    response = client.get("/api/me/")

    assert response.status_code == 200
    assert response.json()["email"] == "citizen@example.com"


@pytest.mark.django_db
def test_me_requires_authentication(api_client):
    response = api_client.get("/api/me/")

    assert response.status_code == 401


@pytest.mark.django_db
def test_me_returns_the_authenticated_user(auth_client):
    response = auth_client.get("/api/me/")

    assert response.status_code == 200
    assert response.json()["email"] == "citizen@example.com"
