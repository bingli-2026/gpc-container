# K3s test-fixture boundary

This directory reserves the deterministic K3s fixture boundary for integration and
CI tests. It is not a production K3s deployment and contains no workload manifest,
host networking, privileged container, runtime socket, `hostPath`, device mount, or
production credential.

## Deterministic CI fixture

CPU-oriented adapter tests may use a disposable K3s fixture only when the test
harness supplies it explicitly. Such a fixture must use test-only images and
credentials, namespace-scoped resources, non-privileged workloads, explicit
CPU/memory/storage limits, and cleanup after every run. It must not depend on an
Ascend device, a host device path, or a vendor device-share resource key.

The PostgreSQL dependency for those tests is defined in
[`../compose.yaml`](../compose.yaml). Start it locally with:

```sh
docker compose -f deploy/test/compose.yaml up -d --wait
```

Remove the test database and its named volume after a run with:

```sh
docker compose -f deploy/test/compose.yaml down --volumes
```

The published database port is bound only to `127.0.0.1`; its credentials are
deliberately non-secret test values and must never be copied to a development or
production environment.

## Real Ascend hardware gate

This deterministic fixture does **not** validate Ascend NPU scheduling,
device-sharing, device isolation, resource discovery, or the per-node three-workspace
limit. Those checks require the approved target image, CANN, K3s, and device-share
adapter on Orange Pi AIPro 8T or 20T hardware. The adapter implementation and tests
must record the observed mapping only after that hardware gate succeeds; no CI fixture
may guess or encode a vendor resource key, annotation, or device path.
