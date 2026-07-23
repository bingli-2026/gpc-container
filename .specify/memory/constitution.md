<!--
Sync Impact Report
- Version change: 1.2.0 → 1.3.0
- Modified principles:
  - Applicability Gates / MVP Gate: expands the approved first delivery from CPU-only
    to approved CPU and Ascend NPU workspace profiles in a controlled single-node
    environment; adds NPU device-sharing and isolation evidence.
  - Mandatory Architecture & Safety Constraints: permits this bounded Ascend NPU
    capability while retaining the prohibition on arbitrary accelerator scheduling,
    vNPU/HAMi, and multi-cluster brokering without an approved specification.
- Added sections: none
- Removed sections: none
- Templates requiring updates:
  - ✅ .specify/templates/plan-template.md (generic Constitution Check; no change)
  - ✅ .specify/templates/spec-template.md (generic scope/requirements; no change)
  - ✅ .specify/templates/tasks-template.md (generic task categories; no change)
  - ✅ .agents/skills/speckit-constitution/SKILL.md (generic workflow; no change)
  - ✅ .agents/skills/speckit-plan/SKILL.md (generic workflow; no change)
  - ✅ AGENTS.md (generic enforcement rules; no change)
- Follow-up TODOs: validate the approved Ascend device-share adapter mapping on 8T
  and 20T hardware before freezing its implementation contract.
-->

# gpc-container Constitution

**Version**: 1.3.0 | **Ratified**: 2026-07-22 | **Last Amended**: 2026-07-23

## Purpose

This constitution defines the non-negotiable architectural, security, durability,
contract, and delivery principles of the gpc-container teaching compute platform. It
governs specifications, plans, tasks, source code, migrations, deployment artifacts,
and runtime integrations. Engineering standards MAY add technology conventions but
MUST NOT weaken this constitution. Unless a rule names a later gate, its MUST
requirement applies from the MVP Gate.

## Core Principles

### I. Domain Ownership and Dependency Direction Before Infrastructure

Every capability MUST identify its bounded context, aggregate ownership, invariants,
transaction boundary, and externally visible responsibility before selecting
Kubernetes, Docker, database, storage, accelerator, or vendor SDK objects. The
control plane MUST remain a modular monolith until measurable load, deployment,
security, release, ownership, or team boundaries justify extraction.

Infrastructure integrations MUST be explicit ports and adapters. Domain code MUST
NOT depend on HTTP, session, authorization context, database driver/ORM, queue,
cache, object storage, Kubernetes/Docker types, device paths, or vendor SDK types.
Public APIs and domain models MUST use platform language such as workspace, image
profile, compute requirement, storage policy, operation, generation, and runtime
status.

The Go module MUST keep `transport → application → domain` dependency direction;
adapters MAY implement application/domain ports and `cmd` packages are composition
roots. A bounded context MUST NOT import another context's concrete aggregate,
repository, transport DTO, or infrastructure adapter. Cross-context collaboration
MUST use application orchestration, owned public ports, immutable integration events,
stable identifiers/read models, or an approved shared kernel. Automated architecture
tests, import checks, or static analysis MUST enforce these rules.

### II. Identity, Tenant Isolation, and Least Privilege Are Non-Negotiable

Every protected request MUST authenticate a stable subject and authorize both the
requested action and the target resource scope. RBAC alone is insufficient;
ownership, course/class/project membership, or an equivalent scope rule MUST be
evaluated for every tenant-owned resource. OIDC identities MUST map to stable internal
user IDs. Email addresses, display names, and usernames MUST NOT be primary identity
keys. The Go control plane MUST make authoritative authorization decisions; frontend
visibility controls MUST NOT be security boundaries.

High-risk actions, authorization denials, administrative impersonation, cross-user
actions, and changes to security-sensitive resources MUST audit actor, target, action,
outcome, timestamp, and correlation identifiers. Workloads MUST use non-privileged
execution, approved image profiles, explicit CPU/memory/storage/device limits,
least-privilege runtime credentials, isolated storage policies, and stable workspace
plus generation identifiers.

Privileged containers, Docker/runtime sockets, arbitrary HostPath mounts, host
networking, uncontrolled host devices, unreviewed images, and credentials shared
across unrelated users/courses are prohibited unless an approved isolated-experiment
specification explicitly permits them.

Next.js is a Backend for Frontend. It MUST NOT hold PostgreSQL credentials, connect
directly to the control-plane database, make authoritative authorization decisions,
mutate authoritative state outside the Go API, forward ID/refresh tokens, or replace
the end-user identity for user-authorized operations. The Go API MUST validate token
signature, issuer, audience, expiry/not-before constraints, stable subject, and
required scopes or claims.

