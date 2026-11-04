# Configuración de Django para la API de Tízibaches.

from datetime import timedelta
from pathlib import Path

import environ
from django.core.exceptions import ImproperlyConfigured
from django.templatetags.static import static

BASE_DIR = Path(__file__).resolve().parent.parent
ROOT_DIR = BASE_DIR.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DEDUPE_RADIUS_M=(float, 15.0),
)
environ.Env.read_env(ROOT_DIR / ".env")

DEBUG = env("DJANGO_DEBUG")

SECRET_KEY = env("DJANGO_SECRET_KEY", default=None)
if not SECRET_KEY:
    raise ImproperlyConfigured("DJANGO_SECRET_KEY es obligatorio.")

DOMAIN = env("DOMAIN", default="localhost").strip() or "localhost"

ALLOWED_HOSTS = env.list(
    "DJANGO_ALLOWED_HOSTS",
    default=["localhost", "127.0.0.1", "testserver"] if DEBUG else [DOMAIN],
)
if DOMAIN not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(DOMAIN)

INSTALLED_APPS = [
    "jazzmin",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.gis",
    "django.contrib.postgres",
    "rest_framework",
    "rest_framework_gis",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    "django_filters",
    "drf_spectacular",
    "apps.accounts",
    "apps.reports",
    "apps.security",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.contrib.gis.db.backends.postgis",
        "NAME": env("POSTGRES_DB", default="baches"),
        "USER": env("POSTGRES_USER", default="baches"),
        "PASSWORD": env("POSTGRES_PASSWORD", default=""),
        "HOST": env("POSTGRES_HOST", default="localhost"),
        "PORT": env("POSTGRES_PORT", default="5432"),
    }
}

AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "es"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"]
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {
        # Jazzmin resuelve el directorio vendor/bootswatch como recurso estático;
        # el manifiesto estricto no contiene directorios y provoca 500 en /admin/.
        "BACKEND": "whitenoise.storage.CompressedStaticFilesStorage",
    },
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Las subidas se validan de nuevo en apps.reports.photos.
DATA_UPLOAD_MAX_MEMORY_SIZE = 8 * 1024 * 1024
FILE_UPLOAD_MAX_MEMORY_SIZE = 8 * 1024 * 1024

DEFAULT_ORIGIN = (
    "http://localhost:4321" if DEBUG else f"https://{DOMAIN}"
)
CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=[DEFAULT_ORIGIN],
)
if DOMAIN not in {"localhost", "127.0.0.1"}:
    for origin in (f"https://{DOMAIN}", f"http://{DOMAIN}"):
        if origin not in CORS_ALLOWED_ORIGINS:
            CORS_ALLOWED_ORIGINS.append(origin)
CORS_EXPOSE_HEADERS = ["ETag", "Last-Modified"]
CSRF_TRUSTED_ORIGINS = env.list(
    "CSRF_TRUSTED_ORIGINS",
    default=CORS_ALLOWED_ORIGINS,
)
WEB_URL = env(
    "WEB_URL",
    default="http://localhost:4321" if DEBUG else f"https://{DOMAIN}",
).rstrip("/")

# Producción: las flags se activan por defecto fuera de DEBUG.
SECURE_PROXY_SSL_HEADER = (
    ("HTTP_X_FORWARDED_PROTO", "https")
    if env.bool("DJANGO_TRUST_PROXY", default=False)
    else None
)
SECURE_SSL_REDIRECT = env.bool("DJANGO_SECURE_SSL_REDIRECT", default=not DEBUG)
SECURE_REDIRECT_EXEMPT = [r"^api/health/$"]
SESSION_COOKIE_SECURE = env.bool("DJANGO_SESSION_COOKIE_SECURE", default=not DEBUG)
CSRF_COOKIE_SECURE = env.bool("DJANGO_CSRF_COOKIE_SECURE", default=not DEBUG)
SECURE_HSTS_SECONDS = env.int(
    "DJANGO_SECURE_HSTS_SECONDS", default=31536000 if not DEBUG else 0
)
SECURE_HSTS_INCLUDE_SUBDOMAINS = env.bool(
    "DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS", default=not DEBUG
)
SECURE_HSTS_PRELOAD = env.bool("DJANGO_SECURE_HSTS_PRELOAD", default=not DEBUG)
SECURE_CONTENT_TYPE_NOSNIFF = True
SESSION_COOKIE_HTTPONLY = True
X_FRAME_OPTIONS = "DENY"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticatedOrReadOnly"],
    "DEFAULT_FILTER_BACKENDS": ["django_filters.rest_framework.DjangoFilterBackend"],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.LimitOffsetPagination",
    "PAGE_SIZE": 100,
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "60/min",
        "user": "120/min",
        "auth": "5/min",
        "report_create": "30/hour",
    },
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Tízibaches API",
    "DESCRIPTION": "Report and browse potholes in a city.",
    "VERSION": "0.1.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
}

