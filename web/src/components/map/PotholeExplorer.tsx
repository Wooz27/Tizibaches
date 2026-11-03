import {
  AlertCircle,
  ArrowUpRight,
  CalendarDays,
  Camera,
  LocateFixed,
  MapPin,
  Search,
  X,
} from "lucide-react";
import type { Map as MapLibreMap, Marker } from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { useEffect, useMemo, useRef, useState } from "react";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { SORT_OPTIONS, STATUS_META, STATUS_ORDER } from "@/lib/constants";
import {
  coordinatesLabel,
  formatDate,
  formatNumber,
  severityLabel,
  statusLabel,
  statusTone,
} from "@/lib/format";
import type { PotholeFeature, PotholeStatus, SortKey, StatusFilter } from "@/lib/types";
import { cn } from "@/lib/utils";

const MAP_STYLE =
  import.meta.env.PUBLIC_MAP_STYLE_URL || "https://tiles.openfreemap.org/styles/positron";
const CITY_CENTER: [number, number] = [-88.1519, 21.143];
const APP_URL = import.meta.env.PUBLIC_APP_URL || "/app";

type ExplorerProps = {
  features: PotholeFeature[];
  error: string | null;
  full?: boolean;
};

type TabValue = "list" | "detail";

function fitToFeatures(map: MapLibreMap, features: PotholeFeature[], duration = 0) {
  if (features.length === 0) {
    map.flyTo({ center: CITY_CENTER, zoom: 13.2, duration });
    return;
  }

  const longitudes = features.map((feature) => feature.geometry.coordinates[0]);
  const latitudes = features.map((feature) => feature.geometry.coordinates[1]);
  const bounds: [[number, number], [number, number]] = [
    [Math.min(...longitudes), Math.min(...latitudes)],
    [Math.max(...longitudes), Math.max(...latitudes)],
  ];

  const maxZoom = map.getContainer().clientWidth < 600 ? 13.6 : 14.5;
  map.fitBounds(bounds, { padding: 56, maxZoom, duration });
}

function SeverityMeter({ severity }: { severity: number }) {
  return (
    <span
      className="severity-meter"
      role="img"
      aria-label={`Severidad ${severityLabel(severity)}, ${severity} de 4`}
    >
      {[1, 2, 3, 4].map((level) => (
        <span key={level} data-filled={level <= severity} />
      ))}
    </span>
  );
}

function StatusBadge({ status, className }: { status: PotholeStatus; className?: string }) {
  return (
    <Badge
      variant="outline"
      className={cn(
        "status-badge rounded-none border px-2.5 py-1 font-mono text-[9px] uppercase tracking-[0.12em]",
        statusTone(status),
        className,
      )}
    >
      <span className="status-dot mr-2 size-1.5 rounded-full" />
      {statusLabel(status)}
    </Badge>
  );
}

function PotholeRow({
  feature,
  active,
  onSelect,
}: {
  feature: PotholeFeature;
  active: boolean;
  onSelect: (feature: PotholeFeature) => void;
}) {
  const pothole = feature.properties;

  return (
    <button
      type="button"
      onClick={() => onSelect(feature)}
      className={cn(
        "group flex w-full items-start gap-3 border-b border-border/70 px-2 py-3 text-left transition-colors last:border-0 hover:bg-muted/60",
        active && "bg-accent/60",
      )}
      aria-pressed={active}
    >
      <span className="relative size-14 shrink-0 overflow-hidden border border-border bg-muted">
        {pothole.photo_url ? (
          <img
            src={pothole.photo_url}
            alt=""
            className="h-full w-full object-cover"
            loading="lazy"
            decoding="async"
          />
        ) : (
          <span className="grid h-full place-items-center font-mono text-[8px] uppercase text-muted-foreground">
            Sin foto
          </span>
        )}
      </span>
      <span className="min-w-0 flex-1">
        <span className="flex items-start justify-between gap-2">
          <span className="line-clamp-2 text-[12px] font-medium leading-4 text-ink">
            {pothole.address}
          </span>
          <span
            className={cn("status-dot mt-1 size-2 shrink-0 rounded-full", statusTone(pothole.status))}
            aria-hidden="true"
          />
        </span>
        <span className="mt-1.5 flex flex-wrap items-center gap-x-1.5 gap-y-1 font-mono text-[9px] uppercase tracking-[0.08em] text-muted-foreground">
          <span>{statusLabel(pothole.status)}</span>
          <span>{formatNumber(pothole.report_count)} reportes</span>
          <span>{formatDate(pothole.last_reported_at)}</span>
        </span>
      </span>
    </button>
  );
}