### III. Durable and Idempotent Lifecycle Control

Every state-changing lifecycle capability MUST define legal and illegal transitions,
a stable operation ID, idempotency behavior, concurrency control, timeout/retry,
recovery, reconciliation, and deletion semantics. External infrastructure failures
are normal operating conditions, not exceptional impossibilities.

Before invoking an external runtime, scheduler, storage, network, image, or hardware
provider, the control plane MUST atomically persist the requested intent, operation
record, aggregate transition, generation or optimistic-concurrency value, audit
record, and Outbox event or equivalent durable-dispatch record. An Outbox-backed or
equally reliable worker MUST execute external effects.

Durability MUST NOT be chosen solely by expected duration. An API MAY wait within a
configured synchronous-response budget; after that budget it MUST return `202
Accepted`, an immutable operation ID, and a status-query location or equivalent.
Metadata-only operations that invoke no external system MAY execute synchronously in a
database transaction. Workers MUST tolerate duplicate delivery, timeouts, restarts,
partial success, lost responses, reordering, and concurrent user requests.
Generation, compare-and-swap, or equivalent concurrency controls MUST prevent stale
workers and requests from overwriting newer state. Reconciliation MUST compare
desired, recorded, and observed state using stable workspace IDs and generations.

### IV. Versioned Contracts and Safe Data Evolution

External APIs, internal service boundaries, events, runtime adapter interfaces, and
persisted schemas MUST be versioned contracts. Contracts MUST state stable identifiers,
request/response schemas, explicit error codes, authentication/authorization,
idempotency, correlation/trace propagation, compatibility, and deprecation behavior.
Breaking changes MUST have an approved specification, migration plan, compatibility
window, affected-client identification, and rollout/recovery instructions.

New compute, storage, accelerator, and runtime capability MUST extend domain models
and adapters. Infrastructure-specific settings MUST NOT leak directly into public APIs
without an approved domain abstraction.

PostgreSQL is the authoritative control-plane system of record. All schema changes
MUST live in a versioned `migrations/` directory and run through an approved tool.
Every production-relevant migration MUST document lock level, table-rewrite/full-scan
risk, transactional behavior, lock and statement timeouts, compatibility with
previous/next application versions, recovery strategy, expected duration, and
operational risk. Potentially blocking, destructive, table-rewriting, or large-data
transformations MUST use an expand-migrate-contract strategy rehearsed against
production-representative data. Non-transactional PostgreSQL operations, including
`CREATE INDEX CONCURRENTLY`, MUST be explicitly handled. A documented roll-forward
recovery is preferred when a mechanical down migration would create more risk.

### V. Evidence-Driven Incremental Delivery and Commit Discipline

Each increment MUST deliver an independently testable user outcome with measurable
acceptance criteria. Changes affecting authorization, tenant scope, state transitions,
idempotency, persistence, migrations, external contracts, runtime adapters,
reconciliation, deletion, or security boundaries MUST include suitable automated
verification. A change is not complete merely because code compiles.

Production-relevant behavior MUST provide structured logs, metrics, audit records,
and correlation evidence. The Go control plane MUST expose `/healthz` and readiness
information when startup dependencies require it. W3C Trace Context (`traceparent`
and, where present, `tracestate`) MUST propagate across applicable boundaries.
`x-request-id` MAY supplement human-facing correlation but MUST NOT replace distributed
trace context. Secrets, access/refresh/ID tokens, cookies, private keys, and sensitive
user data MUST NOT be logged.

An ADR MUST accompany a material change to bounded-context ownership, dependency
direction, authoritative data semantics, authentication/authorization, lifecycle,
persistence, external contracts, runtime adapters, or deployment architecture.

