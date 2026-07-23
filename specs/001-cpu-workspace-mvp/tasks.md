---
description: "一期昇腾算子远程实训平台的可执行交付任务"
---

# Tasks: 昇腾算子远程实训平台一期 MVP

**Input**: `specs/001-cpu-workspace-mvp/` 下的 `spec.md`、`plan.md`、`research.md`、`data-model.md`、`quickstart.md`、`contracts/phase1.openapi.yaml` 与 `contracts/frontend-ui.md`。

**Prerequisites**: 本清单以 OpenAPI 1.3 草案和前端 UI 契约已冻结为前提。实现工作开始前，必须确认 `WorkspaceProfileCreate` 和 `WorkspaceProfile` 对 `ASCEND_NPU` 均强制 `resourcePolicy.npuSlots`；不得以 CPU 降级替代 NPU 拒绝。

**Tests**: 宪法要求对授权、状态转换、持久化、契约、运行时 Adapter、迁移、协调、删除和端到端用户结果提供自动化验证。测试任务应先写并在对应实现前确认失败。

**Commit gate**: 每次提交前运行与暂存改动适用的 `make format-check`、`make lint`、`make test-unit`、`make test-integration`、`make test-contract`、`make test-e2e`、`make architecture-check` 或 `make verify`；提交采用 Conventional Commits。

## Phase 1: Setup（共享基础）

**Purpose**: 建立模块化单体、Next.js BFF、可重复开发环境和统一验证入口。

- [X] T001 Initialize Go 1.26.5 module and API/Worker composition roots in `go.mod`, `cmd/api/main.go`, and `cmd/worker/main.go`
- [X] T002 [P] Initialize Next.js App Router, TypeScript, Bun, Tailwind CSS v4, and shadcn/ui baseline in `frontend/package.json`, `frontend/app/layout.tsx`, and `frontend/components.json`
- [X] T003 [P] Create repository validation targets in `Makefile` for format, lint, unit, integration, contract, E2E, architecture, and aggregate verification
- [X] T004 [P] Add local development configuration templates without secrets in `.env.example`, `frontend/.env.example`, and `internal/platform/config/config.go`
- [X] T005 [P] Add deterministic OIDC test identities and controlled dependency fixtures in `tests/fixtures/identity/subjects.json` and `tests/fixtures/runtime/`
- [X] T006 [P] Create local test orchestration and isolated PostgreSQL/K3s fixture definitions in `deploy/test/compose.yaml` and `deploy/test/k3s/README.md`
- [X] T007 [P] Record the approved single-node runtime and persistent-volume decisions in `specs/001-cpu-workspace-mvp/adrs/0001-single-node-kubernetes-runtime.md` and `specs/001-cpu-workspace-mvp/adrs/0002-phase1-ascend-and-persistent-volume.md`

---

## Phase 2: Foundational（阻塞性前置能力）

**Purpose**: 在任何用户故事前落实身份、范围授权、持久操作、Outbox、追踪、审计、迁移和前端安全边界。

**⚠️ CRITICAL**: 本阶段完成前不得开始用户故事实现。

