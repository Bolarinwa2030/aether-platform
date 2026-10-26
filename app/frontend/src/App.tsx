import { useCallback, useEffect, useState } from "react";
import { api, Deployment, DriftRecord, Environment, Overview } from "./api";

const REFRESH_MS = 10_000;

function timeAgo(iso: string | null): string {
  if (!iso) return "never";
  const s = Math.max(0, Math.floor((Date.now() - new Date(iso).getTime()) / 1000));
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

function Badge({ value }: { value: string }) {
  return <span className={`badge badge-${value}`}>{value.replace("_", " ")}</span>;
}

function Stat({ label, value, tone }: { label: string; value: string | number; tone?: "bad" | "ok" }) {
  return (
    <div className={`stat ${tone ? `stat-${tone}` : ""}`}>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
    </div>
  );
}

export default function App() {
  const [overview, setOverview] = useState<Overview | null>(null);
  const [envs, setEnvs] = useState<Environment[]>([]);
  const [deps, setDeps] = useState<Deployment[]>([]);
  const [drift, setDrift] = useState<DriftRecord[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      const [o, e, d, dr] = await Promise.all([api.overview(), api.environments(), api.deployments(), api.drift()]);
      setOverview(o);
      setEnvs(e);
      setDeps(d);
      setDrift(dr);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to reach the API");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    const t = setInterval(load, REFRESH_MS);
    return () => clearInterval(t);
  }, [load]);

  const envName = (id: string) => envs.find((e) => e.id === id)?.name ?? id;

  return (
    <div className="shell">
      <header className="top">
        <div>
          <h1>Aether Platform</h1>
          <p className="muted">Git-driven infrastructure &amp; deployments</p>
        </div>
        <button className="btn" onClick={load}>Refresh</button>
      </header>

      {error && <div className="alert" role="alert">API unreachable: {error}</div>}
      {loading && !overview && <p className="muted">Loading…</p>}

      {overview && (
        <section className="stats">
          <Stat label="Environments" value={overview.environments} />
          <Stat label="Deployments" value={overview.deployments_total} />
          <Stat
            label="Success rate"
            value={`${Math.round(overview.success_rate * 100)}%`}
            tone={overview.success_rate < 0.9 ? "bad" : "ok"}
          />
          <Stat label="Failed" value={overview.deployments_failed} tone={overview.deployments_failed ? "bad" : undefined} />
          <Stat label="Drifted envs" value={overview.environments_drifted} tone={overview.environments_drifted ? "bad" : "ok"} />
        </section>
      )}

      <section>
        <h2>Environments</h2>
        <div className="cards">
          {envs.map((e) => (
            <article key={e.id} className="card">
              <div className="card-head">
                <h3>{e.name}</h3>
                <Badge value={e.drift} />
              </div>
              <dl>
                <dt>Cluster</dt><dd>{e.cluster}</dd>
                <dt>Region</dt><dd>{e.region}</dd>
                <dt>Last synced</dt><dd>{timeAgo(e.last_synced_at)}</dd>
              </dl>
            </article>
          ))}
        </div>
      </section>

      <section>
        <h2>Recent deployments</h2>
        {deps.length === 0 ? (
          <p className="muted">No deployments yet. POST one to <code>/api/deployments</code> from your pipeline.</p>
        ) : (
          <table>
            <thead>
              <tr><th>Service</th><th>Environment</th><th>Commit</th><th>Status</th><th>Started</th></tr>
            </thead>
            <tbody>
              {deps.slice(0, 20).map((d) => (
                <tr key={d.id}>
                  <td>{d.service}</td>
                  <td>{envName(d.environment_id)}</td>
                  <td><code>{d.git_sha.slice(0, 7)}</code></td>
                  <td><Badge value={d.status} /></td>
                  <td>{timeAgo(d.started_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section>
        <h2>Drift reports</h2>
        {drift.length === 0 ? (
          <p className="muted">No drift reports yet.</p>
        ) : (
          <table>
            <thead>
              <tr><th>Environment</th><th>Result</th><th>Resources changed</th><th>Summary</th><th>Detected</th></tr>
            </thead>
            <tbody>
              {drift.slice(0, 20).map((r) => (
                <tr key={r.id}>
                  <td>{envName(r.environment_id)}</td>
                  <td><Badge value={r.drifted ? "drifted" : "in_sync"} /></td>
                  <td>{r.resources_changed}</td>
                  <td>{r.summary || "—"}</td>
                  <td>{timeAgo(r.detected_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