Every commit MUST use Conventional Commits: `type(optional-scope): summary`. Allowed
types are `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `build`, `ci`, and
`perf`; a breaking change MUST use `!` or a `BREAKING CHANGE` footer. Before every
commit, every applicable automated test and validation command MUST pass.
Documentation/template changes MUST compile or validate affected artifacts. When no
validation exists, the change MUST add it or obtain a documented, time-bounded
technical-owner exception before committing. Intentionally failing-test commits are
prohibited even when an individual workflow would otherwise permit a temporary Red
phase.

## Applicability Gates

### MVP Gate

The first single-node delivery MUST include stable internal identity mapping, basic
RBAC and resource-scope authorization, approved CPU and Ascend NPU image profiles,
non-privileged workloads, explicit CPU/memory/storage/device limits, a workspace state
machine, durable operation IDs, Outbox-backed execution, generation control,
PostgreSQL persistence, a persistent volume policy, structured logs, `/healthz`,
domain-invariant unit tests, persistence/runtime-adapter integration tests, and
complete CPU and Ascend NPU workspace lifecycles. Each lifecycle MUST demonstrate
authenticated creation, operation progress, state inspection, stop, restart, deletion,
and expected volume/audit behavior. The Ascend NPU adapter MUST prove device isolation,
separate class quota accounting, and the approved per-node concurrency limit on the
target 8T and 20T hardware; it MUST NOT silently downgrade a rejected NPU request to
CPU.

### Multi-Tenant Gate

Before serving unrelated students, classes, courses, or organizations, the platform
MUST add tenant-isolation tests, default-deny network/exposure policies, per-user or
per-course quotas, authorization-denial auditing, backup/restore verification,
lifecycle metrics/alerts, tenant/authorization contract tests, documented
administrative access and impersonation policy, and credential rotation procedures.

### Production Gate

Before production or public exposure, the platform MUST add end-to-end
OpenTelemetry, Prometheus metrics and service-level indicators, production migration
rehearsals, release plus rollback/roll-forward procedures, disaster-recovery
objectives and restore tests, vulnerability/dependency scanning, public-exposure
security review, load/concurrency validation, tested reconciliation/orphan cleanup,
operational runbooks, incident response, and audit-retention documentation.

## Mandatory Architecture & Safety Constraints

- The first scope is lifecycle management for platform-approved CPU and Ascend NPU
  workspaces in a controlled single-node environment. Ascend scheduling is limited to
  the approved device-share adapter, explicit class quotas, and approved per-node
  concurrency limits. Arbitrary accelerator scheduling, vNPU/HAMi, image construction,
  collaborative terminal viewing, public service exposure, and multi-cluster brokering
  remain out of scope without an approved specification.
- `go.mod` MUST remain at repository root unless an ADR changes module strategy.
  External runtime, database, queue, cache, storage, and vendor clients MUST remain
  outside domain packages. Dependency injection MUST be explicit in composition roots
  such as `cmd/server` or `cmd/worker`; hidden global-singleton initialization is
  prohibited.
- Runtime adapters MUST receive only domain-level workspace, volume, image-profile,
  and compute specifications. They MUST NOT receive HTTP requests, browser cookies,
  frontend sessions, or arbitrary unvalidated provider configuration.
- Next.js production builds MUST use an explicitly documented deployment mode. Public
  browser configuration MUST remain separate from server secrets. Secrets MUST be
  injected at runtime and MUST NOT be committed, baked into images, or exposed through
  public environment variables.

## Delivery Workflow & Quality Gates

1. A specification MUST define outcomes, exclusions, actors/authorization, lifecycle
   or data changes, failure cases, measurable success criteria, and applicable gate.
2. A plan MUST pass Constitution Check before research and after architecture/contract
   design. Exceptions MUST identify the violated principle, rationale, risk,
   compensating control, approver, and expiry/removal plan.
3. Tasks MUST include applicable authorization, migrations, unit/integration/contract/
   end-to-end tests, observability, documentation, ADRs, and recovery instructions.
4. Frontend and backend implementation MUST NOT start in parallel until their contract
   is stable enough for independent work. Pull requests MUST link specification, plan,
   task IDs, contracts, ADRs, and validation evidence.
5. Reviewers MUST reject changes that bypass a constitutional rule, introduce
   undocumented contracts, weaken isolation, omit recovery, leak infrastructure types,
   or lack evidence. Releases MUST include recovery instructions for schema,
   control-plane, worker, Next.js, and runtime-adapter changes.

## Governance

This constitution supersedes conflicting project conventions, templates, role
instructions, and implementation preferences. Any team member MAY propose an
amendment that documents affected principles, rationale, compatibility/security
impact, and required changes to specifications, plans, tasks, runtime guidance, and
operational artifacts. Technical and security owners MUST approve changes to security,
tenancy, identity, durability, external contracts, or lifecycle semantics.

Semantic versioning applies: MAJOR removes or incompatibly redefines a principle;
MINOR adds or materially expands a mandatory obligation; PATCH clarifies without
changing obligations. Every approved amendment MUST update its version, date, Sync
Impact Report, dependent templates, relevant agent guidance, and engineering
standards. Planning, task generation, implementation review, and convergence analysis
MUST verify compliance. Unresolved conflicts MUST be explicit, approved, time-bounded
exceptions and MUST NOT be silently waived.
