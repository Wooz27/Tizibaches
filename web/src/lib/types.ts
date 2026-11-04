export type PotholeStatus =
  | "pending"
  | "reported"
  | "verified"
  | "scheduled"
  | "in_progress"
  | "fixed"
  | "rejected";

export type PotholeProperties = {
  name: string;
  status: PotholeStatus;
  severity: number;
  report_count: number;
  note: string;
  address: string;
  first_reported_at: string;
  last_reported_at: string;
  fixed_at: string | null;
  photo_url: string | null;
};

export type PotholeFeature = {
  id: number;
  type: "Feature";
  geometry: {
    type: "Point";
    coordinates: [number, number];
  };
  properties: PotholeProperties;
};

export type PotholeCollection = {
  type: "FeatureCollection";
  features: PotholeFeature[];
};

export type StatusFilter = "all" | PotholeStatus;
export type SortKey = "recent" | "severity" | "reports";
