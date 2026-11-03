import "maplibre-gl/dist/maplibre-gl.css";
import { ArrowUpRight, MapPin } from "lucide-react";
import type { Map as MapLibreMap } from "maplibre-gl";
import { useEffect, useRef, useState } from "react";

import { formatNumber, statusLabel } from "@/lib/format";
import type { PotholeFeature } from "@/lib/types";
import { cn } from "@/lib/utils";

const MAP_STYLE =
  import.meta.env.PUBLIC_MAP_STYLE_URL || "https://tiles.openfreemap.org/styles/positron";
const CITY_CENTER: [number, number] = [-88.1519, 21.143];

type MiniMapProps = {
  features: PotholeFeature[];
  featured?: PotholeFeature | null;
  bare?: boolean;
  styleUrl?: string;
};

export default function MiniMap({
  features,
  featured = null,
  bare = false,
  styleUrl = MAP_STYLE,
}: MiniMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    let observer: ResizeObserver | null = null;

    async function start() {
      try {
        const maplibregl = await import("maplibre-gl");
        if (cancelled || !containerRef.current) return;

        const map = new maplibregl.Map({
          container: containerRef.current,
          style: styleUrl,
          center: CITY_CENTER,
          zoom: 12.7,
          interactive: false,
          attributionControl: false,
        });
        mapRef.current = map;

        map.on("load", () => {
          if (cancelled) return;

          if (features.length > 0) {
            const longitudes = features.map((feature) => feature.geometry.coordinates[0]);
            const latitudes = features.map((feature) => feature.geometry.coordinates[1]);
            map.fitBounds(
              [
                [Math.min(...longitudes), Math.min(...latitudes)],
                [Math.max(...longitudes), Math.max(...latitudes)],
              ],
              { padding: 32, maxZoom: 13.7, duration: 0 },
            );
          }

          features.forEach((feature) => {
            const element = document.createElement("span");
            element.className = "pothole-marker";
            element.dataset.status = feature.properties.status;
            element.dataset.severity = String(feature.properties.severity);
            element.style.width = "9px";
            element.style.height = "9px";
            element.style.borderWidth = "1.5px";
            element.style.pointerEvents = "none";
            element.setAttribute("aria-hidden", "true");

            new maplibregl.Marker({ element, anchor: "center" })
              .setLngLat(feature.geometry.coordinates)
              .addTo(map);
          });

          setReady(true);
        });

        if (typeof ResizeObserver !== "undefined") {
          observer = new ResizeObserver(() => map.resize());
          observer.observe(containerRef.current);
        }
      } catch {
        // La vista previa conserva su fondo si el mapa no puede iniciar.
      }
    }

    start();

    return () => {
      cancelled = true;
      observer?.disconnect();
      mapRef.current?.remove();
      mapRef.current = null;
    };
    // La vista previa se inicializa una vez con los datos del servidor.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (bare) {
    return (
      <div className="relative h-full w-full bg-paper-deep">
        <div
          ref={containerRef}
          className={cn(
            "pothole-map pointer-events-none h-full w-full transition-opacity duration-700",
            ready ? "opacity-100" : "opacity-0",
          )}
          aria-hidden="true"
        />
      </div>
    );
  }

  return (
    <div className="relative h-full w-full bg-paper-deep">
      <div
        ref={containerRef}
        className={cn(
          "pothole-map h-full w-full transition-opacity duration-700",
          ready ? "opacity-100" : "opacity-0",
        )}
        aria-hidden="true"
      />

      <div className="pointer-events-none absolute inset-0 bg-ink/15" />

      <div className="pointer-events-none absolute left-4 top-4 flex items-center gap-2 border border-paper/35 bg-ink/45 px-2.5 py-1.5 backdrop-blur-sm">
        <MapPin className="size-3 text-maize" aria-hidden="true" />
        <span className="font-mono text-[8px] uppercase tracking-[0.16em] text-paper/85">
          Mapa abierto / Tizimín
        </span>
      </div>

      <div className="pointer-events-none absolute right-3 top-3 border border-paper/30 bg-ink/75 px-2.5 py-1.5 text-right backdrop-blur-sm">
        <p className="font-heading text-2xl leading-none tracking-[-0.06em] text-paper">
          {formatNumber(features.length)}
        </p>
        <p className="mt-1 font-mono text-[8px] uppercase tracking-[0.14em] text-paper/60">
          expedientes
        </p>
      </div>

      <div className="pointer-events-none absolute bottom-0 left-0 right-0 border-t border-paper/15 bg-ink/92 p-3 backdrop-blur-sm">
        {featured && (
          <div className="flex items-center gap-3">
            {featured.properties.photo_url && (
              <img
                src={featured.properties.photo_url}
                alt=""
                className="size-12 shrink-0 border border-paper/30 object-cover"
                loading="lazy"
                decoding="async"
              />
            )}
            <div className="min-w-0 flex-1">
              <p className="font-mono text-[8px] uppercase tracking-[0.16em] text-paper/55">
                Último reporte: {statusLabel(featured.properties.status)}
              </p>
              <p className="mt-1 line-clamp-2 text-[11px] font-medium leading-4 text-paper">
                {featured.properties.address}
              </p>
            </div>
          </div>
        )}

        <div className="mt-3 flex items-center justify-between border-t border-paper/15 pt-2">
          <span className="font-mono text-[8px] uppercase tracking-[0.14em] text-paper/55">
            © OpenStreetMap y OpenFreeMap
          </span>
          <span className="inline-flex items-center gap-1 border border-paper/30 px-2 py-1 font-mono text-[8px] uppercase tracking-[0.12em] text-paper/85">
            Abrir mapa
            <ArrowUpRight className="size-3" aria-hidden="true" />
          </span>
        </div>
      </div>

      <a
        href="/mapa"
        className="absolute inset-0 z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-maize"
        aria-label="Abrir el mapa completo de baches de Tizimín"
      >
        <span className="sr-only">Abrir el mapa completo</span>
      </a>
    </div>
  );
}
