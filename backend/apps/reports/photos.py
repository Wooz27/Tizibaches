from io import BytesIO
from uuid import uuid4

from django.core.files.base import ContentFile
from PIL import Image, ImageOps, UnidentifiedImageError

from apps.reports.constants import (
    ALLOWED_PHOTO_FORMATS,
    MAX_PHOTO_BYTES,
    MAX_PHOTO_PIXELS,
    MAX_PHOTO_SIDE,
)

# Pillow solo avisa hasta ~179 M de píxeles. Se baja el umbral para que una
# imagen declarada como enorme falle antes de reservar memoria.
Image.MAX_IMAGE_PIXELS = MAX_PHOTO_PIXELS


class InvalidPhoto(Exception):
    # El archivo subido no es una foto válida para un reporte.
    pass


def process_uploaded_photo(uploaded_file) -> ContentFile:
    # Valida, redimensiona y elimina los metadatos de la foto.
    # Devuelve un WebP listo para guardar. Quitar el EXIF también borra
    # las coordenadas GPS que algunas cámaras incluyen.
    if uploaded_file.size > MAX_PHOTO_BYTES:
        raise InvalidPhoto("La foto supera los 8 MB.")

    try:
        uploaded_file.seek(0)
        Image.open(uploaded_file).verify()
        uploaded_file.seek(0)
        image = Image.open(uploaded_file)
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError, ValueError) as exc:
        raise InvalidPhoto("El archivo no es una imagen válida.") from exc

    if image.format not in ALLOWED_PHOTO_FORMATS:
        raise InvalidPhoto("Formato no soportado. Usa JPEG, PNG o WebP.")

    # Una imagen de pocos KB puede declarar dimensiones enormes. Se rechaza
    # antes de convertirla a RGB, que es donde se reserva la memoria real.
    width, height = image.size
    if width * height > MAX_PHOTO_PIXELS:
        raise InvalidPhoto("La imagen es demasiado grande.")

    image = ImageOps.exif_transpose(image).convert("RGB")
    image.thumbnail((MAX_PHOTO_SIDE, MAX_PHOTO_SIDE))

    output = BytesIO()
    image.save(output, format="WEBP", quality=82, method=6)
    return ContentFile(output.getvalue(), name=f"{uuid4().hex}.webp")
