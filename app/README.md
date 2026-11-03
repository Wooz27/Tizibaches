# Tízibaches — app Android

App ciudadana en Flutter, **solo Android**. Usa la misma paleta que la web:
henequén, caliza, cenote, ink y amarillo maize.

## Qué incluye

- Mapa a pantalla completa con los expedientes públicos, búsqueda, filtros por
  estado y detalle con foto, severidad y acceso a cómo llegar.
- Acceso con Google y modo de exploración sin cuenta.
- Reporte con foto de cámara o galería, GPS, severidad y nota.
- Historial personal de reportes.
- Perfil, cierre de sesión y enlace al mapa abierto de la web.

## Levantar contra el backend

Desde la raíz del repositorio:

```bash
make podman-db
cd backend && uv run python manage.py migrate
uv run python manage.py seed_demo --reset
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,<lan-ip> \
  uv run python manage.py runserver 0.0.0.0:3000
```

La app necesita la URL LAN de la laptop, el **Web client ID** de Google y,
opcionalmente, el **Android client ID**:

```dotenv
GOOGLE_WEB_CLIENT_ID=<web-application-client-id>.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=<android-client-id>.apps.googleusercontent.com
```

El generador crea `app/config/app_config.json` solo con esos IDs públicos y la
URL de la API. **Nunca copia `GOOGLE_SECRET`**:

```bash
cd app && flutter pub get
cd ..
make app-config
make app          # o: make app-apk
```

También puedes ejecutar manualmente:

```bash
cd app
flutter run -d <android-device> --dart-define-from-file=config/app_config.json
flutter build apk --debug --dart-define-from-file=config/app_config.json
```

`GOOGLE_SECRET` queda únicamente en el backend y este flujo de ID token ni
siquiera lo usa.

## Google Sign-In

El cliente secreto **no se usa** en este flujo y nunca va en el APK.

En Google Cloud:

1. **Google Auth Platform / OAuth consent screen**: nombre, correo de soporte y
   contacto. Si está en `Testing`, agrega las cuentas Gmail del teléfono como
   test users.
2. **Web application client**: su ID es el `serverClientId` y el valor de
   `GOOGLE_CLIENT_IDS` en el backend.
3. **Android client**: package `mx.tizimin.baches` y SHA-1 de la firma debug:

```text
<debug-sha1>
```

Para release, agrega el SHA-1 de la firma de release o de Play App Signing.

Si aparece `[16] Account reauth failed`, Google rechazó la combinación de
cliente Android/cuenta. Verificá package + SHA-1, agregá la cuenta como test user
y vuelve a intentar.

## Desarrollo

```bash
flutter analyze
flutter test
```

El preview temporal de web fue retirado; el target de producto es Android.
Los flags `USE_DEMO_DATA=true` y `START_AS_GUEST=true` existen solo para
capturas de diseño y no se usan en builds normales.

## Firma release

El build release ya no usa la debug key. Copia
`app/android/key.properties.example` a `app/android/key.properties`, apunta
`storeFile` a tu keystore y completa las contraseñas. El archivo y los keystores
están en `.gitignore`.

Sin `key.properties`, el APK release queda sin firma y no debe publicarse.

## Datos demo

`seed_demo` se niega a correr fuera de `DEBUG` salvo que uses
`--allow-production` en un entorno controlado. Crea usuarios de demostración sin
contraseña utilizable; no hay una cuenta administradora con contraseña fija.

## Créditos

Desarrollado por Reynaldo Manzanilla.
