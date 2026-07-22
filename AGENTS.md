# AGENTS.md

## 1. Purpose

This file defines how Codex CLI agents operate inside the gpc-container repository.

It governs:

* multi-agent coordination;
* task assignment;
* writable scope;
* Git worktree isolation;
* specification ownership;
* contract changes;
* testing and validation;
* commit and Pull Request evidence;
* escalation and convergence.

Role-specific agent definitions already exist in the project's configured agent files. This document does not redefine those role prompts.

Role files provide role expertise. This document provides repository-wide execution rules.

All agents, including coordinators, workers, reviewers, and explorers, MUST follow this file.

---

## 2. Instruction Precedence

When instructions conflict, agents MUST apply the following precedence:

1. `.specify/memory/constitution.md`
2. Approved feature specification under `specs/<feature>/spec.md`
3. Approved implementation plan under `specs/<feature>/plan.md`
4. Approved contracts, data models, ADRs, and migration plans
5. `specs/<feature>/tasks.md`
6. Repository engineering standards
7. This `AGENTS.md`
8. Role-specific agent configuration
9. The immediate task prompt
10. Local implementation preference

A lower-precedence instruction MUST NOT weaken or override a higher-precedence instruction.

When a conflict cannot be resolved, the agent MUST stop the conflicting work and escalate it to the coordinator.

Agents MUST NOT silently choose whichever instruction is easiest to implement.

---

## 3. Source-of-Truth Artifacts

The repository uses Spec-Driven Development.

The source-of-truth hierarchy is:

```text
constitution
    ↓
feature specification
    ↓
implementation plan
    ↓
contracts / data model / ADRs
    ↓
tasks
    ↓
implementation and tests
```

Code is an implementation of approved intent. Code does not silently redefine approved intent.

### Artifact responsibilities

| Artifact         | Purpose                                    | Default owner                    |
| ---------------- | ------------------------------------------ | -------------------------------- |
| Constitution     | Long-term project invariants               | Technical owner                  |
| `spec.md`        | User outcomes and acceptance criteria      | Coordinator                      |
| `plan.md`        | Technical architecture and delivery design | Coordinator / architecture role  |
| `contracts/`     | Stable interface boundaries                | Architecture role                |
| `data-model.md`  | Domain and persistence semantics           | Architecture / backend role      |
| ADRs             | Material architectural decisions           | Architecture role                |
| `tasks.md`       | Executable dependency-ordered work         | Coordinator                      |
| Source code      | Implementation                             | Assigned worker                  |
| Tests            | Verification evidence                      | Assigned worker / test role      |
| Migration files  | Versioned schema evolution                 | Explicitly assigned backend task |
| Release evidence | Merge and deployment verification          | Coordinator                      |

Workers MAY read all relevant artifacts.

Workers MUST NOT modify source-of-truth artifacts unless the assigned task explicitly authorizes those exact paths.

---

## 4. Spec Kit Workflow Ownership

The coordinator owns the feature-level Spec Kit lifecycle.

The following commands or equivalent skills SHOULD be run only by the coordinator unless explicitly delegated:

```text
speckit-constitution
speckit-specify
speckit-clarify
speckit-plan
speckit-tasks
speckit-analyze
speckit-taskstoissues
speckit-converge
```

Workers MUST NOT regenerate a feature specification, plan, task list, or contract merely because implementation becomes inconvenient.

When implementation exposes a problem in an artifact, the worker MUST report:

* affected artifact;
* conflicting requirement;
* implementation evidence;
* recommended correction;
* tasks likely to be invalidated.

The coordinator then decides whether to amend the artifact and regenerate or revise dependent tasks.

---

## 5. Default Multi-Agent Operating Model

The default topology is:

```text
Coordinator
├── optional read-only explorer
├── frontend or backend worker
├── second independent worker when safe
└── read-only reviewer or test agent when needed
```

The project does not use permanently active role agents.

Agents are started for bounded tasks and terminated after delivering their completion report.

### Default concurrency policy

