# Shared test fixtures

These deterministic fixtures are test data only. Their IDs and external OIDC subjects
are opaque identifiers, not login material. Tests must use the identity fixture to
exercise both an authorized same-class request and a denied cross-class request.

Runtime fixtures define only approved CPU and Ascend NPU profiles. They deliberately
exclude image references, device paths, credentials, host networking, HostPath mounts,
runtime-socket mounts, and privileged execution. Runtime adapters supply their own
approved internal mapping when integration tests require it.
