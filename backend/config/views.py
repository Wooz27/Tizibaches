# Pequeños endpoints operativos.

from django.db import DatabaseError, connection
from django.http import JsonResponse


def health(request):
    # Indica si la aplicación puede conectarse a la base de datos.
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except DatabaseError:
        return JsonResponse({"status": "error", "database": "error"}, status=503)
    return JsonResponse({"status": "ok", "database": "ok"})
