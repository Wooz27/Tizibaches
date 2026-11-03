from io import BytesIO

import pytest
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image
from rest_framework.test import APIClient

from apps.accounts.models import User


@pytest.fixture(autouse=True)
def clear_throttle_cache():
    cache.clear()
    yield
    cache.clear()


@pytest.fixture(autouse=True)
def isolated_media(settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def citizen(db):
    return User.objects.create_user(email="citizen@example.com", password="test-pass-123")


@pytest.fixture
def staff(db):
    return User.objects.create_user(
        email="staff@example.com",
        password="test-pass-123",
        role=User.Role.STAFF,
        is_staff=True,
    )


@pytest.fixture
def auth_client(api_client, citizen):
    api_client.force_authenticate(user=citizen)
    return api_client


@pytest.fixture
def staff_client(api_client, staff):
    api_client.force_authenticate(user=staff)
    return api_client


@pytest.fixture
def report_photo():
    def make_photo(name: str = "pothole.png", size: tuple[int, int] = (40, 30)):
        buffer = BytesIO()
        Image.new("RGB", size, (120, 120, 120)).save(buffer, "PNG")
        return SimpleUploadedFile(name, buffer.getvalue(), content_type="image/png")

    return make_photo
