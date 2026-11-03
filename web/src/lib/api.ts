import type { PotholeCollection, PotholeFeature } from "./types";

const apiBaseUrl = (import.meta.env.API_URL ?? "http://127.0.0.1:3000").replace(/\/$/, "");
const publicApiUrl = (import.meta.env.PUBLIC_API_URL ?? apiBaseUrl).replace(/\/$/, "");

export { apiBaseUrl, publicApiUrl };

type PotholesResult = {
  features: PotholeFeature[];
  error: string | null;
};

function normalizePhotoUrl(url: string | null): string | null {
  if (!url) return null;
  try {
    const parsed = new URL(url);
    return `${publicApiUrl}${parsed.pathname}${parsed.search}`;
  } catch {
    return url;
  }
}

export async function getPotholes(): Promise<PotholesResult> {
  try {
    const response = await fetch(`${apiBaseUrl}/api/potholes/geojson/`, {
      headers: { Accept: "application/json" },
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });

    if (!response.ok) {
      return {
        features: [],
        error: `La API respondió con el código ${response.status}.`,
      };
    }

    const data = (await response.json()) as PotholeCollection;
    const features = data.features.map((feature) => ({
      ...feature,
      properties: {
        ...feature.properties,
        photo_url: normalizePhotoUrl(feature.properties.photo_url),
      },
    }));

    return { features, error: null };
  } catch (error) {
    return {
      features: [],
      error:
        error instanceof Error
          ? `No se pudo conectar con la API: ${error.message}`
          : "No se pudo conectar con la API.",
    };
  }
}