- [ ] T008 Create versioned migration runner and migration metadata validation in `internal/platform/migrate/runner.go`, `migrations/`, and `tests/integration/migration_runner_test.go`
- [ ] T009 Create expand-migrate-contract baseline schema for identity, class, authorization, audit, operation, and outbox records in `migrations/000001_foundation.up.sql` and `migrations/000001_foundation.md`
- [ ] T010 [P] Define stable identity domain model and external-subject mapping port in `internal/identity/domain/user.go` and `internal/identity/application/ports.go`
- [ ] T011 [P] Define scope-aware authorization decision port and default-deny policy types in `internal/authorization/domain/decision.go` and `internal/authorization/application/authorizer.go`
- [ ] T012 [P] Define append-only audit and transactional Outbox domain contracts in `internal/audit/domain/record.go`, `internal/audit/domain/outbox_event.go`, and `internal/audit/application/ports.go`
- [ ] T013 [P] Define immutable operation, idempotency, generation, retry, and reconciliation primitives in `internal/platform/operation/operation.go` and `internal/platform/operation/idempotency.go`
- [ ] T014 Implement PostgreSQL repositories and atomic transaction boundary for identity, authorization, audit, Outbox, and operations in `internal/identity/adapter/postgres/`, `internal/authorization/adapter/postgres/`, `internal/audit/adapter/postgres/`, and `internal/platform/postgres/transaction.go`
- [ ] T015 Implement OIDC/JWT subject verification, stable subject resolution, and request actor context middleware in `internal/identity/transport/http/middleware.go` and `internal/identity/application/resolve_subject.go`
- [ ] T016 Implement traceparent/tracestate propagation, safe error mapping, correlation IDs, and structured logging in `internal/platform/observability/trace.go`, `internal/platform/observability/logging.go`, and `internal/platform/transport/http/errors.go`
- [ ] T017 Implement `/healthz` and dependency-aware `/readyz` endpoints in `internal/platform/transport/http/health_handlers.go` and `cmd/api/main.go`
- [ ] T018 Implement API routing, OpenAPI request/response validation, and authorization/audit middleware in `internal/platform/transport/http/router.go` and `internal/platform/transport/http/middleware.go`
- [ ] T019 Implement reliable Outbox dispatcher, duplicate-delivery guard, and Worker consumption loop in `internal/audit/application/dispatch_outbox.go` and `cmd/worker/main.go`
- [ ] T020 Create architecture dependency rule tests for `transport → application → domain` and adapter isolation in `tests/architecture/dependency_rules_test.go`
- [ ] T021 [P] Create contract-validation harness against `phase1.openapi.yaml` in `tests/contract/openapi_validation_test.go` and `tests/contract/fixtures/`
- [ ] T022 [P] Create foundational identity, trace, health, error-safety, and audit tests in `internal/identity/application/resolve_subject_test.go`, `internal/platform/observability/trace_test.go`, and `tests/integration/foundation_test.go`
- [ ] T023 [P] Create migration lock/statement-timeout, compatibility-window, verification-query, and roll-forward rehearsal evidence in `tests/integration/migration_foundation_test.go` and `migrations/000001_foundation.md`
- [ ] T024 [P] Create Next.js BFF boundary, no-secret-exposure, and non-authoritative authorization tests in `frontend/tests/bff-boundary.test.ts` and `frontend/tests/no-public-secret.test.ts`

**Checkpoint**: 统一身份、默认拒绝、可靠异步操作、审计/追踪、迁移、健康检查和前端 BFF 边界可验证；后续用户故事可按依赖并行。

---

## Phase 3: User Story 1 - 创建并管理自己的算力工作区（Priority: P1）🎯 MVP

**Goal**: 班级成员可使用批准且已启用的 CPU 或 Ascend NPU Profile 创建、查看、停止、启动、重置和删除自己的持久工作区。

**Independent Test**: 已授权成员完成 CPU/NPU 工作区全生命周期；停止/重置保留数据，删除遵循明确数据处置，重复请求无副作用。

### Tests for User Story 1

- [ ] T025 [P] [US1] Add OpenAPI contract tests for Profile resource policy, workspace create/delete, operation history, volume, and command endpoints in `tests/contract/workspace_contract_test.go`
- [ ] T026 [P] [US1] Add domain state-machine, duplicate-name, idempotency, retry, and stale-generation tests in `internal/workspace/domain/workspace_test.go` and `internal/workspace/domain/operation_test.go`
- [ ] T027 [P] [US1] Add PostgreSQL persistence tests for owner/class name uniqueness, retained-volume ownership, quota reservation, and atomic Operation/Outbox writes in `tests/integration/workspace_repository_test.go`
- [ ] T028 [P] [US1] Add CPU lifecycle integration tests for create, stop, start, reset, delete-keep, and delete-data in `tests/integration/cpu_workspace_lifecycle_test.go`
- [ ] T029 [P] [US1] Add Ascend admission tests for NPU slot requirement, separate quota, no CPU downgrade, and three-workspace node limit in `tests/integration/ascend_workspace_admission_test.go`
- [ ] T030 [P] [US1] Add runtime timeout, duplicate message, partial delete, member-loss, and Profile revocation reconciliation tests in `tests/integration/workspace_reconciliation_test.go`
- [ ] T031 [P] [US1] Add workspace portal component and keyboard/delete-dialog tests in `frontend/tests/workspace-portal.test.tsx` and `frontend/tests/workspace-delete-dialog.test.tsx`

