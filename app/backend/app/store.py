"""In-memory store.

Deliberately small and swappable: every method here maps 1:1 to something a
real repository (Postgres/DynamoDB provisioned by your Terraform) would do.
Replace this module's `store` with a DB-backed implementation exposing the same
methods and the routers don't need to change.
"""

import threading
import uuid
from typing import Optional

from .models import (
    DeployStatus,
    Deployment,
    DeploymentCreate,
    DriftRecord,
    DriftReport,
    DriftStatus,
    Environment,
    utcnow,
)


class Store:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self.environments: dict[str, Environment] = {}
        self.deployments: dict[str, Deployment] = {}
        self.drift_records: list[DriftRecord] = []
        self._seed()

    def _seed(self) -> None:
        for env in (
            Environment(id="dev", name="Development", region="eu-west-1", cluster="aether-dev", drift=DriftStatus.in_sync),
            Environment(id="staging", name="Staging", region="eu-west-1", cluster="aether-stg", drift=DriftStatus.in_sync),
            Environment(id="prod", name="Production", region="eu-west-1", cluster="aether-prod", drift=DriftStatus.in_sync),
        ):
            env.last_synced_at = utcnow()
            self.environments[env.id] = env

    # Environments
    def list_environments(self) -> list[Environment]:
        return list(self.environments.values())

    def get_environment(self, env_id: str) -> Optional[Environment]:
        return self.environments.get(env_id)

    # Deployments
    def create_deployment(self, payload: DeploymentCreate) -> Deployment:
        with self._lock:
            dep = Deployment(id=uuid.uuid4().hex[:12], **payload.model_dump())
            self.deployments[dep.id] = dep
            return dep

    def list_deployments(self, environment_id: Optional[str] = None, service: Optional[str] = None) -> list[Deployment]:
        items = list(self.deployments.values())
        if environment_id:
            items = [d for d in items if d.environment_id == environment_id]
        if service:
            items = [d for d in items if d.service == service]
        return sorted(items, key=lambda d: d.started_at, reverse=True)

    def get_deployment(self, dep_id: str) -> Optional[Deployment]:
        return self.deployments.get(dep_id)

    def update_deployment_status(self, dep_id: str, status: DeployStatus) -> Optional[Deployment]:
        with self._lock:
            dep = self.deployments.get(dep_id)
            if dep is None:
                return None
            dep.status = status
            if status in (DeployStatus.succeeded, DeployStatus.failed, DeployStatus.rolled_back):
                dep.finished_at = utcnow()
                env = self.environments.get(dep.environment_id)
                if env and status == DeployStatus.succeeded:
                    env.last_synced_at = dep.finished_at
            return dep

    # Drift
    def record_drift(self, report: DriftReport) -> DriftRecord:
        with self._lock:
            record = DriftRecord(id=uuid.uuid4().hex[:12], **report.model_dump())
            self.drift_records.append(record)
            env = self.environments[report.environment_id]
            env.drift = DriftStatus.drifted if report.drifted else DriftStatus.in_sync
            return record

    def list_drift(self, environment_id: Optional[str] = None) -> list[DriftRecord]:
        items = self.drift_records
        if environment_id:
            items = [r for r in items if r.environment_id == environment_id]
        return sorted(items, key=lambda r: r.detected_at, reverse=True)


store = Store()
