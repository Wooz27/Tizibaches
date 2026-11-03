import type { PotholeStatus, SortKey } from "./types";

export const STATUS_ORDER: PotholeStatus[] = [
  "pending",
  "reported",
  "in_progress",
  "fixed",
];

export const STATUS_META: Record<
  PotholeStatus,
  { label: string; short: string; tone: string }
> = {
  pending: {
    label: "Pendiente de revisión",
    short: "Pendiente",
    tone: "tone-pending",
  },
  reported: { label: "Reportado", short: "Reportado", tone: "tone-reported" },
  verified: { label: "Verificado", short: "Verificado", tone: "tone-verified" },
  scheduled: { label: "Programado", short: "Programado", tone: "tone-scheduled" },
  in_progress: { label: "En obra", short: "En obra", tone: "tone-in_progress" },
  fixed: { label: "Reparado", short: "Reparado", tone: "tone-fixed" },
  rejected: { label: "Rechazado", short: "Rechazado", tone: "tone-rejected" },
};

export const SEVERITY_LABELS: Record<number, string> = {
  1: "Leve",
  2: "Moderado",
  3: "Grave",
  4: "Muy grave",
};

export const SORT_OPTIONS: { value: SortKey; label: string }[] = [
  { value: "recent", label: "Más recientes" },
  { value: "severity", label: "Mayor severidad" },
  { value: "reports", label: "Más reportes" },
];