### Implementation for User Story 1

- [ ] T032 [P] [US1] Define Workspace, WorkspaceVolume, WorkspaceOperation, Profile, quota, and lifecycle domain invariants in `internal/workspace/domain/workspace.go`, `internal/workspace/domain/volume.go`, `internal/workspace/domain/operation.go`, and `internal/workspace/domain/profile.go`
- [ ] T033 [P] [US1] Define domain-level runtime and storage ports without K3s types in `internal/workspace/application/runtime_port.go` and `internal/workspace/application/storage_port.go`
- [ ] T034 [US1] Add workspace/profile/volume schema with unique active-name enforcement, generation, idempotency, and migration evidence in `migrations/000002_workspace.up.sql` and `migrations/000002_workspace.md`
- [ ] T035 [US1] Implement PostgreSQL workspace, volume, operation, Profile, class-quota, and Outbox repositories in `internal/workspace/adapter/postgres/`
- [ ] T036 [US1] Implement Profile approval, ordinary disable, class enablement/quota, and idempotent security/compliance revocation application services in `internal/workspace/application/profile_service.go` and `internal/class/application/profile_enablement_service.go`
- [ ] T037 [US1] Implement create, lifecycle command, delete disposition, volume rebind/delete, and explicit retry application services in `internal/workspace/application/workspace_service.go` and `internal/workspace/application/operation_service.go`
- [ ] T038 [US1] Implement worker-side lifecycle execution, generation comparison, timeout reconciliation, and automatic volume-delete retry in `internal/workspace/application/reconcile_worker.go`
- [ ] T039 [US1] Implement CPU runtime adapter with non-privileged workload policy and persistent-volume binding in `internal/workspace/adapter/k3s/cpu_runtime.go` and `internal/workspace/adapter/k3s/volume_binding.go`
- [ ] T040 [US1] Implement Ascend device-share adapter using only domain ComputeRequirement, isolated volume access, and explicit node-slot admission in `internal/workspace/adapter/k3s/ascend_runtime.go`
- [ ] T041 [US1] Verify target 8T/20T discovery, isolation, and three concurrent NPU workspaces; record adapter-only mapping evidence in `tests/integration/ascend_hardware_gate_test.go` and `docs/operations/ascend-adapter-validation.md`
- [ ] T042 [US1] Implement workspace/Profile/volume/operation HTTP handlers matching `phase1.openapi.yaml` in `internal/workspace/transport/http/handlers.go` and `internal/workspace/transport/http/routes.go`
- [ ] T043 [US1] Add lifecycle audit records, metrics, trace linkage, and safe user failure projection in `internal/workspace/application/audit.go` and `internal/workspace/application/metrics.go`
- [ ] T044 [US1] Implement Next.js BFF clients for workspace, volume, operation, Profile, and idempotent commands in `frontend/lib/bff/workspace.ts` and `frontend/lib/bff/operation.ts`
- [ ] T045 [US1] Implement shared responsive app shell, class switcher, 12-column page container, and navigation Sheet in `frontend/components/layout/page-container.tsx`, `frontend/components/layout/app-shell.tsx`, and `frontend/components/layout/class-switcher.tsx`
- [ ] T046 [P] [US1] Implement reusable workspace cards, Profile selector, quota display, operation timeline, and data-disposition dialog in `frontend/components/features/workspace/`
- [ ] T047 [US1] Implement my-workspaces route, create flow, status polling, operation history, and volume management in `frontend/app/(portal)/workspaces/page.tsx`, `frontend/app/(portal)/workspaces/[workspaceId]/page.tsx`, and `frontend/app/(portal)/workspaces/loading.tsx`
- [ ] T048 [US1] Implement workspace error/not-disclosed states and matching identity-free Skeletons in `frontend/app/(portal)/workspaces/error.tsx`, `frontend/components/skeletons/workspace-skeleton.tsx`, and `frontend/components/features/workspace/not-disclosed.tsx`
- [ ] T049 [US1] Add CPU 20-create/3-minute success-criterion E2E evidence and data-retention E2E cases in `tests/e2e/workspace_mvp_test.go`