* Default to one active agent.
* Use parallel agents only when parallel execution provides a clear benefit.
* At most two write-capable worker agents SHOULD run concurrently.
* A read-only explorer or reviewer MAY run alongside write workers when necessary.
* Only one write-capable agent MAY operate in a worktree at a time.
* Subagents MUST NOT create nested subagents.
* A worker MUST NOT delegate its assigned task to another agent.
* The coordinator MUST NOT duplicate work already assigned to an active worker.
* Testing and review agents SHOULD be started at the relevant delivery checkpoint rather than kept permanently active.
* Simple edits, formatting, one-file fixes, and trivial test corrections SHOULD remain single-agent tasks.

Increasing concurrency without an explicit dependency analysis is prohibited.

---

## 6. Conditions for Parallel Work

Two tasks MAY run in parallel only when all of the following are true:

1. Both tasks are marked parallelizable or have been explicitly approved for parallel execution.
2. Their writable file sets do not overlap.
3. Their generated files do not overlap.
4. Neither task depends on unfinished output from the other.
5. The relevant API, event, schema, or UI contract is stable.
6. Both tasks have independently testable acceptance criteria.
7. Shared infrastructure work has already completed.
8. Integration order is understood.
9. Failure of one task will not cause the other to implement guessed behavior.

Tasks MUST NOT run in parallel solely because they have different role labels.

### Unsafe parallel examples

The following SHOULD NOT run concurrently:

* two agents editing the same Go package;
* two agents editing the same React component tree;
* migration creation and repository implementation based on the unfinished migration;
* API contract design and frontend implementation against that same unsettled contract;
* shared type generation and manual edits to generated types;
* two agents modifying root build configuration;
* two agents changing authentication middleware;
* two agents changing the same dependency lock file.

---

## 7. Task Assignment Contract

Every worker task MUST include an explicit task contract.

The task contract MUST provide:

```text
Task ID:
User Story:
Role:
Objective:
Required input artifacts:
Writable paths:
Read-only relevant paths:
Forbidden paths:
Dependencies:
Acceptance criteria:
Validation commands:
Expected completion report:
```

### Required task properties

A task MUST:

* have one primary objective;
* identify exact writable paths;
* describe observable completion criteria;
* identify upstream dependencies;
* identify relevant contracts;
* provide validation expectations;
* be small enough to review as one logical change.

A worker MUST NOT begin an underspecified task that lacks a safe writable boundary.

The worker MAY perform read-only exploration to clarify implementation details, but MUST escalate missing requirements that materially affect behavior.

### Example task assignment

```text
Task ID: T021
User Story: US1
Role: backend
Objective: Implement creation of an approved CPU workspace operation.

Required input artifacts:
- specs/001-cpu-workspace/spec.md
- specs/001-cpu-workspace/plan.md
- specs/001-cpu-workspace/contracts/workspaces.openapi.yaml
- specs/001-cpu-workspace/data-model.md

Writable paths:
- internal/workspace/application/**
- internal/workspace/transport/http/**
- internal/workspace/adapter/postgres/**
- tests/integration/workspace_create_test.go

Read-only relevant paths:
- internal/identity/**
- internal/platform/**
- migrations/**

Forbidden paths:
- specs/**
- frontend/**
- migrations/**
- .specify/**

Dependencies:
- T014 contract freeze
- T018 workspace repository port

Acceptance criteria:
- Duplicate idempotency keys do not create duplicate operations.
- Unauthorized users receive the documented error.
- The operation and Outbox event persist atomically.
- API response matches the approved contract.

Validation commands:
- go test ./internal/workspace/...
- go test ./tests/integration/... -run WorkspaceCreate
```

---

## 8. Git Branch and Worktree Isolation

Parallel write agents MUST use separate Git worktrees.

Recommended branch naming:

```text
agent/<feature>-<role>-<task-id>
```

Examples:

```text
agent/001-workspace-frontend-T025
agent/001-workspace-backend-T021
agent/001-workspace-test-T030
```

Recommended worktree naming:

```text
../gpc-T021-backend
../gpc-T025-frontend
../gpc-T030-test
```

### Worktree rules

* Every parallel worker MUST start from the same approved integration-base commit.
* A worktree MUST have exactly one write-capable owner.
* Workers MUST NOT write into another agent's worktree.
* Workers MUST NOT rely on uncommitted files in another worktree.
* Workers MUST NOT share mutable generated output directories.
* Dependency lock files require explicit ownership.
* Root-level configuration requires explicit ownership.
* A worker MUST report its base commit in the completion report.
* The coordinator decides merge or cherry-pick order.
* Workers MUST NOT merge their own branches into the integration branch unless explicitly authorized.
* Force pushes are prohibited unless explicitly approved by the coordinator.

