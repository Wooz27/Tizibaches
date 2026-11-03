# Cloudflare Tunnel en el host

`cloudflared` corre como servicio del host y entra a nginx por loopback. El
puerto 8080 no se publica a Internet.

## Compose

El proxy queda publicado solo en localhost:

```yaml
proxy:
  ports:
    - "127.0.0.1:8080:80"
```

El backend y Astro no se publican; solo el proxy los alcanza.

## Configuración de cloudflared

En `/etc/cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /etc/cloudflared/<tunnel-id>.json

ingress:
  - hostname: tizibaches.casatos.online
    service: http://127.0.0.1:8080
  - service: http_status:404
```

Después:

```bash
sudo cloudflared tunnel route dns <tunnel-name> tizibaches.casatos.online
sudo systemctl enable --now cloudflared
sudo systemctl status cloudflared
```

Si usas el panel de Cloudflare Zero Trust, el servicio del hostname debe ser
`http://127.0.0.1:8080`.

## Cloudflare

- DNS: el hostname se enruta al túnel; no debe apuntar a una IP del servidor.
- SSL/TLS: **Full**, no Flexible.
- Activa **Always Use HTTPS**.
- Cloudflare debe enviar `X-Forwarded-Proto: https`; nginx lo conserva hacia
  Django. Si no llega, nginx usa `https` como valor interno.
- Protege `/admin/*` con Cloudflare Access si es posible.

## Variables

```dotenv
DOMAIN=tizibaches.casatos.online
HOST_PORT=8080
DJANGO_ALLOWED_HOSTS=tizibaches.casatos.online,backend,127.0.0.1
CSRF_TRUSTED_ORIGINS=https://tizibaches.casatos.online
CORS_ALLOWED_ORIGINS=https://tizibaches.casatos.online
WEB_URL=https://tizibaches.casatos.online
PUBLIC_API_URL=https://tizibaches.casatos.online
PUBLIC_APP_URL=https://tizibaches.casatos.online/app
DJANGO_TRUST_PROXY=1
DJANGO_SECURE_SSL_REDIRECT=1
```

`DJANGO_ALLOWED_HOSTS` no lleva `https://`, puerto ni slash.

## Prueba local

```bash
curl -I http://127.0.0.1:8080/
curl -I -H 'X-Forwarded-Proto: https' http://127.0.0.1:8080/api/health/
```

No abras `8080` en el firewall. Solo `cloudflared` debe consumirlo desde el host.