**Checkpoint**: US1 可独立演示并满足 CPU/NPU 生命周期、持久数据、NPU 准入、操作追踪和删除处置要求。

---

## Phase 4: User Story 4 - 查看班级终端操作与实训进度（Priority: P1）

**Goal**: 教师和授权助教可在班级范围内查询已过滤的 WebIDE、SSH 与 VS Code Remote-SSH 终端过程及采集缺口。

**Independent Test**: 不同入口的学生终端输入/stdout/stderr 被关联、过滤和归档；本班教师可查询，跨班级主体无法枚举。

### Tests for User Story 4

- [ ] T050 [P] [US4] Add terminal-record list/filter/pagination and non-disclosure contract tests in `tests/contract/terminal_contract_test.go`
- [ ] T051 [P] [US4] Add sensitive-content redaction and capture-gap domain tests in `internal/terminal/domain/redaction_test.go` and `internal/terminal/domain/record_test.go`
- [ ] T052 [P] [US4] Add WebIDE, SSH, and VS Code Remote-SSH adapter integration tests in `tests/integration/terminal_capture_adapter_test.go`
- [ ] T053 [P] [US4] Add teacher/class isolation, audit, realtime/history, and capture-recovery integration tests in `tests/integration/terminal_access_test.go`
- [ ] T054 [P] [US4] Add responsive terminal-page, filter, table, keyboard, Skeleton, and safe-empty-state tests in `frontend/tests/terminal-records.test.tsx`

### Implementation for User Story 4

- [ ] T055 [P] [US4] Define filtered TerminalRecord and capture-gap domain models and retention policy in `internal/terminal/domain/record.go` and `internal/terminal/domain/redaction.go`
- [ ] T056 [US4] Add terminal records, capture gaps, scope indexes, and migration evidence in `migrations/000003_terminal_records.up.sql` and `migrations/000003_terminal_records.md`
- [ ] T057 [US4] Implement terminal repository, class-scope query, cursor pagination, and archive projection in `internal/terminal/adapter/postgres/`
- [ ] T058 [US4] Implement pre-visibility redaction, capture ingestion, gap/recovery evidence, and audit application services in `internal/terminal/application/capture_service.go` and `internal/terminal/application/query_service.go`
- [ ] T059 [US4] Implement WebIDE and SSH/Remote-SSH terminal capture adapters without recording secrets in `internal/terminal/adapter/webide/capture.go` and `internal/terminal/adapter/ssh/capture.go`
- [ ] T060 [US4] Implement terminal record HTTP query handler and authorization/audit behavior in `internal/terminal/transport/http/handlers.go`
- [ ] T061 [US4] Implement terminal BFF filtering client and typed read model in `frontend/lib/bff/terminal.ts` and `frontend/lib/bff/types.ts`
- [ ] T062 [US4] Implement teaching-process route, filters, accessible responsive table, record detail, and class-safe Skeleton in `frontend/app/(portal)/teaching/terminal-records/page.tsx`, `frontend/components/features/terminal/`, and `frontend/components/skeletons/terminal-records-skeleton.tsx`
- [ ] T063 [US4] Add terminal capture health, redaction, gap-count metrics, alerts, and operational dashboard projection in `internal/terminal/application/metrics.go` and `docs/operations/terminal-capture-runbook.md`
- [ ] T064 [US4] Add three-entry terminal teaching-process E2E acceptance evidence in `tests/e2e/terminal_teaching_process_test.go`

**Checkpoint**: US4 提供不泄露敏感内容或其他班级信息的教学过程证据。

---

## Phase 5: User Story 2 - 按班级范围管理访问与角色（Priority: P2）

**Goal**: 授权管理员可管理角色、权限、绑定、班级成员、Profile 和额度；所有资源操作遵循范围和不可枚举语义。

