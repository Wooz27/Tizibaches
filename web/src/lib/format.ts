import { SEVERITY_LABELS, STATUS_META } from "./constants";
import type { PotholeStatus } from "./types";

const dateFormatter = new Intl.DateTimeFormat("es-MX", {
  day: "2-digit",
  month: "short",
  year: "numeric",
  timeZone: "America/Merida",
});

const numberFormatter = new Intl.NumberFormat("es-MX");

export function formatDate(value: string | null | undefined): string {
  if (!value) return "Sin fecha";
  return dateFormatter.format(new Date(value));
}

export function formatNumber(value: number): string {
  return numberFormatter.format(value);
}

export function statusLabel(status: string): string {
  return STATUS_META[status as PotholeStatus]?.label ?? status;
}

export function statusTone(status: string): string {
  return STATUS_META[status as PotholeStatus]?.tone ?? "tone-reported";
}

export function severityLabel(severity: number): string {
  return SEVERITY_LABELS[severity] ?? "Sin clasificar";
}

export function coordinatesLabel(longitude: number, latitude: number): string {
  return `${latitude.toFixed(5)}° N · ${Math.abs(longitude).toFixed(5)}° O`;
}
