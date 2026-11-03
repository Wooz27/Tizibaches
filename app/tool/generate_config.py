#!/usr/bin/env python3
"""Genera app/config/app_config.json solo con valores públicos.

Nunca copia GOOGLE_SECRET ni ninguna credencial del backend.
"""

from __future__ import annotations

import json
import socket
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app"
ENV_FILE = ROOT / ".env"
OUT_FILE = APP / "config" / "app_config.json"


def read_env() -> dict[str, str]:
    values: dict[str, str] = {}
    if not ENV_FILE.exists():
        return values
    for raw in ENV_FILE.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def lan_ip() -> str:
    configured = read_env().get("API_HOST", "").strip()
    if configured:
        return configured
    try:
        output = subprocess.check_output(["hostname", "-I"], text=True).split()
        for candidate in output:
            if "." in candidate and not candidate.startswith("127."):
                return candidate
    except Exception:
        pass
    try:
        return socket.gethostbyname(socket.gethostname())
    except OSError:
        return "127.0.0.1"


def main() -> None:
    env = read_env()
    host = lan_ip()
    android_id = env.get("GOOGLE_ANDROID_CLIENT_ID", "").strip()
    web_id = env.get("GOOGLE_WEB_CLIENT_ID", "").strip()

    if not web_id:
        print("AVISO: falta GOOGLE_WEB_CLIENT_ID en .env.")
        print("       Es el ID del cliente OAuth *Web application*, no el Android.")
    if android_id and web_id and android_id == web_id:
        print("ERROR: GOOGLE_WEB_CLIENT_ID y GOOGLE_ANDROID_CLIENT_ID son iguales.")
        print("       El serverClientId debe ser el cliente Web.")
    if not android_id:
        print("AVISO: falta GOOGLE_ANDROID_CLIENT_ID (opcional, pero recomendado).")

    config = {
        "API_BASE_URL": env.get("API_BASE_URL", f"http://{host}:3000").rstrip("/"),
        "PUBLIC_WEB_URL": env.get(
            "PUBLIC_WEB_URL", f"http://{host}:4321/mapa"
        ).rstrip("/"),
        "GOOGLE_SERVER_CLIENT_ID": web_id,
        "GOOGLE_ANDROID_CLIENT_ID": android_id,
    }
    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(json.dumps(config, indent=2) + "\n")
    print(f"Configuración pública escrita en {OUT_FILE.relative_to(ROOT)}")
    print("No se copió GOOGLE_SECRET ni ninguna otra credencial.")


if __name__ == "__main__":
    main()