**Independent Test**: 两个班级的成员、角色和工作区管理相互隔离；普通成员和跨班级主体均得到无枚举拒绝与审计。

### Tests for User Story 2

- [ ] T065 [P] [US2] Add RBAC, permission CRUD, RoleBinding, member removal, Profile governance, and trace-header contract tests in `tests/contract/authorization_contract_test.go`
- [ ] T066 [P] [US2] Add Role/Permission/RoleBinding scope and immutable-action domain tests in `internal/authorization/domain/rbac_test.go`
- [ ] T067 [P] [US2] Add two-class authorization, ownership, cross-user operation, and non-enumeration integration tests in `tests/integration/class_authorization_test.go`
- [ ] T068 [P] [US2] Add member-removal coordination and in-flight workspace cleanup integration tests in `tests/integration/member_removal_test.go`
- [ ] T069 [P] [US2] Add role-management, class-member, Profile-quota, capability-menu, and keyboard dialog tests in `frontend/tests/class-administration.test.tsx`

### Implementation for User Story 2

- [ ] T070 [P] [US2] Define Class, ClassMembership, Role, Permission, and RoleBinding aggregates and scoped invariants in `internal/class/domain/` and `internal/authorization/domain/`
- [ ] T071 [US2] Add class membership, RBAC, binding, quota policy, and Profile-enablement migration with rehearsal evidence in `migrations/000004_class_rbac.up.sql` and `migrations/000004_class_rbac.md`
- [ ] T072 [US2] Implement Class/RBAC PostgreSQL repositories and scope-filtered read models in `internal/class/adapter/postgres/` and `internal/authorization/adapter/postgres/`
- [ ] T073 [US2] Implement permission/role/binding CRUD, compatible disable/delete rules, and audit services in `internal/authorization/application/rbac_service.go`
- [ ] T074 [US2] Implement member upsert and asynchronous removal coordination that revokes access and cancels affected creation safely in `internal/class/application/membership_service.go` and `internal/class/application/remove_member_worker.go`
- [ ] T075 [US2] Implement class creation, membership, RBAC, Profile enablement, and operational-summary HTTP handlers in `internal/class/transport/http/handlers.go` and `internal/authorization/transport/http/handlers.go`
- [ ] T076 [US2] Implement authorization-denial audit and administrator cross-user operation policy in `internal/authorization/application/denial_audit.go` and `docs/operations/administrator-access-policy.md`
- [ ] T077 [US2] Implement BFF clients for classes, membership, roles, permissions, bindings, Profiles, quotas, and capabilities in `frontend/lib/bff/class.ts` and `frontend/lib/bff/authorization.ts`
- [ ] T078 [US2] Implement class administration pages and shared accessible Role/Permission/Binding dialogs in `frontend/app/(portal)/admin/classes/page.tsx`, `frontend/app/(portal)/admin/rbac/page.tsx`, and `frontend/components/features/authorization/`
- [ ] T079 [US2] Implement Profile/quota governance, member removal pending state, and safe not-disclosed UI in `frontend/components/features/class/` and `frontend/components/skeletons/class-administration-skeleton.tsx`
- [ ] T080 [US2] Add two-class governance and non-enumeration E2E acceptance evidence in `tests/e2e/class_rbac_isolation_test.go`

**Checkpoint**: US2 支持可演进 RBAC 和班级治理，且所有拒绝与跨用户管理都有范围验证与审计。

---

## Phase 6: User Story 5 - 以独立工作区执行长期 API 任务（Priority: P2）

**Goal**: 被授权主体可提交、查看和管理长期任务，任务始终使用独立 TaskWorkspace/Volume 和可撤销 TaskGrant。

**Independent Test**: 有班级和任务范围权限的主体可操作任务；任何任务均无法读取学生工作区、卷或终端记录，也不能暴露服务端点。

### Tests for User Story 5

