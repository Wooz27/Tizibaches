# Despliegue

El despliegue de referencia usa Docker Compose con Postgres/PostGIS, Django,
Astro y nginx. El APK es un cliente aparte; no forma parte del compose.

## Requisitos

- Docker Engine y Docker Compose v2, o Podman con `podman-compose`.
- Dominio con DNS apuntando al servidor.
- Certificado TLS, o un proxy delante (Caddy, Traefik o nginx con Certbot).
- Una llave de Google Gemini si se habilitará la moderación de fotos.
- Al menos 2 GB de RAM y almacenamiento persistente para la base y `media/`.

## Variables de producción

Parte de una copia privada de `.env.example`; nunca subas `.env` al repositorio.

```dotenv
POSTGRES_PASSWORD=<password-larga-aleatoria>
DJANGO_SECRET_KEY=<secreto-de-al-menos-64-caracteres>
DJANGO_DEBUG=0

DJANGO_ALLOWED_HOSTS=tizibaches.example
CSRF_TRUSTED_ORIGINS=https://tizibaches.example
CORS_ALLOWED_ORIGINS=https://tizibaches.example
WEB_URL=https://tizibaches.example
PUBLIC_API_URL=https://tizibaches.example
PUBLIC_APP_URL=https://tizibaches.example/app
APP_PORT=8080

DJANGO_TRUST_PROXY=1
DJANGO_SECURE_SSL_REDIRECT=1
DJANGO_SESSION_COOKIE_SECURE=1
DJANGO_CSRF_COOKIE_SECURE=1
DJANGO_SECURE_HSTS_SECONDS=31536000

GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=<android-client-id>.apps.googleusercontent.com
GOOGLE_CLIENT_IDS=<web-client-id>.apps.googleusercontent.com

AI_VERIFICATION_ENABLED=1
GEMINI_API_KEY=<gemini-key>
GEMINI_VISION_MODEL=gemini-3.1-flash-lite
```

`PUBLIC_API_URL` se compila dentro de Astro; si cambia el dominio hay que
reconstruir la imagen web. `DJANGO_ALLOWED_HOSTS` debe incluir el dominio y el
host que nginx reenvía.

## Primer arranque

```bash
cp .env.example .env
# Edita .env con valores reales, sin subirlo a Git.
docker compose up -d --build
docker compose exec backend python manage.py createsuperuser
```

El `entrypoint.sh` del backend ejecuta `migrate` y `collectstatic` antes de
arrancar Gunicorn. El proxy publica la web y la API en `APP_PORT`.

Para habilitar la moderación con IA:

```bash
docker compose --profile ai up -d ai-worker
```

El worker se puede detener en cualquier momento; los reportes nuevos quedan en
**Pendiente de revisión** hasta que se procesen.

## TLS y dominio

El `infra/nginx.conf` incluido escucha HTTP en el puerto 80. Para producción,
termina TLS en un proxy exterior y reenvía a `127.0.0.1:8080`, o agrega un
bloque `listen 443 ssl` con los certificados correspondientes. Mantén
`X-Forwarded-Proto: https` para que Django reconozca HTTPS.

No abras públicamente los puertos de Postgres, Django ni Astro. Solo debe quedar
expuesto el proxy (o el balanceador TLS).

## Operación

- Revisa salud: `GET /api/health/`.
- Respaldos: `docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' > baches.sql`;
  protege el archivo y prueba la restauración.
- `media/` y el volumen `pgdata` deben estar en almacenamiento persistente.
- No ejecutes `seed_demo` en producción. El comando rechaza hacerlo sin
  `--allow-production`, y ese flag es solo para entornos de prueba controlados.
- Revisa los logs del worker de IA y del backend sin registrar imágenes, tokens
  ni llaves.
- Configura límites de disco y una política de retención para fotos.

## APK

El APK release requiere `app/android/key.properties` y un keystore propio. No se
sube al repositorio. Google OAuth debe registrar el package
`mx.tizimin.baches` y el SHA-1 de la firma de release/Play App Signing. La
configuración pública se genera con `make app-config`; nunca incluye
`GOOGLE_SECRET` ni la llave de Gemini.

## Privacidad

La moderación con IA envía fotos a Google. La política de privacidad debe
informarlo y el despliegue de producción debe usar el nivel pagado de Gemini:
el nivel gratuito puede usar el contenido para mejorar productos de Google.
