#!/bin/sh
# Publica un APK para pruebas y muestra las variables que hay que poner en el .env.
# Uso: scripts/publish-release.sh reales/Tizibaches-1.1.0-v5.apk
set -eu

if [ "$#" -lt 1 ]; then
  echo "Uso: $0 <ruta-del-apk>" >&2
  exit 1
fi

APK="$1"
if [ ! -f "$APK" ]; then
  echo "No existe el archivo: $APK" >&2
  exit 1
fi

case "$APK" in
  *.apk) ;;
  *)
    echo "El archivo debe tener extensión .apk" >&2
    exit 1
    ;;
esac

DEST_DIR="${RELEASES_HOST_PATH:-./releases}"
VERSION="${APK_VERSION:-}"

# Lee versionName y versionCode directamente del APK si aapt está disponible.
BADGING=""
if command -v aapt >/dev/null 2>&1; then
  BADGING=$(aapt dump badging "$APK" 2>/dev/null | head -1 || true)
fi

APK_VERSION_NAME=$(printf '%s' "$BADGING" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
APK_VERSION_CODE=$(printf '%s' "$BADGING" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")

if [ -z "$VERSION" ]; then
  if [ -n "$APK_VERSION_NAME" ] && [ -n "$APK_VERSION_CODE" ]; then
    VERSION="${APK_VERSION_NAME} (${APK_VERSION_CODE})"
  else
    VERSION=$(basename "$APK" .apk | sed 's/^[Tt]izibaches-//')
  fi
fi

# El nombre del archivo no puede llevar espacios ni paréntesis.
FILE_VERSION=$(printf '%s' "$VERSION" | tr ' ()' '--' | sed 's/--*/-/g; s/-$//')

TARGET="$DEST_DIR/tizibaches-${FILE_VERSION}.apk"

mkdir -p "$DEST_DIR"
cp "$APK" "$TARGET"

SIZE_BYTES=$(wc -c <"$TARGET" | tr -d ' ')
SIZE_MB=$(awk -v bytes="$SIZE_BYTES" 'BEGIN { printf "%.1f", bytes / 1048576 }')
SHA256=$(sha256sum "$TARGET" | awk '{ print $1 }')
TODAY=$(date +%Y-%m-%d)

echo
echo "APK publicado en: $TARGET"
echo
echo "Copia estas líneas en el .env del servidor y reconstruye el contenedor web:"
echo
echo "PUBLIC_APK_URL=/releases/tizibaches-${FILE_VERSION}.apk"
echo "PUBLIC_APK_VERSION=${VERSION}"
echo "PUBLIC_APK_DATE=${TODAY}"
echo "PUBLIC_APK_SIZE=${SIZE_MB} MB"
echo "PUBLIC_APK_SHA256=${SHA256}"
echo
echo "Recuerda: flutter build appbundle genera app-release.aab."
echo "Verifica el versionCode antes de subirlo a Play Console."