- [ ] T081 [P] [US5] Add Task, Task command, TaskGrant, and non-disclosure OpenAPI contract tests in `tests/contract/task_contract_test.go`
- [ ] T082 [P] [US5] Add TaskWorkspace/TaskGrant isolation and lifecycle domain tests in `internal/task/domain/task_test.go` and `internal/task/domain/grant_test.go`
- [ ] T083 [P] [US5] Add task persistence, duplicate submission, grant revocation, and cross-class isolation integration tests in `tests/integration/task_isolation_test.go`
- [ ] T084 [P] [US5] Add task runtime adapter tests proving no student-volume reuse and no service exposure in `tests/integration/task_runtime_test.go`
- [ ] T085 [P] [US5] Add task list/detail/grant accessible UI, pending operation, and not-disclosed tests in `frontend/tests/task-management.test.tsx`

### Implementation for User Story 5

- [ ] T086 [P] [US5] Define LongRunningTask, TaskWorkspace, TaskVolume, TaskGrant, and task-scope policy domain models in `internal/task/domain/`
- [ ] T087 [US5] Add task, task workspace/volume, grants, operations, and audit schema migration with recovery evidence in `migrations/000005_tasks.up.sql` and `migrations/000005_tasks.md`
- [ ] T088 [US5] Implement task and TaskGrant PostgreSQL repositories with strict separate workspace/volume identities in `internal/task/adapter/postgres/`
- [ ] T089 [US5] Implement idempotent task submission, cancellation, reconciliation, and TaskGrant grant/revoke services in `internal/task/application/task_service.go` and `internal/task/application/grant_service.go`
- [ ] T090 [US5] Implement task runtime/storage adapter boundary that rejects service exposure and student-resource references in `internal/task/adapter/k3s/task_runtime.go`
- [ ] T091 [US5] Implement task HTTP handlers, operation lookup, authorization, denial auditing, and control-plane-only request validation in `internal/task/transport/http/handlers.go`
- [ ] T092 [US5] Implement typed task/TaskGrant BFF clients in `frontend/lib/bff/task.ts`
- [ ] T093 [US5] Implement long-running task list/detail, submit/cancel, grant/revoke dialogs, Skeleton, and safe error states in `frontend/app/(portal)/tasks/page.tsx`, `frontend/app/(portal)/tasks/[taskId]/page.tsx`, `frontend/components/features/task/`, and `frontend/components/skeletons/task-skeleton.tsx`
- [ ] T094 [US5] Add independent-task-workspace and revoked-grant E2E acceptance evidence in `tests/e2e/task_workspace_isolation_test.go`

**Checkpoint**: US5 可在不触碰学生资源且不公开服务 API 的前提下交付长期任务控制面能力。

---

## Phase 7: User Story 3 - 跟踪失败并安全恢复（Priority: P3）

**Goal**: 用户和班级负责人可安全查看操作进度、失败原因与重试资格；系统可从超时、重启和部分副作用中协调恢复。

**Independent Test**: 注入可恢复与不可恢复故障，验证同请求无重复副作用、显式重试关联原操作、旧结果不覆盖新状态，并最终到达明确状态。

### Tests for User Story 3

- [ ] T095 [P] [US3] Add operation status/retry/result and export-result conditional-schema contract tests in `tests/contract/operation_contract_test.go`
- [ ] T096 [P] [US3] Add retry eligibility, correlation, stale-generation, and terminal-state domain tests in `internal/platform/operation/operation_test.go`
- [ ] T097 [P] [US3] Add worker restart, duplicate delivery, provider timeout, partial success, and out-of-order observation tests in `tests/integration/operation_recovery_test.go`
- [ ] T098 [P] [US3] Add operation-history, failure-safety, retry-button, and no-duplicate-submit frontend tests in `frontend/tests/operation-recovery.test.tsx`

### Implementation for User Story 3

