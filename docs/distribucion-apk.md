# Distribución temporal del APK

Este documento describe el puente temporal para entregar el APK a testers mientras
Google Play aprueba la prueba cerrada.

> **Es temporal.** Al aprobarse Play Store, se retira. Los pasos de retiro están al final.

---

## Advertencia: el repositorio es público

El código de `/descargar`, el bloque `location /releases/` de nginx y este documento
son públicos. Cualquiera que lea el repositorio sabrá que el enlace existe.

Eso es aceptable porque:

- El APK está firmado con el keystore del proyecto. Quien lo descargue no puede
  modificarlo ni firmar actualizaciones.
- El riesgo real no es de seguridad, sino de que alguien instale una versión alfa
  pensando que es oficial.

La mitigación es la página `/descargar`: dice con claridad que es una versión de
prueba, que no está en Play y que el proyecto es independiente del Ayuntamiento.

Si en el futuro se necesita privacidad real, habría que agregar un token por tester
en el backend. No está implementado porque este puente es temporal.

---

## 1. Compilar el APK

```bash
cd app
flutter build apk --release --dart-define-from-file=config/app_config.json
```

Salida real: `app/build/app/outputs/flutter-apk/app-release.apk`

> No confundir con el AAB. `flutter build appbundle` produce
> `app/build/app/outputs/bundle/release/app-release.aab`. Los nombres
> `tizibaches-release.apk` y `tizibaches-playstore.aab` que aparecen en documentación
> antigua no los genera Gradle.

---

## 2. Publicar el APK

```bash
scripts/publish-release.sh reales/Tizibaches-1.1.0-v5.apk
```

El script:

1. Copia el APK a `${RELEASES_HOST_PATH:-./releases}` con el nombre
   `tizibaches-<version>.apk`.
2. Calcula el tamaño y el SHA-256.
3. Imprime las variables listas para pegar en el `.env`.

Si el directorio no existe en el servidor:

```bash
sudo mkdir -p /opt/tizibaches/releases
sudo chown "$USER":"$USER" /opt/tizibaches/releases
```

---

## 3. Configurar las variables

En el `.env` del servidor:

```bash
RELEASES_HOST_PATH=/opt/tizibaches/releases
PUBLIC_APK_URL=/releases/tizibaches-1.1.0-v5.apk
PUBLIC_APK_VERSION=1.1.0 (5)
PUBLIC_APK_DATE=2026-11-04
PUBLIC_APK_SIZE=58.5 MB
PUBLIC_APK_SHA256=<hash que imprimió el script>
```

---

## 4. Reconstruir `web` y `proxy`

`PUBLIC_APK_*` es una variable de **build** de Astro. Reiniciar no basta.

```bash
docker compose build web
docker compose up -d web proxy
```

El `proxy` debe recrearse porque cambió el montaje de `/srv/releases`.

Si usas Dokploy: **Redeploy** de los servicios `web` y `proxy`.

---

## 5. Verificar

```bash
curl -I https://<dominio>/releases/tizibaches-1.1.0-v5.apk
```

Debe devolver:

```text
HTTP/2 200
content-type: application/vnd.android.package-archive
x-robots-tag: noindex, nofollow
x-content-type-options: nosniff
```

El listado del directorio debe estar cerrado:

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://<dominio>/releases/
```

Debe devolver `403` o `404`, nunca un `200` con listado.

La página:

```bash
curl -s https://<dominio>/descargar | grep -i noindex
```

Debe encontrar `<meta name="robots" content="noindex, nofollow">`.

---

## 6. Compartir con los testers

Envía únicamente:

```text
https://<dominio>/descargar
```

No compartas la ruta directa del APK. Así el tester ve las instrucciones de
instalación y el aviso de versión de prueba.

### Antes de enviar el enlace, verifica

1. **Usuarios de prueba en OAuth.** Si la pantalla de consentimiento está en modo
   *Testing*, agrega el correo de cada tester en Google Cloud → OAuth consent screen
   → Test users. Sin esto, el botón de Google falla.
2. **SHA-1 del keystore.** El APK está firmado con `tizibaches-upload.jks`, cuyo
   SHA-1 debe estar registrado en el cliente OAuth Android.
3. **El archivo existe.** Un enlace a un 404 es el error más común.

---

## 7. Publicar una versión nueva

1. Sube el `versionCode` en `app/pubspec.yaml`.
2. Recompila el APK.
3. Cambia el nombre del archivo a `tizibaches-<version>.apk`.
4. Ejecuta `scripts/publish-release.sh`.
5. Actualiza `PUBLIC_APK_*` en el `.env`.
6. Reconstruye `web`.

Los enlaces viejos dejan de funcionar si borras el archivo anterior. Eso es
intencional: evita que los testers instalen una versión obsoleta.

---

## 8. Retirar el puente cuando Play apruebe

Orden recomendado:

1. Vaciar `PUBLIC_APK_*` en el `.env` y reconstruir `web`.
   - `/descargar` muestra "La descarga no está disponible".
   - El CTA de `/app` desaparece automáticamente.
2. Borrar el contenido de `RELEASES_HOST_PATH` en el servidor.
3. Quitar el bloque `location /releases/` de `infra/nginx.conf`.
4. Quitar el montaje `"${RELEASES_HOST_PATH:-./releases}:/srv/releases:ro"` de
   `docker-compose.yml`.
5. Borrar `web/src/pages/descargar.astro` y las líneas `Disallow: /descargar` y
   `Disallow: /releases/` de `web/public/robots.txt`.
6. Quitar los `PUBLIC_APK_*` del `.env.example` y del `web/Dockerfile`.
7. Reconstruir `web` y `proxy`.

Ningún paso toca el backend, la base de datos ni la app.

---

## Notas de seguridad

- El APK se sirve solo por HTTPS; Cloudflare se encarga del certificado.
- `Cache-Control: max-age=300` mantiene el APK fuera de cachés largas.
- `autoindex off` evita listar el directorio.
- No se publica nunca el keystore ni `key.properties`.
- No se guarda ningún token de Telegram, Gemini ni de base de datos en `releases/`.