function PotholeDetail({ feature }: { feature: PotholeFeature }) {
  const pothole = feature.properties;
  const [longitude, latitude] = feature.geometry.coordinates;
  const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2">
        <p className="font-mono text-[9px] uppercase tracking-[0.16em] text-muted-foreground">
          Expediente #{feature.id}
        </p>
        <StatusBadge status={pothole.status} />
      </div>

      {pothole.photo_url ? (
        <Dialog>
          <DialogTrigger asChild>
            <button
              type="button"
              className="group relative block w-full overflow-hidden border border-border bg-muted"
              aria-label={`Ampliar foto del bache en ${pothole.address}`}
            >
              <img
                src={pothole.photo_url}
                alt={`Bache en ${pothole.address}`}
                className="aspect-[4/3] w-full object-cover transition-transform duration-300 group-hover:scale-[1.02]"
                loading="lazy"
                decoding="async"
              />
              <span className="absolute bottom-2 right-2 inline-flex items-center gap-1.5 border border-border bg-background/92 px-2 py-1 font-mono text-[8px] uppercase tracking-[0.1em] text-ink backdrop-blur">
                <Camera className="size-3" aria-hidden="true" />
                Ampliar foto
              </span>
            </button>
          </DialogTrigger>
          <DialogContent className="max-w-3xl border-border bg-card p-2 sm:max-w-3xl">
            <DialogTitle className="sr-only">Foto del bache en {pothole.address}</DialogTitle>
            <img
              src={pothole.photo_url}
              alt={`Bache en ${pothole.address}`}
              className="max-h-[75svh] w-full object-contain"
              loading="lazy"
              decoding="async"
            />
            <DialogDescription className="px-2 pb-2 text-xs text-muted-foreground">
              {pothole.address}
            </DialogDescription>
          </DialogContent>
        </Dialog>
      ) : (
        <div className="grid aspect-[4/3] place-items-center border border-border bg-muted font-mono text-[9px] uppercase text-muted-foreground">
          Sin foto disponible
        </div>
      )}

      <div>
        <h3 className="font-heading text-xl leading-tight tracking-[-0.03em]">{pothole.address}</h3>
        <div className="mt-2 flex flex-wrap items-center gap-2 font-mono text-[9px] uppercase tracking-[0.1em] text-muted-foreground">
          <SeverityMeter severity={pothole.severity} />
          <span>{severityLabel(pothole.severity)}</span>
          <span>{formatNumber(pothole.report_count)} reportes</span>
        </div>
      </div>

      <Separator />

      <dl className="grid grid-cols-2 gap-x-3 gap-y-4 text-xs">
        <div>
          <dt className="font-mono text-[8px] uppercase tracking-[0.14em] text-muted-foreground">
            Último reporte
          </dt>
          <dd className="mt-1 inline-flex items-center gap-1.5 text-ink">
            <CalendarDays className="size-3 text-muted-foreground" aria-hidden="true" />
            {formatDate(pothole.last_reported_at)}
          </dd>
        </div>
        <div>
          <dt className="font-mono text-[8px] uppercase tracking-[0.14em] text-muted-foreground">
            Primer reporte
          </dt>
          <dd className="mt-1 text-ink">{formatDate(pothole.first_reported_at)}</dd>
        </div>
        <div>
          <dt className="font-mono text-[8px] uppercase tracking-[0.14em] text-muted-foreground">
            Coordenadas
          </dt>
          <dd className="mt-1 font-mono text-[10px] leading-4 text-ink">
            {coordinatesLabel(longitude, latitude)}
          </dd>
        </div>
        <div>
          <dt className="font-mono text-[8px] uppercase tracking-[0.14em] text-muted-foreground">
            Cierre
          </dt>
          <dd className="mt-1 text-ink">
            {pothole.fixed_at ? formatDate(pothole.fixed_at) : "En seguimiento"}
          </dd>
        </div>
      </dl>

      <Separator />

      <div className="flex flex-col gap-2">
        <Button
          asChild
          variant="outline"
          className="h-9 justify-between font-mono text-[9px] uppercase tracking-[0.1em]"
        >
          <a href={mapsUrl} target="_blank" rel="noreferrer">
            Abrir en Google Maps
            <ArrowUpRight className="size-3.5" />
          </a>
        </Button>
        <Button asChild className="h-9 justify-between font-mono text-[9px] uppercase tracking-[0.1em]">
          <a href={APP_URL}>
            Reportar de nuevo
            <ArrowUpRight className="size-3.5" />
          </a>
        </Button>
      </div>
    </div>
  );
}

