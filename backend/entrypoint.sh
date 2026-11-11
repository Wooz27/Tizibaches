#!/bin/sh
set -eu

# El contenedor arranca como root solo para ajustar los permisos del volumen
# de media (que puede venir con dueño root de despliegues anteriores) y luego
# cede el control a un usuario sin privilegios.
if [ "$(id -u)" = "0" ]; then
  chown -R app:app /app/media /app/staticfiles 2>/dev/null || true
fi

if [ "$#" -gt 0 ]; then
  if [ "$(id -u)" = "0" ]; then
    exec gosu app "$@"
  fi
  exec "$@"
fi

python manage.py migrate --noinput
python manage.py collectstatic --clear --noinput

if [ "$(id -u)" = "0" ]; then
  exec gosu app gunicorn config.wsgi:application \
    --bind "0.0.0.0:${PORT:-3000}" \
    --workers "${GUNICORN_WORKERS:-3}" \
    --timeout "${GUNICORN_TIMEOUT:-60}" \
    --access-logfile - \
    --error-logfile -
fi

exec gunicorn config.wsgi:application \
  --bind "0.0.0.0:${PORT:-3000}" \
  --workers "${GUNICORN_WORKERS:-3}" \
  --timeout "${GUNICORN_TIMEOUT:-60}" \
  --access-logfile - \
  --error-logfile -
