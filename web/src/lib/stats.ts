import type { PotholeFeature, PotholeStatus } from "./types";

const OPEN_STATUSES: PotholeStatus[] = [
  "pending",
  "reported",
  "verified",
  "scheduled",
  "in_progress",
];

export type Stats = {
  total: number;
  reports: number;
  open: number;
  fixed: number;
  lastReport: string | null;
};

export function buildStats(features: PotholeFeature[]): Stats {
  const reports = features.reduce((total, feature) => total + feature.properties.report_count, 0);
  const open = features.filter((feature) =>
    OPEN_STATUSES.includes(feature.properties.status),
  ).length;
  const fixed = features.filter((feature) => feature.properties.status === "fixed").length;
  const lastReport = features.reduce<string | null>((latest, feature) => {
    const value = feature.properties.last_reported_at;
    return !latest || value > latest ? value : latest;
  }, null);

  return { total: features.length, reports, open, fixed, lastReport };
}

export function statusCounts(features: PotholeFeature[]): Record<string, number> {
  return features.reduce<Record<string, number>>((counts, feature) => {
    const status = feature.properties.status;
    counts[status] = (counts[status] ?? 0) + 1;
    return counts;
  }, {});
}

export function recentFeatures(features: PotholeFeature[], limit = 3): PotholeFeature[] {
  return [...features]
    .sort((a, b) =>
      b.properties.last_reported_at.localeCompare(a.properties.last_reported_at),
    )
    .slice(0, limit);
}

export function featuredFeature(features: PotholeFeature[]): PotholeFeature | null {
  return (
    features.find(
      (feature) =>
        feature.properties.status === "in_progress" && Boolean(feature.properties.photo_url),
    ) ??
    features.find((feature) => Boolean(feature.properties.photo_url)) ??
    features[0] ??
    null
  );
}