Read-only agents MAY inspect the main repository or an integration worktree without creating a separate worktree, provided they do not modify files.

---

## 9. Writable Scope Rules

A worker MAY modify only:

* paths explicitly assigned in the task contract;
* directly related test files explicitly permitted by the task;
* generated outputs whose generator and destination are explicitly part of the task.

A worker MUST NOT modify:

* `.specify/**`;
* unrelated feature specifications;
* unrelated contracts;
* unrelated ADRs;
* role configuration files;
* root build configuration;
* dependency lock files;
* database migrations;
* deployment manifests;
* CI workflows;
* another bounded context;

unless the task explicitly permits those paths.

### Out-of-scope discoveries

When a worker discovers a required out-of-scope change, it MUST:

1. stop before modifying the out-of-scope path;
2. record the required change;
3. explain why it is required;
4. identify affected tasks;
5. recommend a new task or contract amendment;
6. continue only with work that remains valid independently.

“Fixing it while here” is prohibited for out-of-scope changes.

---

## 10. Contract Freeze Protocol

Frontend, backend, test, and integration work MUST share the same approved contract.

A contract is considered frozen for an implementation increment when:

* its request and response schemas are defined;
* error codes are defined;
* authorization effects are defined;
* idempotency semantics are defined where applicable;
* operation-status behavior is defined;
* compatibility expectations are defined;
* unresolved material ambiguities are absent.

The contract MAY carry an explicit marker such as:

```text
status: frozen-for-US1
contract-version: 1.0
```

### Contract rules

* Frontend workers MUST NOT invent undocumented fields.
* Backend workers MUST NOT silently introduce undocumented behavior.
* Test workers MUST derive contract tests from the same approved artifact.
* Generated clients MUST be generated from the approved contract.
* Manual generated-code edits are prohibited.
* A contract change requires a distinct task.
* A breaking contract change requires coordinator approval.
* A contract amendment MUST identify dependent tasks that need revision or rerun.
* Workers MUST stop when the contract cannot support the assigned acceptance criteria.

### Contract change sequence

```text
contract change task
→ contract review
→ dependent task invalidation or update
→ regenerated clients or fixtures
→ frontend/backend implementation
→ contract tests
→ integration tests
```

---

## 11. Architecture Boundaries

All agents MUST preserve the dependency rules defined by the constitution.

### Go architecture

Expected dependency direction:

```text
transport → application → domain
adapter   → application/domain ports
cmd       → composition and startup
```

Domain packages MUST NOT import:

* HTTP frameworks;
* database clients;
* Kubernetes clients;
* Docker clients;
* object-storage clients;
* queue clients;
* Next.js or frontend types;
* vendor SDK types.

Cross-bounded-context interaction MUST use:

* application orchestration;
* public ports;
* stable identifiers;
* read models;
* integration events;
* an approved shared kernel.

Workers MUST NOT create a generic `common`, `utils`, `helpers`, or `shared` package to bypass ownership decisions.

### Next.js architecture

Next.js acts as a BFF and presentation layer.

Frontend agents MUST NOT:

* connect directly to PostgreSQL;
* add database credentials;
* implement authoritative authorization;
* persist authoritative control-plane state;
* forward ID or refresh tokens to the Go API;
* expose server secrets through `NEXT_PUBLIC_*`;
* mint user-equivalent service identities;
* bypass the Go API for state mutation.

Client-side checks MAY improve user experience but MUST NOT be treated as security enforcement.

### Runtime adapters

Runtime adapters MUST consume domain-level specifications.

They MUST NOT receive:

* raw HTTP requests;
* browser cookies;
* frontend session objects;
* UI-specific state;
* arbitrary unvalidated provider configuration.

Provider-specific details MUST remain inside the relevant adapter.

---

## 12. Database and Migration Rules

Migration files require an explicit migration task.

A worker MUST NOT generate an incidental migration while implementing another task unless the task contract explicitly authorizes it.

Every migration task MUST document:

* forward behavior;
* recovery strategy;
* lock behavior;
* transaction behavior;
* compatibility window;
* application rollout order;
* data backfill behavior;
* verification query or test.

### Migration constraints

