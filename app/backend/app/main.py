import logging
import secrets
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, get_settings
from .metrics import DEPLOYMENTS, DRIFTED_ENVS, install_metrics
from .models import (
    Deployment,
    DeploymentCreate,
    DeploymentStatusUpdate,
    DeployStatus,
    DriftRecord,
    DriftReport,
    DriftStatus,
    Environment,
    Overview,
)
from .store import store

settings = get_settings()
logging.basicConfig(level=settings.log_level, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("aether")

app = FastAPI(title="Aether Platform API", version=settings.version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_methods=["*"],
    allow_headers=["*"],
)
install_metrics(app)


def require_token(
    authorization: Optional[str] = Header(default=None),
    cfg: Settings = Depends(get_settings),
) -> None:
    """Protects write endpoints when AETHER_API_TOKEN is set (CI/GitOps callers
    send `Authorization: Bearer <token>`). If no token is configured (local dev),
    writes are open."""
    if not cfg.api_token:
        return
    expected = f"Bearer {cfg.api_token}"
    if not authorization or not secrets.compare_digest(authorization, expected):
        raise HTTPException(status_code=401, detail="Invalid or missing token")


# ---------- Health (wire these to k8s liveness/readiness probes) ----------
@app.get("/healthz", tags=["health"])
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/readyz", tags=["health"])
def readyz() -> dict:
    return {"status": "ready", "version": settings.version, "environment": settings.environment}


# ---------- API ----------
@app.get("/api/overview", response_model=Overview, tags=["overview"])
def overview() -> Overview:
    deps = store.list_deployments()
    finished = [d for d in deps if d.status in (DeployStatus.succeeded, DeployStatus.failed, DeployStatus.rolled_back)]
    ok = [d for d in finished if d.status == DeployStatus.succeeded]
    envs = store.list_environments()
    return Overview(
        environments=len(envs),
        deployments_total=len(deps),
        deployments_failed=len([d for d in deps if d.status == DeployStatus.failed]),
        environments_drifted=len([e for e in envs if e.drift == DriftStatus.drifted]),
        success_rate=round(len(ok) / len(finished), 3) if finished else 1.0,
    )


@app.get("/api/environments", response_model=list[Environment], tags=["environments"])
def list_environments() -> list[Environment]:
    return store.list_environments()


@app.get("/api/deployments", response_model=list[Deployment], tags=["deployments"])
def list_deployments(
    environment_id: Optional[str] = Query(default=None),
    service: Optional[str] = Query(default=None),
) -> list[Deployment]:
    return store.list_deployments(environment_id, service)


@app.post("/api/deployments", response_model=Deployment, status_code=201, tags=["deployments"],
          dependencies=[Depends(require_token)])
def create_deployment(payload: DeploymentCreate) -> Deployment:
    if store.get_environment(payload.environment_id) is None:
        raise HTTPException(status_code=404, detail="Unknown environment")
    dep = store.create_deployment(payload)
    log.info("deployment created id=%s service=%s env=%s sha=%s", dep.id, dep.service, dep.environment_id, dep.git_sha)
    return dep


@app.get("/api/deployments/{dep_id}", response_model=Deployment, tags=["deployments"])
def get_deployment(dep_id: str) -> Deployment:
    dep = store.get_deployment(dep_id)
    if dep is None:
        raise HTTPException(status_code=404, detail="Deployment not found")
    return dep


@app.patch("/api/deployments/{dep_id}", response_model=Deployment, tags=["deployments"],
           dependencies=[Depends(require_token)])
def update_deployment(dep_id: str, payload: DeploymentStatusUpdate) -> Deployment:
    dep = store.update_deployment_status(dep_id, payload.status)
    if dep is None:
        raise HTTPException(status_code=404, detail="Deployment not found")
    if payload.status in (DeployStatus.succeeded, DeployStatus.failed, DeployStatus.rolled_back):
        DEPLOYMENTS.labels(dep.environment_id, payload.status.value).inc()
    return dep


@app.get("/api/drift", response_model=list[DriftRecord], tags=["drift"])
def list_drift(environment_id: Optional[str] = Query(default=None)) -> list[DriftRecord]:
    return store.list_drift(environment_id)


@app.post("/api/drift", response_model=DriftRecord, status_code=201, tags=["drift"],
          dependencies=[Depends(require_token)])
def report_drift(payload: DriftReport) -> DriftRecord:
    if store.get_environment(payload.environment_id) is None:
        raise HTTPException(status_code=404, detail="Unknown environment")
    record = store.record_drift(payload)
    DRIFTED_ENVS.set(len([e for e in store.list_environments() if e.drift == DriftStatus.drifted]))
    log.warning("drift report env=%s drifted=%s changed=%d", payload.environment_id, payload.drifted, payload.resources_changed)
    return record