# Área de la ciudad para validar reportes y limitar consultas del mapa.
CITY_NAME = env("CITY_NAME", default="Tizimín")
CITY_BBOX = tuple(
    float(value) for value in env("CITY_BBOX", default="-88.19,21.11,-88.11,21.18").split(",")
)
if len(CITY_BBOX) != 4:
    raise ValueError("CITY_BBOX debe ser 'min_lon,min_lat,max_lon,max_lat'.")

DEDUPE_RADIUS_M = env("DEDUPE_RADIUS_M")
REPORT_DUPLICATE_WINDOW_HOURS = env.int("REPORT_DUPLICATE_WINDOW_HOURS", default=12)
GEOJSON_CACHE_SECONDS = env.int("GEOJSON_CACHE_SECONDS", default=30)

GEOCODING_ENABLED = env.bool("GEOCODING_ENABLED", default=False)
GEOCODING_URL = env(
    "GEOCODING_URL",
    default="https://nominatim.openstreetmap.org/reverse",
)
GEOCODING_USER_AGENT = env("GEOCODING_USER_AGENT", default="Tizibaches/1.0")
GEOCODING_TIMEOUT_SECONDS = env.int("GEOCODING_TIMEOUT_SECONDS", default=6)

# Moderación de fotos con Gemini. El worker es opt-in para no generar costo
# accidentalmente si una instalación tiene una key configurada.
GEMINI_API_KEY = env("GEMINIS_KEY", default="") or env("GEMINI_API_KEY", default="")
AI_VERIFICATION_ENABLED = env.bool("AI_VERIFICATION_ENABLED", default=False)
GEMINI_VISION_MODEL = env("GEMINI_VISION_MODEL", default="gemini-3.1-flash-lite")
AI_CONFIRM_THRESHOLD = env.float("AI_CONFIRM_THRESHOLD", default=0.85)
AI_REJECT_THRESHOLD = env.float("AI_REJECT_THRESHOLD", default=0.90)
AI_AUTHENTICITY_THRESHOLD = env.float("AI_AUTHENTICITY_THRESHOLD", default=0.85)
AI_TIMEOUT_SECONDS = env.int("AI_TIMEOUT_SECONDS", default=25)
TELEGRAM_API_KEY = env("TELEGRAM_API_KEY", default="")
USER_TELEGRAM = env("USER_TELEGRAM", default="")
TELEGRAM_TIMEOUT_SECONDS = env.int("TELEGRAM_TIMEOUT_SECONDS", default=5)
AI_MAX_OUTPUT_TOKENS = env.int("AI_MAX_OUTPUT_TOKENS", default=200)
AI_THINKING_LEVEL = env("AI_THINKING_LEVEL", default="minimal")
if not 0 <= AI_CONFIRM_THRESHOLD <= 1:
    raise ValueError("AI_CONFIRM_THRESHOLD debe estar entre 0 y 1.")
if not 0 <= AI_REJECT_THRESHOLD <= 1:
    raise ValueError("AI_REJECT_THRESHOLD debe estar entre 0 y 1.")

# Los ID tokens de Google se verifican contra estas audiencias.
GOOGLE_CLIENT_IDS = env.list("GOOGLE_CLIENT_IDS", default=[])
GOOGLE_WEB_CLIENT_ID = env("GOOGLE_WEB_CLIENT_ID", default="").strip()
if GOOGLE_WEB_CLIENT_ID and GOOGLE_WEB_CLIENT_ID not in GOOGLE_CLIENT_IDS:
    # El ID token de Flutter se emite para el cliente Web (serverClientId).
    GOOGLE_CLIENT_IDS.append(GOOGLE_WEB_CLIENT_ID)