* Migration files MUST be versioned.
* Destructive changes MUST use an approved staged strategy.
* Large backfills MUST NOT run as unbounded application startup work.
* `CREATE INDEX CONCURRENTLY` MUST be handled as non-transactional where required.
* Lock and statement timeouts MUST be explicit for production-relevant migrations.
* Agents MUST NOT add fake rollback SQL that cannot safely restore lost data.
* Roll-forward recovery is acceptable when documented and safer.
* Schema changes and application compatibility MUST be reviewed together.

Migration changes SHOULD be integrated before code that depends exclusively on the new schema, while preserving a safe deployment order.

---

## 13. Security Rules

Agents MUST treat tenant isolation and authorization as implementation requirements, not optional review concerns.

Changes involving users, courses, classes, projects, workspaces, volumes, images, runtime resources, or administrative actions MUST consider:

* actor identity;
* tenant or resource ownership;
* role permission;
* target-resource scope;
* audit behavior;
* enumeration resistance;
* error-information exposure;
* cross-tenant test coverage.

Agents MUST NOT:

* use email as an authoritative user key;
* trust tenant IDs supplied by the frontend without authorization;
* accept arbitrary runtime image references;
* mount Docker sockets;
* enable privileged containers;
* add HostPath mounts;
* enable host networking;
* log tokens or secrets;
* commit secrets;
* weaken default-deny policies without an approved specification.

Any suspected cross-tenant data exposure MUST immediately be escalated as a blocking issue.

---

## 14. Testing Strategy

Tests are part of the implementation, not a final cleanup phase.

### Minimum verification by change type

| Change type               | Minimum expected verification                   |
| ------------------------- | ----------------------------------------------- |
| Domain invariant          | Unit tests                                      |
| Application service       | Unit or component tests                         |
| Repository implementation | Database integration tests                      |
| HTTP or Connect endpoint  | Contract and integration tests                  |
| Authorization behavior    | Positive and negative authorization tests       |
| Tenant-scoped behavior    | Cross-tenant isolation tests                    |
| Runtime adapter           | Adapter integration or deterministic fake tests |
| State transition          | State-machine and idempotency tests             |
| Outbox or worker          | Retry and duplicate-delivery tests              |
| Migration                 | Migration validation and compatibility test     |
| Frontend interaction      | Component or integration test                   |
| Complete user story       | End-to-end acceptance test                      |

### Test-first behavior

Before every commit and before a Pull Request is marked ready:

* the required tests MUST pass;
* unrelated existing failures MUST be reported;
* intentionally failing tests MUST be resolved;
* skipped tests MUST have documented justification.

Workers MUST NOT delete, weaken, skip, or rewrite an existing valid test merely to make implementation pass.

When a test and specification disagree, the worker MUST escalate the conflict rather than choosing one silently.

---

## 15. Validation Commands

Agents MUST discover and use repository-defined commands before inventing new commands.

Preferred discovery order:

1. `Makefile`
2. `Taskfile.yml`
3. `justfile`
4. package-manager scripts
5. documented commands in `README.md`
6. CI workflow commands
7. language-native defaults

Typical Go validation MAY include:

```bash
go test ./...
go vet ./...
go build ./...
golangci-lint run
```

Typical Next.js validation MAY include:

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Typical integration validation MAY include:

```bash
docker compose config
docker compose up -d
go test ./tests/integration/...
pnpm test:e2e
```

Agents MUST run only commands applicable to the current repository and assigned scope.

A worker MUST report:

* exact command;
* exit status;
* relevant result;
* skipped validation and reason.

Agents MUST NOT claim a test passed when it was not executed.

---

## 16. Observability Requirements

Changes that add or alter production-relevant behavior MUST consider:

* structured logs;
* operation IDs;
* workspace IDs;
* stable user IDs;
* error codes;
* audit events;
* metrics;
* trace propagation.

Agents MUST preserve W3C Trace Context across applicable boundaries.

A request ID MAY supplement trace context but MUST NOT replace it.

Workers MUST NOT log:

* access tokens;
* refresh tokens;
* ID tokens;
* cookies;
* passwords;
* private keys;
* database passwords;
* secret environment variables;
* full sensitive request bodies.

Changes to lifecycle operations SHOULD include enough observability to distinguish:

* request accepted;
* operation persisted;
* event dispatched;
* worker started;
* provider call attempted;
* provider result observed;
* reconciliation result;
* terminal success or failure.

