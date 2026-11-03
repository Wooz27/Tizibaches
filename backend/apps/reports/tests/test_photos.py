from io import BytesIO

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image

from apps.reports.photos import InvalidPhoto, process_uploaded_photo


def image_file(size=(3000, 2000), image_format="PNG") -> SimpleUploadedFile:
    buffer = BytesIO()
    Image.new("RGB", size, (10, 120, 200)).save(buffer, image_format)
    return SimpleUploadedFile(
        f"photo.{image_format.lower()}",
        buffer.getvalue(),
        content_type=f"image/{image_format.lower()}",
    )


def test_photo_is_converted_to_webp_and_resized():
    result = process_uploaded_photo(image_file())

    assert result.name.endswith(".webp")
    image = Image.open(BytesIO(result.read()))
    assert image.format == "WEBP"
    assert max(image.size) <= 1600


def test_non_image_is_rejected():
    file = SimpleUploadedFile("notes.txt", b"not an image", content_type="text/plain")

    with pytest.raises(InvalidPhoto):
        process_uploaded_photo(file)


def test_oversized_photo_is_rejected():
    file = SimpleUploadedFile(
        "big.jpg",
        b"x" * (8 * 1024 * 1024 + 1),
        content_type="image/jpeg",
    )

    with pytest.raises(InvalidPhoto, match="8 MB"):
        process_uploaded_photo(file)