export default function PotholeExplorer({ features, error, full = false }: ExplorerProps) {
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [query, setQuery] = useState("");
  const [sortBy, setSortBy] = useState<SortKey>("recent");
  const [selectedId, setSelectedId] = useState<number | null>(
    features[0]?.id ?? null,
  );
  const [tab, setTab] = useState<TabValue>("list");
  const [mapReady, setMapReady] = useState(false);
  const [mapError, setMapError] = useState<string | null>(null);

  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const maplibreRef = useRef<typeof import("maplibre-gl") | null>(null);
  const markersRef = useRef<Marker[]>([]);
  const markerElementsRef = useRef(new Map<number, HTMLButtonElement>());
  const selectedIdRef = useRef<number | null>(selectedId);

  const counts = useMemo(() => {
    return features.reduce<Record<string, number>>((result, feature) => {
      const status = feature.properties.status;
      result[status] = (result[status] ?? 0) + 1;
      return result;
    }, {});
  }, [features]);

  const visibleFeatures = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();
    const filtered = features.filter((feature) => {
      const matchesStatus =
        statusFilter === "all" || feature.properties.status === statusFilter;
      const searchable = [
        feature.properties.address,
        feature.id,
        statusLabel(feature.properties.status),
      ]
        .join(" ")
        .toLowerCase();
      return matchesStatus && (!normalizedQuery || searchable.includes(normalizedQuery));
    });

    return [...filtered].sort((a, b) => {
      if (sortBy === "severity") return b.properties.severity - a.properties.severity;
      if (sortBy === "reports") return b.properties.report_count - a.properties.report_count;
      return b.properties.last_reported_at.localeCompare(a.properties.last_reported_at);
    });
  }, [features, query, sortBy, statusFilter]);

  const selectedFeature =
    features.find((feature) => feature.id === selectedId) ?? null;

  useEffect(() => {
    selectedIdRef.current = selectedId;
  }, [selectedId]);

  useEffect(() => {
    let cancelled = false;
    let observer: ResizeObserver | null = null;

    async function startMap() {
      try {
        const maplibregl = await import("maplibre-gl");
        if (cancelled || !mapContainerRef.current) return;

        maplibreRef.current = maplibregl;
        const map = new maplibregl.Map({
          container: mapContainerRef.current,
          style: MAP_STYLE,
          center: CITY_CENTER,
          zoom: 13.2,
          attributionControl: { compact: true },
        });
        mapRef.current = map;

        map.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right");
        map.addControl(
          new maplibregl.ScaleControl({ unit: "metric", maxWidth: 110 }),
          "bottom-right",
        );

        map.on("load", () => {
          if (cancelled) return;
          setMapReady(true);
          fitToFeatures(map, features);
        });

        map.on("error", () => {
          if (!cancelled && !map.isStyleLoaded()) {
            setMapError("No se pudo cargar el mapa base. Revisa tu conexión.");
          }
        });

        if (typeof ResizeObserver !== "undefined") {
          observer = new ResizeObserver(() => map.resize());
          observer.observe(mapContainerRef.current);
        }
      } catch {
        if (!cancelled) setMapError("No se pudo iniciar el mapa interactivo.");
      }
    }

    startMap();

    return () => {
      cancelled = true;
      observer?.disconnect();
      markersRef.current.forEach((marker) => marker.remove());
      markersRef.current = [];
      markerElementsRef.current.clear();
      mapRef.current?.remove();
      mapRef.current = null;
      maplibreRef.current = null;
    };
    // El mapa se crea una vez; los cambios de filtros se manejan con marcadores.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    const maplibregl = maplibreRef.current;
    if (!map || !maplibregl || !mapReady) return;

    markersRef.current.forEach((marker) => marker.remove());
    markersRef.current = [];
    markerElementsRef.current.clear();

    visibleFeatures.forEach((feature) => {
      const pothole = feature.properties;
      const element = document.createElement("button");
      element.type = "button";
      element.className = "pothole-marker";
      element.dataset.status = pothole.status;
      element.dataset.severity = String(pothole.severity);
      element.dataset.active = String(selectedIdRef.current === feature.id);
      element.setAttribute(
        "aria-label",
        `${statusLabel(pothole.status)} en ${pothole.address}. Abrir ficha.`,
      );
      element.addEventListener("click", (event) => {
        event.stopPropagation();
        setSelectedId(feature.id);
        setTab("detail");
        map.flyTo({
          center: feature.geometry.coordinates,
          zoom: Math.max(map.getZoom(), 15),
          duration: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 700,
        });
      });

      const marker = new maplibregl.Marker({ element, anchor: "center" })
        .setLngLat(feature.geometry.coordinates)
        .addTo(map);

      markersRef.current.push(marker);
      markerElementsRef.current.set(feature.id, element);
    });

    return () => {
      markersRef.current.forEach((marker) => marker.remove());
      markersRef.current = [];
      markerElementsRef.current.clear();
    };
  }, [mapReady, visibleFeatures]);

  useEffect(() => {
    markerElementsRef.current.forEach((element, id) => {
      element.dataset.active = String(id === selectedId);
    });
  }, [selectedId, visibleFeatures]);

  function selectFeature(feature: PotholeFeature) {
    setSelectedId(feature.id);
    setTab("detail");
    const map = mapRef.current;
    if (map) {
      map.flyTo({
        center: feature.geometry.coordinates,
        zoom: Math.max(map.getZoom(), 15),
        duration: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 700,
      });
    }
  }

  function centerOnResults() {
    const map = mapRef.current;
    if (!map) return;
    fitToFeatures(
      map,
      visibleFeatures,
      window.matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 550,
    );
  }

  function clearFilters() {
    setQuery("");
    setStatusFilter("all");
    setSortBy("recent");
  }

  const mapHeight = full
    ? "h-[calc(100svh-15rem)] min-h-[30rem]"
    : "h-[min(68svh,36rem)] lg:h-[clamp(36rem,70svh,54rem)]";
  const panelHeight = full
    ? "h-[calc(100svh-15rem)] min-h-[30rem]"
    : "h-[32rem] lg:h-[clamp(36rem,70svh,54rem)]";

  return (
    <div className="text-ink">
      {error && (
        <Alert variant="destructive" className="mb-4 rounded-none border-clay/35 bg-clay/5">
          <AlertCircle className="size-4" />
          <AlertTitle>No se pudo cargar el registro</AlertTitle>
          <AlertDescription>
            {error} El mapa puede seguir mostrando la ciudad; el listado necesita que la API esté
            disponible.
          </AlertDescription>
        </Alert>
      )}

      <div className="mb-4 flex min-w-0 flex-col gap-3 border border-border bg-card p-3 xl:flex-row xl:items-center">
        <div className="relative min-w-0 flex-1 xl:max-w-md">
          <Search
            className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            aria-hidden="true"
          />
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Buscar calle, colonia o folio…"
            aria-label="Buscar bache por dirección o folio"
            className="h-10 rounded-none bg-background pl-9 pr-9 text-sm"
          />
          {query && (
            <button
              type="button"
              onClick={() => setQuery("")}
              className="absolute right-2 top-1/2 grid size-7 -translate-y-1/2 place-items-center text-muted-foreground transition-colors hover:text-ink"
              aria-label="Limpiar búsqueda"
            >
              <X className="size-3.5" />
            </button>
          )}
        </div>

        <ToggleGroup
          type="single"
          value={statusFilter}
          onValueChange={(value) =>
            setStatusFilter((value || "all") as StatusFilter)
          }
          className="flex w-full min-w-0 max-w-full flex-wrap justify-start gap-1 xl:w-auto xl:flex-nowrap"
          aria-label="Filtrar por estado"
        >
          <ToggleGroupItem
            value="all"
            className="h-8 shrink-0 px-2.5 font-mono text-[9px] uppercase tracking-[0.1em]"
          >
            Todos
          </ToggleGroupItem>
          {STATUS_ORDER.map((status) => (
            <ToggleGroupItem
              key={status}
              value={status}
              className="h-8 shrink-0 px-2.5 font-mono text-[9px] uppercase tracking-[0.1em]"
            >
              {STATUS_META[status].short}
            </ToggleGroupItem>
          ))}
        </ToggleGroup>

        <div className="flex items-center gap-2 xl:ml-auto">
          <Select value={sortBy} onValueChange={(value) => setSortBy(value as SortKey)}>
            <SelectTrigger
              className="h-10 w-full rounded-none bg-background font-mono text-[10px] uppercase tracking-[0.08em] xl:w-44"
              aria-label="Ordenar baches"
            >
              <SelectValue placeholder="Ordenar" />
            </SelectTrigger>
            <SelectContent>
              {SORT_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {(query || statusFilter !== "all") && (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={clearFilters}
              className="h-10 shrink-0 px-2 font-mono text-[9px] uppercase tracking-[0.1em]"
            >
              Limpiar
            </Button>
          )}
        </div>
      </div>

      <div className="grid min-w-0 gap-4 lg:grid-cols-[minmax(0,1fr)_380px] xl:grid-cols-[minmax(0,1fr)_420px]">
        <div className={cn("relative overflow-hidden border border-border bg-muted", mapHeight)}>
          <div ref={mapContainerRef} className="pothole-map h-full w-full" />

          <div className="pointer-events-none absolute left-3 top-3 z-10 flex flex-wrap items-center gap-2">
            <div className="pointer-events-auto flex items-center gap-2 border border-border bg-background/92 px-3 py-2 backdrop-blur">
              <MapPin className="size-3.5 text-clay" aria-hidden="true" />
              <span className="font-mono text-[9px] uppercase tracking-[0.14em] text-ink">
                Tizimín, Yucatán
              </span>
              <span className="h-3 w-px bg-border" aria-hidden="true" />
              <span className="font-mono text-[9px] uppercase tracking-[0.12em] text-muted-foreground">
                {formatNumber(visibleFeatures.length)} visibles
              </span>
            </div>
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              onClick={centerOnResults}
              className="pointer-events-auto rounded-none bg-background/92"
              aria-label="Centrar el mapa en los resultados"
            >
              <LocateFixed className="size-4" />
            </Button>
          </div>

          <div className="pointer-events-none absolute bottom-3 left-3 z-10 hidden max-w-[17rem] border border-border bg-background/92 p-3 backdrop-blur sm:block">
            <p className="font-mono text-[8px] uppercase tracking-[0.16em] text-muted-foreground">
              Estados en el mapa
            </p>
            <ul className="mt-2 grid grid-cols-2 gap-x-3 gap-y-1.5">
              {STATUS_ORDER.map((status) => (
                <li
                  key={status}
                  className="flex items-center gap-1.5 font-mono text-[8px] uppercase tracking-[0.06em] text-ink-soft"
                >
                  <span
                    className={cn(
                      "status-dot size-1.5 rounded-full",
                      STATUS_META[status].tone,
                    )}
                  />
                  <span className="min-w-0 flex-1 truncate">{STATUS_META[status].label}</span>
                  <span className="text-muted-foreground">{counts[status] ?? 0}</span>
                </li>
              ))}
            </ul>
          </div>

          {!mapReady && !mapError && (
            <div className="absolute inset-0 z-20 grid place-items-center bg-background/45 backdrop-blur-[1px]">
              <div className="w-56 space-y-2 border border-border bg-card p-4">
                <Skeleton className="h-3 w-28" />
                <Skeleton className="h-16 w-full" />
                <p className="font-mono text-[8px] uppercase tracking-[0.14em] text-muted-foreground">
                  Cargando mapa…
                </p>
              </div>
            </div>
          )}

          {mapError && (
            <div className="absolute inset-0 z-20 grid place-items-center bg-background/75 p-4 backdrop-blur-sm">
              <Alert variant="destructive" className="max-w-sm rounded-none bg-card">
                <AlertCircle className="size-4" />
                <AlertTitle>Mapa no disponible</AlertTitle>
                <AlertDescription>{mapError}</AlertDescription>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => window.location.reload()}
                  className="mt-3 w-fit"
                >
                  Reintentar
                </Button>
              </Alert>
            </div>
          )}
        </div>

        <aside
          className={cn(
            "flex min-h-0 flex-col border border-border bg-card",
            panelHeight,
          )}
        >
          <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-3">
            <div>
              <p className="font-mono text-[8px] uppercase tracking-[0.16em] text-muted-foreground">
                Expedientes
              </p>
              <p className="mt-1 font-heading text-lg leading-none tracking-[-0.03em]">
                {formatNumber(visibleFeatures.length)} baches
              </p>
            </div>
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              onClick={centerOnResults}
              className="rounded-none"
              aria-label="Centrar mapa en los baches visibles"
            >
              <LocateFixed className="size-4" />
            </Button>
          </div>

          <Tabs
            value={tab}
            onValueChange={(value) => setTab(value as TabValue)}
            className="flex min-h-0 flex-1 flex-col gap-0"
          >
            <div className="border-b border-border px-3 py-2">
              <TabsList className="grid w-full grid-cols-2 bg-muted">
                <TabsTrigger
                  value="list"
                  className="font-mono text-[9px] uppercase tracking-[0.12em]"
                >
                  Lista
                </TabsTrigger>
                <TabsTrigger
                  value="detail"
                  className="font-mono text-[9px] uppercase tracking-[0.12em]"
                >
                  Ficha
                </TabsTrigger>
              </TabsList>
            </div>

            <TabsContent value="list" className="min-h-0 flex-1 overflow-hidden">
              <ScrollArea className="h-full">
                <div className="p-2">
                  {visibleFeatures.length > 0 ? (
                    visibleFeatures.map((feature) => (
                      <PotholeRow
                        key={feature.id}
                        feature={feature}
                        active={feature.id === selectedId}
                        onSelect={selectFeature}
                      />
                    ))
                  ) : (
                    <div className="px-4 py-10 text-center">
                      <p className="font-heading text-xl leading-tight">No hay baches con esos filtros.</p>
                      <p className="mt-2 text-xs leading-5 text-muted-foreground">
                        Prueba con otro estado o limpia la búsqueda para ver todo el registro.
                      </p>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={clearFilters}
                        className="mt-4"
                      >
                        Limpiar filtros
                      </Button>
                    </div>
                  )}
                </div>
              </ScrollArea>
            </TabsContent>

            <TabsContent value="detail" className="min-h-0 flex-1 overflow-hidden">
              <ScrollArea className="h-full">
                <div className="p-4">
                  {selectedFeature ? (
                    <PotholeDetail feature={selectedFeature} />
                  ) : (
                    <div className="py-10 text-center">
                      <p className="font-heading text-xl leading-tight">Elige un bache del mapa.</p>
                      <p className="mt-2 text-xs leading-5 text-muted-foreground">
                        Toca un punto o una fila de la lista para abrir su expediente.
                      </p>
                    </div>
                  )}
                </div>
              </ScrollArea>
            </TabsContent>
          </Tabs>
        </aside>
      </div>
    </div>
  );
}