---

## 17. Commit Discipline

Every commit MUST use Conventional Commits:

```text
type(optional-scope): summary
```

Allowed types:

```text
feat
fix
docs
chore
refactor
test
build
ci
perf
```

Examples:

```text
feat(workspace): persist create operation and outbox event
test(authz): add cross-course workspace access cases
fix(runtime): ignore stale generation reconciliation result
docs(spec): clarify workspace deletion retention policy
```

### Commit rules

* One commit SHOULD represent one logical task step.
* Unrelated cleanup MUST NOT be mixed into a feature commit.
* Generated files and their source changes SHOULD be committed together.
* Every commit MUST pass its applicable validation; intentionally failing-test commits
  are prohibited.
* The final worker branch state MUST pass required validation.
* Secrets and local environment files MUST NOT be committed.
* Agents MUST inspect the staged diff before committing.
* Agents MUST NOT use `--no-verify` unless explicitly authorized.
* Agents MUST NOT amend or rewrite shared history without coordinator approval.

---

## 18. Pull Request Requirements

A worker completion is normally delivered through a reviewable branch or Pull Request.

The Pull Request description MUST include:

```markdown
## Task

- Task ID:
- User Story:
- Role:
- Base commit:

## Summary

- What changed:
- Why:

## Scope

- Files or packages changed:
- Explicitly excluded work:

## Contracts and data

- Contract impact:
- Migration impact:
- Compatibility impact:

## Verification

- Command:
- Result:

## Security and tenancy

- Authorization impact:
- Tenant-isolation impact:
- Audit impact:

## Risks

- Known limitations:
- Follow-up tasks:
```

A Pull Request MUST NOT be marked ready when:

* required tests fail;
* the contract is unresolved;
* the migration strategy is unresolved;
* a security boundary is unclear;
* out-of-scope edits are present;
* generated artifacts are stale;
* required evidence is missing.

---

## 19. Worker Completion Report

Every worker MUST return a structured completion report.

Required format:

```text
Task ID:
Role:
Branch:
Worktree:
Base commit:

Status:
- completed
- partially completed
- blocked

Files changed:

Behavior implemented:

Validation:
- command:
- result:

Contract impact:
Migration impact:
Authorization impact:
Observability impact:

Unresolved risks:

Recommended follow-up tasks:
```

The report MUST be concise but complete.

Raw command logs SHOULD NOT be pasted unless they contain evidence needed to diagnose a failure.

A worker MUST distinguish:

* implemented and verified;
* implemented but not verified;
* explored only;
* blocked.

---

## 20. Escalation Rules

A worker MUST stop and escalate when any of the following occurs:

* specification and implementation plan conflict;
* contract does not support required behavior;
* a breaking contract change appears necessary;
* an unassigned migration appears necessary;
* required writable paths exceed task scope;
* another bounded context must change;
* authorization semantics are unclear;
* tenant isolation may be weakened;
* destructive data behavior is possible;
* runtime behavior cannot be made idempotent;
* a required secret or credential is unavailable;
* the same failure persists after two evidence-based attempts;
* tests reveal an architectural contradiction;
* merge conflict changes intended behavior;
* another active worker owns the required file.

The escalation report MUST include:

```text
Blocking issue:
Evidence:
Affected artifacts:
Affected tasks:
Risk of proceeding:
Recommended decision:
```

The worker MUST NOT conceal a blocker by implementing a speculative workaround.

---

## 21. Failure and Retry Budget

Agents MUST avoid unbounded retry loops.

Default behavior:

1. First failure:

   * inspect evidence;
   * identify the likely cause;
   * perform one targeted correction.

2. Second failure:

   * compare the new evidence with the previous failure;
   * perform one materially different correction only when justified.

3. Persistent failure:

   * stop;
   * preserve logs and state;
   * escalate to the coordinator.

Repeating the same command or modification without new evidence is prohibited.

A worker MUST NOT broaden its scope in response to repeated failure.

---

## 22. Review Agent Rules

Review agents SHOULD operate read-only.

A reviewer MUST prioritize:

1. constitutional violations;
2. security and tenant-isolation defects;
3. contract mismatches;
4. state-machine and idempotency defects;
5. data-loss and migration risk;
6. runtime reconciliation defects;
7. missing acceptance coverage;
8. maintainability issues.

