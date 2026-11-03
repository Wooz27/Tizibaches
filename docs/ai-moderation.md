# Moderación de fotos con IA

La verificación es opcional y asíncrona. Cada reporte conserva su estado interno;
el mapa público solo muestra baches con al menos un reporte no rechazado.

## Modelo elegido

**`gemini-3.1-flash-lite`** es el mejor costo-beneficio para clasificar una foto
de bache: entrada de imagen, salida estructurada, 1M de contexto y precio bajo.
Es un modelo estable de Gemini 3.1. No se eligió `gemini-2.5-flash-lite` porque
es legacy; `3.5-flash-lite` es una alternativa si una evaluación propia muestra
mejor precisión, pero cuesta más por token de salida.

Precios oficiales estándar (3 de noviembre de 2026, USD por 1M tokens):

| Modelo | Entrada texto/imagen/video | Salida | Nota |
|---|---:|---:|---|
| Gemini 3.1 Flash-Lite | $0.25 | $1.50 | Elegido |
| Gemini 3.5 Flash-Lite | $0.30 | $2.50 | Alternativa |
| Gemini 2.5 Flash-Lite | $0.10 | $0.40 | Legacy |
| Gemini 3.8 Flash | $0.75 | $3.75 | Más capacidad, más costo |

Fuente: [Gemini Developer API pricing](https://ai.google.dev/gemini-api/docs/pricing)
y [Gemini 3.1 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite).

### Estimación por reporte

La app reduce la foto a un máximo de 1024 px antes de enviarla. Una imagen
1024×768 usa aproximadamente 516 tokens de imagen; el prompt y la respuesta
corta suman otros ~200 tokens. En 3.1 Flash-Lite eso da aproximadamente:

- **~$0.0003 USD por reporte**
- **~$0.30 USD por 1,000 reportes**
- **~$3.00 USD por 10,000 reportes**

Es una estimación; el tamaño real de la foto y los tokens de pensamiento pueden
cambiarla. El nivel de pensamiento se fija en `minimal` para este clasificador.
Batch API ofrece 50% de descuento, pero no se usa en el flujo en vivo porque su
latencia no es compatible con una autoconfirmación inmediata.

## Flujo

1. El reporte se guarda como `pending`. El mapa lo muestra como **Pendiente de
   revisión** mientras se procesa; no se oculta.
2. El worker `verify_report_photos` toma un reporte pendiente y hace **una
   llamada por imagen**.
3. La respuesta estructurada se valida con Pydantic:
   - `is_pothole`
   - `confidence` (0–1)
   - `reason`
   - `severity` opcional
4. Resultado:
   - bache + confianza ≥ `AI_CONFIRM_THRESHOLD`: `confirmed`; el bache público
     pasa a **Reportado**.
   - no bache + confianza ≥ `AI_REJECT_THRESHOLD`: `rejected`.
   - duda o confianza baja: queda `pending` como **Pendiente de revisión** para
     revisión humana.
5. Si todos los reportes de un bache quedan rechazados, el bache deja de salir
   en `/api/potholes/` y en el GeoJSON. La última foto pública también ignora
   reportes rechazados.
6. El admin puede aprobar, rechazar o volver a mandar a la cola de IA.

Un error del proveedor no borra el reporte: queda pendiente con veredicto
`error` y el reporte sigue visible. El worker no bloquea la subida.

## Configuración

```dotenv
AI_VERIFICATION_ENABLED=1
GEMINI_API_KEY=...
# También se acepta GEMINIS_KEY por compatibilidad.
GEMINI_VISION_MODEL=gemini-3.1-flash-lite
AI_CONFIRM_THRESHOLD=0.85
AI_REJECT_THRESHOLD=0.90
AI_TIMEOUT_SECONDS=25
AI_MAX_OUTPUT_TOKENS=200
AI_THINKING_LEVEL=minimal
```

Con Docker Compose, el worker es un perfil opcional:

```bash
docker compose --profile ai up -d ai-worker
```

Sin Docker:

```bash
cd backend
python manage.py verify_report_photos --once
python manage.py verify_report_photos --loop --sleep 10
```

La key **solo** vive en el backend. No se incluye en Flutter ni en el frontend.

## Privacidad y operación

- Las fotos se envían a Google para su análisis. Hay que informarlo en la
  política de privacidad y obtener el consentimiento correspondiente.
- El nivel gratuito puede usar el contenido para mejorar productos de Google;
  para producción usar el nivel pago.
- No se envía el texto libre del ciudadano al modelo, solo la imagen reducida.
- El prompt instruye al modelo a ignorar texto o instrucciones dentro de la
  imagen.
- Los umbrales son deliberadamente conservadores. La IA no cambia el estado
  oficial del bache; solo modera la visibilidad del reporte.
