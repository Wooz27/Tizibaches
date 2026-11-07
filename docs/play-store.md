# Publicación y testers en Play Store

## Artefactos

Los nombres reales que produce Gradle son:

- AAB para Play Store: `app/build/app/outputs/bundle/release/app-release.aab`
- APK release para instalación directa: `app/build/app/outputs/flutter-apk/app-release.apk`

> Documentación anterior mencionaba `tizibaches-playstore.aab` y
> `tizibaches-release.apk`. Esos nombres **no** los genera Gradle. Si se copia el
> archivo equivocado se sube un `versionCode` viejo y Play Console lo rechaza.

- Package: `mx.tizimin.baches`
- `versionCode`: `5`
- `versionName`: `1.1.0`

Comandos:

```bash
cd app
flutter build appbundle --release --dart-define-from-file=config/app_config.json
flutter build apk --release --dart-define-from-file=config/app_config.json
```

El AAB está firmado con la llave de upload local. El APK release usa la misma
firma. Antes de cada nueva subida incrementa el `versionCode` en
`app/pubspec.yaml` (`1.1.0+6`, `1.1.0+7`, etc.).

### Verificar el `versionCode` antes de subir

```bash
unzip -p reales/<archivo>.aab base/manifest/AndroidManifest.xml > /tmp/m.bin
mkdir -p /tmp/m && cp /tmp/m.bin /tmp/m/AndroidManifest.xml
cd /tmp/m && zip -q ../m.apk AndroidManifest.xml
aapt2 dump xmltree --file AndroidManifest.xml /tmp/m.apk | head -6
```

Debe mostrar el `versionCode` esperado.

## Firma

El keystore se genera una sola vez y se guarda fuera de Git:

```text
app/android/tizibaches-upload.jks
app/android/key.properties
app/android/tizibaches-upload.local.txt
```

Respalda esos tres archivos en un lugar seguro. Si se pierde el keystore de
upload, Google Play puede permitir rotarlo, pero es un proceso manual.

SHA-1 de la llave de upload actual:

```text
ED:C1:1E:66:A7:A5:D9:CD:77:6C:B2:1E:A4:16:2A:91:7B:AF:67:69
```

Si Play App Signing está activo, Google firma la app con otra llave. Después de
la primera subida, copia el SHA-1 de **App Integrity > App signing** y agrégalo
también al cliente Android de Google OAuth.

## Google OAuth para testers

El `GOOGLE_WEB_CLIENT_ID` no cambia. Para que los testers puedan entrar:

1. En Google Cloud, abre el cliente OAuth **Android** del package
   `mx.tizimin.baches`.
2. Agrega el SHA-1 de upload mostrado arriba.
3. Después de subir el AAB, agrega también el SHA-1 de Play App Signing.
4. Mantén las cuentas de prueba como test users si la pantalla de consentimiento
   está en modo Testing.

Sin el SHA-1 de Play App Signing, el login de Google fallará en la versión
instalada desde Play aunque el APK esté firmado correctamente.

## Subida a Play Console

1. Crea la app en Play Console con el package `mx.tizimin.baches`.
2. Completa la ficha: nombre **Tízibaches**, idioma español, app gratuita,
   clasificación y formularios obligatorios.
3. Ve a **Testing > Internal testing**.
4. Crea una release y sube el AAB. Verifica antes el `versionCode`.
5. Escribe las notas de la versión y guarda la release.
6. En **Testers**, crea una lista con los correos de los testers y copia el
   enlace de opt-in.
7. Envía ese enlace a cada tester. Debe abrirlo con la misma cuenta de Google
   que registraste y aceptar la invitación.
8. Una vez que el tester acepta, Play muestra la app para instalar.

No se pueden agregar testers desde este repositorio: los correos y el acceso a
Play Console son necesarios en el panel de Google.

## APK directo

Para una demo sin Play Store:

```bash
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

El APK directo usa la llave de upload. Para Google Sign-In también debe estar
registrado su SHA-1 en el cliente Android.

Para entregar el APK a testers mientras Play aprueba la prueba cerrada, ver
[`docs/distribucion-apk.md`](./distribucion-apk.md).

## Variables de la app

La configuración pública usada por este build apunta a:

```text
API_BASE_URL=https://tizibaches.casatos.online
PUBLIC_WEB_URL=https://tizibaches.casatos.online/mapa
```

Si el dominio de la demo cambia, ejecuta `make app-config` y vuelve a compilar el
AAB y el APK.
