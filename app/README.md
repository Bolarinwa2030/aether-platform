# Aether Platform

Immutable, GitOps-driven platform dashboard. Two independently built and deployed services:

| Service  | Stack                    | Port | Image build context |
|----------|--------------------------|------|---------------------|
| backend  | Python 3.12, FastAPI     | 8000 | `./backend`         |
| frontend | React 18, Vite, nginx    | 8080 | `./frontend`        |

The frontend never talks to the backend by hard-coded URL. nginx proxies `/api/*` to `BACKEND_URL`,
which your Kubernetes manifest / Helm values set per environment.

## Run locally

```bash
# Option 1: both containers
docker compose up --build        # UI on http://localhost:8080, API docs on http://localhost:8000/docs

# Option 2: hot reload
cd backend  && pip install -r requirements.txt && uvicorn app.main:app --reload
cd frontend && npm install && npm run dev      # http://localhost:5173 (proxies /api to :8000)
```

## Backend contract (for your CI / GitOps controller)

| Method | Path                       | Purpose                                        | Auth |
|--------|----------------------------|------------------------------------------------|------|
| GET    | `/healthz`, `/readyz`      | Liveness / readiness probes                    | none |
| GET    | `/metrics`                 | Prometheus scrape endpoint                     | none |
| GET    | `/api/overview`            | Summary stats                                  | none |
| GET    | `/api/environments`        | Environments + drift state                     | none |
| GET/POST | `/api/deployments`       | List / record a rollout                        | POST: bearer token |
| PATCH  | `/api/deployments/{id}`    | Update status (`succeeded`, `failed`, ...)     | bearer token |
| GET/POST | `/api/drift`             | List / submit a drift report                   | POST: bearer token |

Set `AETHER_API_TOKEN` (from a Kubernetes Secret) to require `Authorization: Bearer <token>` on writes.

Example pipeline step:

```bash
curl -X POST "$AETHER_URL/api/deployments" \
  -H "Authorization: Bearer $AETHER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{"service":"orders-api","environment_id":"prod","image":"ghcr.io/org/orders-api:'$GIT_SHA'","git_sha":"'$GIT_SHA'"}'
```

Drift job example (after `terraform plan -detailed-exitcode`, exit code 2 = drift):

```bash
curl -X POST "$AETHER_URL/api/drift" -H "Authorization: Bearer $AETHER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"environment_id":"prod","drifted":true,"resources_changed":3,"summary":"SG rule changed in console"}'
```

## Config (env vars, backend)

`AETHER_ENVIRONMENT`, `AETHER_LOG_LEVEL`, `AETHER_CORS_ORIGINS`, `AETHER_API_TOKEN`.
Frontend: `BACKEND_URL` (runtime).

## Notes / next steps

- State is **in memory** (`backend/app/store.py`), so it resets on restart and isn't shared across replicas.
  Swap in a database-backed store (the methods map 1:1 to repository calls) once your Terraform provisions one.
- Containers run as non-root and expose health endpoints, so they fit restrictive pod security policies.
- Run backend tests: `cd backend && pytest`.
