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
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.8.15 /uv /uvx /bin/

WORKDIR /app

# El pyproject apunta a ../README.md; el contexto de build es la raíz del repo.
COPY README.md /README.md
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen --no-dev

COPY backend/ /app/
RUN chmod +x /app/entrypoint.sh
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
