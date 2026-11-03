# Coordinates

## Storage

Potholes and reports store their position in a single GeoDjango field:

```python
location = models.PointField(srid=4326, geography=True)
```

- `srid=4326` is WGS84, the same coordinate system used by GPS receivers, Google
  Maps, MapLibre and mobile devices.
- `geography=True` stores a PostGIS `geography`. Distances are computed on the
  sphere and returned in meters, which is what a city-scale application needs.
- The field creates a GiST index automatically, so `dwithin` and `bboverlaps`
  queries stay fast.

Do not store `latitude` and `longitude` as separate `FloatField`s. That loses
the spatial index and every distance query has to be written by hand.

## Coordinate order

The most common bug in this kind of project is swapping the two numbers.

| Context | Order |
|---|---|
| Client payload (Flutter, GPS) | `latitude`, `longitude` |
| `geos.Point(...)` | `Point(x=longitude, y=latitude)` |
| GeoJSON | `[longitude, latitude]` |
| PostGIS `ST_MakePoint` | `lon, lat` |

All conversions go through one helper:

```python
def point_from_lat_lon(lat: float, lon: float) -> Point:
    return Point(float(lon), float(lat), srid=4326)
```

## Precision

Six decimal places are about 11 cm, more than enough for a pothole. No extra
precision is needed.

## City validation

`CITY_BBOX` in `.env` defines the city area as
`min_lon,min_lat,max_lon,max_lat`. A report outside the polygon is rejected:

```python
city = city_polygon()
if not is_inside_city(point):
    raise ValidationError("La ubicación está fuera del área de la ciudad.")
```

Replace the bounding box with the official city boundary polygon when the city
boundary is available.

## Deduplication

A new report is merged into an existing open pothole when it falls within
`DEDUPE_RADIUS_M` (15 m by default):

```python
Pothole.objects.filter(status__in=OPEN_STATUSES)
    .annotate(distance=Distance("location", point))
    .filter(distance__lte=D(m=settings.DEDUPE_RADIUS_M))
    .order_by("distance")
```

`Distance` on a geography column returns meters. The API response includes
`created` and `distance_m` so the app can explain what happened.

## Map queries

The map can request a viewport:

```
GET /api/potholes/geojson/?bbox=minLon,minLat,maxLon,maxLat
```

The backend converts the values to a polygon and filters with
`location__bboverlaps`. The response is a GeoJSON `FeatureCollection` limited to
5,000 features and cached for 60 seconds.

## Native requirements

GeoDjango needs GDAL, GEOS and PROJ. On Debian/Ubuntu:

```bash
sudo apt install -y binutils libproj-dev gdal-bin libgdal-dev libgeos-dev
```

If the libraries are not in the standard path, set `GDAL_LIBRARY_PATH` and
`GEOS_LIBRARY_PATH` in `.env`.