- [ ] T099 [US3] Extend operation persistence with safe failure classification, retry lineage, desired/observed reconciliation state, and query indexes in `migrations/000006_operation_recovery.up.sql` and `migrations/000006_operation_recovery.md`
- [ ] T100 [US3] Implement durable retry eligibility, original-request idempotency lookup, and safe failure projection in `internal/platform/operation/retry_service.go` and `internal/platform/operation/failure.go`
- [ ] T101 [US3] Implement shared reconciliation scheduler for workspace, volume, Profile revocation, training disposition, and task effects in `internal/platform/operation/reconciliation_worker.go`
- [ ] T102 [US3] Implement operation query/retry HTTP handlers and contract-specific export result projection in `internal/platform/transport/http/operation_handlers.go`
- [ ] T103 [US3] Implement BFF operation polling/retry client and non-sensitive failure model in `frontend/lib/bff/operation.ts` and `frontend/components/features/operation/`
- [ ] T104 [US3] Integrate operation timeline, retry affordance, correlation display, and state-preserving pending UI across `frontend/app/(portal)/workspaces/[workspaceId]/page.tsx` and `frontend/app/(portal)/tasks/[taskId]/page.tsx`
- [ ] T105 [US3] Add recovery fault-injection E2E acceptance evidence for duplicate, timeout, restart, and stale-result cases in `tests/e2e/operation_recovery_test.go`

**Checkpoint**: US3 为所有异步外部副作用提供可追踪、可恢复且不泄露内部细节的用户闭环。

---

## Phase 8: 培训期处置、运营与跨故事完成项

**Purpose**: 交付培训期关闭/导出/清理、备份恢复、试点 Multi-Tenant Gate 证据、前端全页设计验证和发布文档。

