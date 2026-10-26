from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class DeployStatus(str, Enum):
    pending = "pending"
    in_progress = "in_progress"
    succeeded = "succeeded"
    failed = "failed"
    rolled_back = "rolled_back"


class DriftStatus(str, Enum):
    in_sync = "in_sync"
    drifted = "drifted"
    unknown = "unknown"


class Environment(BaseModel):
    id: str
    name: str
    region: str
    cluster: str
    drift: DriftStatus = DriftStatus.unknown
    last_synced_at: Optional[datetime] = None


class DeploymentCreate(BaseModel):
    """Payload a CI pipeline / GitOps controller posts when a rollout starts."""

    service: str = Field(min_length=1, max_length=63, pattern=r"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$")
    environment_id: str
    image: str = Field(min_length=1, description="Full image ref, e.g. ghcr.io/org/app:sha")
    git_sha: str = Field(min_length=7, max_length=64)
    triggered_by: str = "gitops"


class Deployment(DeploymentCreate):
    id: str
    status: DeployStatus = DeployStatus.pending
    started_at: datetime = Field(default_factory=utcnow)
    finished_at: Optional[datetime] = None


class DeploymentStatusUpdate(BaseModel):
    status: DeployStatus


class DriftReport(BaseModel):
    """Posted by a drift-detection job (e.g. `terraform plan -detailed-exitcode`)."""

    environment_id: str
    drifted: bool
    resources_changed: int = Field(default=0, ge=0)
    summary: str = ""


class DriftRecord(DriftReport):
    id: str
    detected_at: datetime = Field(default_factory=utcnow)


class Overview(BaseModel):
    environments: int
    deployments_total: int
    deployments_failed: int
    environments_drifted: int
    success_rate: float