# Rutas explícitas opcionales para instalaciones no estándar de GDAL/GEOS.
GDAL_LIBRARY_PATH = env("GDAL_LIBRARY_PATH", default=None) or None
GEOS_LIBRARY_PATH = env("GEOS_LIBRARY_PATH", default=None) or None


def user_avatar(user):
    # Usa la foto de Google si existe; si no, el avatar de la marca.
    return user.avatar_url or static("img/tizibache-mark.webp")


JAZZMIN_SETTINGS = {
    "site_title": "Tízibaches",
    "site_header": "Tízibaches",
    "site_brand": "Tízibaches",
    "site_logo": "img/tizibache-admin-badge.webp",
    "login_logo": "img/tizibache-logo.webp",
    "login_logo_dark": "img/tizibache-logo.webp",
    "site_logo_classes": "brand-image",
    "site_icon": "img/tizibache-icon-32.png",
    "welcome_sign": "Panel de administración de Tízibaches",
    "copyright": "Tízibaches · Desarrollado por Reynaldo Manzanilla",
    "search_model": "reports.Pothole",
    "user_avatar": user_avatar,
    "topmenu_links": [
        {
            "name": "Mapa público",
            "url": f"{WEB_URL}/mapa",
            "new_window": True,
        },
        {
            "name": "Documentación API",
            "url": "/api/docs/",
            "new_window": True,
        },
        {"name": "Inicio", "url": "admin:index"},
    ],
    "usermenu_links": [
        {
            "name": "Mapa público",
            "url": f"{WEB_URL}/mapa",
            "new_window": True,
        },
        {
            "name": "Documentación API",
            "url": "/api/docs/",
            "new_window": True,
        },
    ],
    "custom_links": {
        "reports": [
            {
                "name": "Ver mapa público",
                "url": f"{WEB_URL}/mapa",
                "icon": "fas fa-map-marked-alt",
                "permissions": ["reports.view_pothole"],
            }
        ]
    },
    "show_sidebar": True,
    "navigation_expanded": True,
    "hide_apps": ["token_blacklist"],
    "hide_models": [],
    "order_with_respect_to": [
        "accounts",
        "accounts.user",
        "reports",
        "reports.pothole",
        "reports.report",
        "reports.statusevent",
        "security",
        "security.issuedtoken",
        "security.blockedtoken",
        "auth",
        "auth.group",
    ],
    "icons": {
        "accounts": "fas fa-users",
        "accounts.user": "fas fa-user-shield",
        "reports": "fas fa-road",
        "reports.pothole": "fas fa-road",
        "reports.report": "fas fa-camera",
        "reports.statusevent": "fas fa-clipboard-list",
        "security": "fas fa-shield-halved",
        "security.issuedtoken": "fas fa-key",
        "security.blockedtoken": "fas fa-ban",
        "auth": "fas fa-lock",
        "auth.group": "fas fa-users-cog",
    },
    "default_icon_parents": "fas fa-folder",
    "default_icon_children": "fas fa-circle",
    "related_modal_active": True,
    "custom_css": "css/admin.css",
    "use_google_fonts_cdn": False,
    "show_ui_builder": False,
    "changeform_format": "horizontal_tabs",
    "language_chooser": False,
}

JAZZMIN_UI_TWEAKS = {
    "navbar_small_text": False,
    "footer_small_text": False,
    "body_small_text": False,
    "brand_small_text": False,
    "brand_colour": "navbar-dark",
    "accent": "accent-warning",
    "navbar": "navbar-dark",
    "no_navbar_border": True,
    "navbar_fixed": True,
    "layout_fixed": True,
    "sidebar_fixed": True,
    "footer_fixed": False,
    "sidebar": "sidebar-dark-primary",
    "sidebar_nav_small_text": False,
    "sidebar_disable_expand": False,
    "sidebar_nav_child_indent": True,
    "sidebar_nav_compact_style": False,
    "sidebar_nav_legacy_style": False,
    "sidebar_nav_flat_style": False,
    "theme": "flatly",
    "button_classes": {
        "primary": "btn-warning",
        "secondary": "btn-outline-secondary",
        "info": "btn-info",
        "warning": "btn-warning",
        "danger": "btn-danger",
        "success": "btn-success",
    },
    "actions_sticky_top": True,
}