- [ ] T106 [P] Add training-period close/export/download/cleanup OpenAPI contract tests, including required successful export result and reauthorization audit, in `tests/contract/training_period_contract_test.go`
- [ ] T107 [P] Add training-period retention, export, cleanup, and authorization integration tests in `tests/integration/training_period_test.go`
- [ ] T108 Add training-period aggregate, export result, and cleanup state migration with recovery evidence in `migrations/000007_training_period.up.sql` and `migrations/000007_training_period.md`
- [ ] T109 Implement training-period close, export, controlled download, explicit cleanup, and audit/Outbox services in `internal/class/application/training_period_service.go` and `internal/class/application/export_service.go`
- [ ] T110 Implement training-period HTTP endpoints and controlled download reauthorization in `internal/class/transport/http/training_period_handlers.go`
- [ ] T111 Implement BFF clients and training-period close/export/cleanup UI with explicit admin-only destructive confirmation in `frontend/lib/bff/training-period.ts`, `frontend/app/(portal)/classes/[classId]/training-period/page.tsx`, and `frontend/components/features/training-period/`
- [ ] T112 [P] Add backup/restore tests for class scope, membership, operations, audit, and persistent-volume ownership in `tests/integration/backup_restore_test.go`
- [ ] T113 [P] Add lifecycle, quota, node, terminal-gap, Outbox, and authorization-denial metrics/alerts in `internal/platform/observability/metrics.go`, `deploy/observability/alerts.yaml`, and `docs/operations/metrics-alerts.md`
- [ ] T114 [P] Add default-deny workload/network exposure policy and verification in `deploy/k3s/policies/default-deny.yaml` and `tests/integration/network_exposure_test.go`
- [ ] T115 [P] Add credential-rotation procedure and verification evidence in `docs/operations/credential-rotation.md` and `tests/integration/credential_rotation_test.go`
- [ ] T116 [P] Add responsive design verification for 375px/768px/1024px/1440px, Skeleton non-disclosure, reduced motion, and dialog focus restoration in `frontend/tests/responsive-accessibility.test.tsx`
- [ ] T117 [P] Implement remaining frozen frontend routes for class operational summary, audit records, and platform operations in `frontend/app/(portal)/operations/page.tsx`, `frontend/app/(portal)/audit/page.tsx`, and `frontend/components/features/operations/`
- [ ] T118 [P] Update every page and modal design asset/index against the frozen UI contract in `specs/001-cpu-workspace-mvp/frontend-prototype.md` and `docs/design/assets/`
- [ ] T119 Add full quickstart acceptance automation covering CPU 20-create, NPU three-concurrency, double-class isolation, three terminal entries, training period, task isolation, recovery, backup, and health evidence in `tests/e2e/phase1_acceptance_test.go`
- [ ] T120 Run architecture, contract, unit, integration, E2E, OpenAPI, Typst, and quickstart verification; record results in `docs/validation/phase1-verification.md` and `specs/001-cpu-workspace-mvp/quickstart.md`
- [ ] T121 Run Spec Kit convergence analysis and record any remaining explicit tasks in `specs/001-cpu-workspace-mvp/tasks.md` and `specs/001-cpu-workspace-mvp/plan.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，可立即开始。
- **Foundational (Phase 2)**: 依赖 Setup；阻塞所有用户故事。
- **US1 与 US4（P1）**: 依赖 Foundational。US4 依赖已可关联的 Workspace/identity 稳定标识，因此其采集 Adapter 可与 US1 的前端工作并行，但最终集成在 US1 Workspace 读模型完成后。
- **US2（P2）**: 基础默认拒绝已在 Foundational；完整 RBAC/成员治理在 US1 前端并行或其后集成，成员移除协调依赖 US1 工作区服务。
- **US5（P2）**: 依赖 Foundational 与 US1 的 Operation/Runtime/Volume 端口；不得复用 Workspace 聚合。
- **US3（P3）**: 依赖 US1/US5 已产生的操作类型；其基础 Operation 原语已在 Foundational。
- **Phase 8**: 依赖所有所需用户故事，完成培训期、试点门槛、全链路验收和收敛。

### User Story Completion Order

`Setup → Foundational → US1 → US4 / US2 → US5 → US3 → Cross-Cutting`。

US4 与 US2 可在 US1 的 Domain/ports 固定后分支并行；US5 在 US1 的 Runtime/Volume ports 固定后并行。遵守 `AGENTS.md`：并行写任务必须使用独立 worktree、文件集合不重叠且从同一整合基线开始。

### Parallel Opportunities

- Phase 1 的 T002–T007 可与 T001 并行，文件无重叠。
- Phase 2 中领域契约、测试 harness、前端边界测试可并行；T014–T019 依赖其完成。
- 每个用户故事中标记 `[P]` 的测试可并行编写；必须先确认失败再实现。
- US1 的 Domain/ports、US4 的终端模型、US2 的 RBAC Domain、US5 的 Task Domain 在共享基础稳定后可由不同 worktree 进行。
- Phase 8 的备份、指标、网络策略、凭证轮换、响应式验证和原型更新可并行。

## Parallel Example: User Story 1

```text
Task: T025 contract tests in tests/contract/workspace_contract_test.go
Task: T026 domain state-machine tests in internal/workspace/domain/workspace_test.go
Task: T027 persistence tests in tests/integration/workspace_repository_test.go
Task: T031 frontend workspace tests in frontend/tests/workspace-portal.test.tsx
```

完成 T032/T033 后，T034–T035 由后端 worktree 负责，T044–T048 由前端 worktree 负责；二者均以冻结的 `contracts/phase1.openapi.yaml` 为唯一契约。

## Implementation Strategy

### MVP First

1. 完成 Phase 1 和 Phase 2，并通过基础验证。
2. 完成 US1 的 CPU 生命周期、持久卷、操作/Outbox、授权和前端闭环。
3. 在受控环境运行 T049 的 CPU 验收；确认至少 19/20 次在三分钟内进入可用或明确失败终态。
4. 完成 Ascend Adapter 硬件门槛 T041 后，才将 NPU Profile 面向试点开放。

### Incremental Delivery

1. US1：个人 CPU/NPU 工作区闭环。
2. US4：教学过程证据。
3. US2：班级治理与可扩展 RBAC。
4. US5：独立长期任务工作区。
5. US3：跨所有异步效果的恢复体验。
6. Phase 8：培训期、Multi-Tenant Gate、运营与完整验收。

## Notes

- `[P]` 仅表示技术上文件和未完成依赖不冲突；实际并行仍须遵守任务契约与 worktree 隔离。
- 每项工作开始前必须从本文件提取 `AGENTS.md` 所要求的 Task ID、用户故事、可写路径、依赖、验收准则与验证命令，形成分派契约。
- 所有实现均须保持领域模型不依赖 HTTP、PostgreSQL、K3s、Ascend SDK 或前端类型；Adapter 不得泄露运行时资源键、设备路径或敏感数据。
