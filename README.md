# Tízibaches

Open-source platform for reporting potholes in a city.

Three projects share one repository:

| Folder | Stack | Purpose |
|---|---|---|
| `backend/` | Django 6 + DRF + GeoDjango | API, authentication, spatial logic |
| `web/` | Astro 6 + React + Tailwind + shadcn/ui | Public landing page and interactive map |
| `app/` | Flutter | Citizen app to sign in with Google and report potholes |

All three projects are implemented. The citizen app is Android-only.

## Docker Compose quickstart

The server stack is Postgres + Django + Astro + nginx:

```bash
cp .env.example .env
# Edita .env: DOMAIN, HOST_PORT, POSTGRES_PASSWORD, DJANGO_SECRET_KEY y Google IDs
docker compose up -d --build
```

- Web: `http://localhost/` (o `http://localhost:<HOST_PORT>/` si cambiaste el puerto)
- Map: `http://localhost/mapa`
- Admin: `http://localhost/admin/`
- API health: `http://localhost/api/health/`

The Flutter app is **not** a compose service. It is an Android client compiled
and installed separately:

```bash
make app-config
make app-apk
adb install -r app/build/app/outputs/flutter-apk/app-debug.apk
```

For demo data inside Docker:

```bash
docker compose run --rm backend python manage.py seed_demo --reset --allow-production
```

## Backend quickstart

Requirements: Docker (or Podman), Python 3.12+ and [uv](https://docs.astral.sh/uv/).

GeoDjango also needs the native geospatial libraries:

```bash
sudo apt install -y binutils libproj-dev gdal-bin libgdal-dev libgeos-dev
```

Start the database and the API:

```bash
cp .env.example .env
make db
cd backend
uv sync
uv run python manage.py migrate
uv run python manage.py seed_demo --reset
uv run python manage.py runserver 0.0.0.0:3000
```

The API is available at `http://localhost:3000/api/`, the admin at `http://localhost:3000/admin/`.
`seed_demo --reset` recreates the complete demo dataset with addresses, reports, photos and status history.

## Web quickstart

The public site consumes the API from the server and the map tiles from OpenFreeMap.

```bash
cd web
cp .env.example .env
npm install --include=dev
npm run dev
```

Open `http://localhost:4321/` for the landing and `http://localhost:4321/mapa` for the full-screen map.
`API_URL` is the backend address used by Astro on the server; `PUBLIC_API_URL` is the address the browser uses for photos.

## Android app quickstart

The app lives in `app/` and targets Android only. It uses the same palette and
type system as the web.

```bash
adb reverse tcp:3000 tcp:3000   # or use the laptop LAN IP
cd app
flutter pub get
flutter run -d <android-device> \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

For a physical phone on the same Wi-Fi, use
`--dart-define=API_BASE_URL=http://<lan-ip>:3000` and include that IP in
`DJANGO_ALLOWED_HOSTS`. Google Sign-In requires the Android OAuth client with
package `mx.tizimin.baches` and the signing SHA-1; the setup is documented in
[app/README.md](app/README.md) and [docs/google-auth.md](docs/google-auth.md).

### Using Podman instead of Docker

```bash
make podman-db
```

### Tests and linting

```bash
make test
make check
```

## API overview

| Method | Path | Description |
|---|---|---|
| GET | `/api/health/` | Health check |
| POST | `/api/auth/google/` | Exchange a Google ID token for JWT tokens |
| POST | `/api/auth/refresh/` | Refresh an access token |
| GET | `/api/me/` | Current user |
| POST | `/api/reports/` | Create a report (multipart, authenticated) |
| GET | `/api/reports/mine/` | Reports created by the current user |
| GET | `/api/potholes/` | List potholes |
| GET | `/api/potholes/{id}/` | Pothole detail |
| GET | `/api/potholes/geojson/` | GeoJSON FeatureCollection for the map |
| GET | `/api/docs/` | OpenAPI documentation |

Coordinates are stored as WGS84 points (`SRID 4326`) with the PostGIS `geography` type, so distance queries are expressed in meters. Clients send `latitude` and `longitude`; GeoJSON returns `[longitude, latitude]`.

## Documentation

- [Coordinates and spatial queries](docs/coordinates.md)
- [Google sign-in setup](docs/google-auth.md)
- [AI photo moderation](docs/ai-moderation.md)
- [Deployment](docs/deployment.md)
- [Play Store and testers](docs/play-store.md)
- [Web frontend](web/README.md)
- [Android app](app/README.md)

## Repository conventions

- Code and documentation in English; user-facing strings in Spanish.
- Standard Django structure: model, serializer, view. Business logic lives in small, named functions.
- No secrets in the repository. Copy `.env.example` and keep `.env` local.
- Conventional commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT. See [LICENSE](LICENSE).

## Security notes

- Production requires `DJANGO_DEBUG=0` and a private `DJANGO_SECRET_KEY`.
- HTTPS, secure cookies, HSTS and proxy trust are enabled outside DEBUG and can
  be tuned with the `DJANGO_SECURE_*` / `DJANGO_TRUST_PROXY` variables.
- Release APKs must use `app/android/key.properties`; the debug key is not valid
  for distribution.
- Demo seed data creates demo users; rotate or remove those accounts before production.

## Créditos

Desarrollado por Reynaldo Manzanilla.
