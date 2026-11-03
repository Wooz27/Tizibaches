.PHONY: db db-stop podman-db migrate run seed seed-reset test check install web app app-config app-apk app-test

ANDROID_DEVICE ?= $(shell adb devices | awk 'NR==2 {print $$1}')

install:
	cd backend && uv sync

db:
	docker compose up -d db

db-stop:
	docker compose down

podman-db:
	podman volume create baches_pgdata >/dev/null 2>&1 || true
	podman rm -f baches-db >/dev/null 2>&1 || true
	podman run -d --name baches-db --env-file .env -p 5432:5432 \
		-v baches_pgdata:/var/lib/postgresql postgis/postgis:18-3.6

migrate:
	cd backend && uv run python manage.py migrate

run:
	cd backend && uv run python manage.py runserver 0.0.0.0:3000

seed:
	cd backend && uv run python manage.py seed_demo

seed-reset:
	cd backend && uv run python manage.py seed_demo --reset

web:
	cd web && npm run dev

app-config:
	python3 app/tool/generate_config.py

app: app-config
	cd app && flutter run -d $(ANDROID_DEVICE) \
		--dart-define-from-file=config/app_config.json

app-apk: app-config
	cd app && flutter build apk --debug \
		--dart-define-from-file=config/app_config.json

app-test:
	cd app && flutter test

test:
	cd backend && uv run pytest

check:
	cd backend && uv run ruff check . && uv run ruff format --check .