A reviewer MUST distinguish:

* blocking defect;
* high-priority defect;
* non-blocking improvement;
* optional style preference.

Every reported defect MUST include:

* file and location;
* violated requirement;
* evidence;
* user or system impact;
* recommended correction.

Reviewers MUST NOT manufacture issues merely to produce a long review.

Style-only preferences MUST NOT block a correct implementation unless an explicit repository standard is violated.

---

## 23. Integration Sequence

For a normal vertical user story, the coordinator SHOULD use this sequence:

```text
1. Specification and acceptance criteria
2. Architecture and data model
3. Contract freeze
4. Test skeletons or contract tests
5. Backend and frontend implementation in parallel
6. Migration and deployment compatibility validation
7. Integration tests
8. End-to-end acceptance test
9. Read-only review
10. Spec Kit convergence analysis
11. Integration-branch merge
```

Backend and frontend MAY proceed in parallel after the contract freeze when their writable paths do not overlap.

The test role SHOULD join before implementation completion when contract or acceptance tests can be authored independently.

The coordinator MUST determine merge order based on dependencies, not role seniority.

---

## 24. Convergence Gate

Before a user story is merged into the integration branch, the coordinator MUST verify alignment among:

* constitution;
* specification;
* implementation plan;
* contracts;
* data model;
* tasks;
* source code;
* tests;
* migrations;
* operational evidence.

The coordinator SHOULD run the Spec Kit convergence workflow or an equivalent structured comparison.

Any remaining implementation work MUST become an explicit task.

Incomplete work MUST NOT be hidden in comments, TODOs, undocumented assumptions, or follow-up promises.

A TODO that affects acceptance criteria, security, durability, or compatibility blocks completion unless explicitly approved and tracked.

---

## 25. Definition of Ready

A task is ready for assignment only when:

* task ID exists;
* objective is clear;
* relevant user story is identified;
* dependencies are complete;
* relevant contract is stable;
* writable paths are identified;
* acceptance criteria are measurable;
* validation commands are known;
* no unresolved constitutional conflict exists.

A task that fails these checks MUST remain blocked.

---

## 26. Definition of Done

A worker task is done only when:

* assigned behavior is implemented;
* writable scope was respected;
* required tests were added or updated;
* applicable validation passed;
* contract impact was reported;
* migration impact was reported;
* authorization and tenant impact were considered;
* observability impact was considered;
* documentation was updated where required;
* no untracked out-of-scope work remains;
* completion report was delivered.

A user story is done only when:

* all required tasks are complete;
* frontend and backend agree with the approved contract;
* acceptance criteria pass;
* end-to-end behavior is verified;
* security and tenant behavior are verified;
* lifecycle failure paths are adequately covered;
* convergence analysis finds no blocking divergence;
* integration evidence is recorded.

---

## 27. Prohibited Agent Behaviors

Agents MUST NOT:

* rewrite specifications to match accidental implementation;
* invent API fields or error behavior;
* silently weaken security requirements;
* bypass authorization in development code;
* share one writable worktree between concurrent agents;
* spawn nested agent trees;
* modify unassigned paths;
* perform unrelated refactoring;
* add generic abstractions without a current requirement;
* introduce a microservice without an approved ADR;
* introduce infrastructure types into domain models;
* use frontend checks as authoritative authorization;
* connect Next.js directly to PostgreSQL;
* add privileged workload capabilities;
* disable tests to achieve a passing build;
* fabricate validation results;
* hide failed commands;
* claim completion with unresolved acceptance failures;
* commit secrets;
* force-push shared branches without approval;
* continue after discovering a blocking constitutional conflict.

---

## 28. Repository Evolution

This file SHOULD remain focused on stable execution policy.

The following belong elsewhere:

* model names and pricing;
* temporary token budgets;
* individual developer preferences;
* local machine paths;
* short-lived CLI flags;
* role-specific prompt wording;
* provider-specific setup secrets.

Model selection, reasoning effort, and maximum thread count SHOULD be configured in Codex configuration and role files.

When this file changes materially, the change MUST consider updates to:

* role files;
* Spec Kit templates;
* task-generation conventions;
* Pull Request templates;
* CI validation;
* worktree scripts;
* engineering standards.

Changes to this file MUST NOT weaken the constitution.
