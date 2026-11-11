# Helpers de coordenadas.
# El cliente envía latitude y longitude; Point y GeoJSON usan (lon, lat).
# Todas las conversiones viven aquí para no invertir el orden por accidente.

from django.conf import settings
from django.contrib.gis.geos import Point, Polygon


def point_from_lat_lon(lat: float, lon: float) -> Point:
    return Point(float(lon), float(lat), srid=4326)


def city_polygon() -> Polygon:
    min_lon, min_lat, max_lon, max_lat = settings.CITY_BBOX
    polygon = Polygon.from_bbox((min_lon, min_lat, max_lon, max_lat))
    polygon.srid = 4326
    return polygon


def is_inside_city(point: Point) -> bool:
    return city_polygon().contains(point)


def bbox_from_query(value: str) -> Polygon:
    # Convierte "minLon,minLat,maxLon,maxLat" en un polígono.
    try:
        min_lon, min_lat, max_lon, max_lat = (float(part) for part in value.split(","))
    except (AttributeError, ValueError) as exc:
        raise ValueError("bbox debe ser 'minLon,minLat,maxLon,maxLat'.") from exc

    if min_lon >= max_lon or min_lat >= max_lat:
        raise ValueError("Los valores mínimos de bbox deben ser menores que los máximos.")

    if not (-180 <= min_lon <= 180 and -180 <= max_lon <= 180):
        raise ValueError("La longitud debe estar entre -180 y 180.")

    if not (-90 <= min_lat <= 90 and -90 <= max_lat <= 90):
        raise ValueError("La latitud debe estar entre -90 y 90.")

    polygon = Polygon.from_bbox((min_lon, min_lat, max_lon, max_lat))
    polygon.srid = 4326
    return polygon
