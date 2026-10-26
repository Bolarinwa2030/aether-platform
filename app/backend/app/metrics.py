"""Prometheus metrics, exposed at /metrics for scraping by your telemetry stack."""

import time

from fastapi import FastAPI, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

HTTP_REQUESTS = Counter(
    "aether_http_requests_total", "HTTP requests", ["method", "path", "status"]
)
HTTP_LATENCY = Histogram(
    "aether_http_request_duration_seconds", "HTTP request latency", ["method", "path"]
)
DEPLOYMENTS = Counter(
    "aether_deployments_total", "Deployments by final status", ["environment", "status"]
)
DRIFTED_ENVS = Gauge("aether_environments_drifted", "Number of environments currently drifted")


def install_metrics(app: FastAPI) -> None:
    @app.middleware("http")
    async def _metrics_mw(request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        # Use the route template (e.g. /deployments/{id}) to keep label cardinality low.
        route = request.scope.get("route")
        path = getattr(route, "path", request.url.path)
        HTTP_REQUESTS.labels(request.method, path, response.status_code).inc()
        HTTP_LATENCY.labels(request.method, path).observe(time.perf_counter() - start)
        return response

    @app.get("/metrics", include_in_schema=False)
    def metrics() -> Response:
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
