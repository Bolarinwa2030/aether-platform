export type DeployStatus = "pending" | "in_progress" | "succeeded" | "failed" | "rolled_back";
export type DriftStatus = "in_sync" | "drifted" | "unknown";

export interface Environment {
  id: string;
  name: string;
  region: string;
  cluster: string;
  drift: DriftStatus;
  last_synced_at: string | null;
}

export interface Deployment {
  id: string;
  service: string;
  environment_id: string;
  image: string;
  git_sha: string;
  triggered_by: string;
  status: DeployStatus;
  started_at: string;
  finished_at: string | null;
}

export interface DriftRecord {
  id: string;
  environment_id: string;
  drifted: boolean;
  resources_changed: number;
  summary: string;
  detected_at: string;
}

export interface Overview {
  environments: number;
  deployments_total: number;
  deployments_failed: number;
  environments_drifted: number;
  success_rate: number;
}

// Same-origin by default: nginx (prod) and the Vite proxy (dev) forward /api to the backend.
// Set VITE_API_BASE at build time only if the API lives on a different origin.
const BASE = (import.meta.env.VITE_API_BASE as string | undefined) ?? "";

async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`);
  if (!res.ok) throw new Error(`${path} failed: ${res.status}`);
  return res.json() as Promise<T>;
}

export const api = {
  overview: () => get<Overview>("/api/overview"),
  environments: () => get<Environment[]>("/api/environments"),
  deployments: () => get<Deployment[]>("/api/deployments"),
  drift: () => get<DriftRecord[]>("/api/drift"),
};
