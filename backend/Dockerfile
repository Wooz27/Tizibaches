FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils \
        libproj-dev \
        gdal-bin \
        libgdal-dev \
        libgeos-dev \
        ca-certificates \
        curl \
        gosu \
    && rm -rf /var/lib/apt/lists/*

# Usuario sin privilegios para gunicorn y el worker.
RUN groupadd --system app && useradd --system --gid app --home /app app

COPY --from=ghcr.io/astral-sh/uv:0.8.15 /uv /uvx /bin/

WORKDIR /app

# El pyproject apunta a ../README.md; el contexto de build es la raíz del repo.
COPY README.md /README.md
COPY backend/ /app/

# Se reinstala el entorno dentro de la imagen. El .venv local no debe viajar:
# su Python apunta al host y deja el contenedor sin dependencias.
RUN rm -rf /app/.venv \
    && uv sync --frozen --no-dev \
    && chmod +x /app/entrypoint.sh \
    && mkdir -p /app/media /app/staticfiles \
    && chown -R app:app /app
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
