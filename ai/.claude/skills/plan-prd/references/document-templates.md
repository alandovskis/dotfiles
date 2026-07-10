# Document assembly templates

Read this file at Step 6, once all Step 5 generator-reviewer loops are complete. Fill in the bracketed placeholders from the sections/task groups/test cases produced in Step 5; do not alter the surrounding structure.

## Step 6A: Assemble the SDD

*Always run.*

Combine all sections into one document:

```
# Software Design Document: [PRD title]

**Source PRD**: [Confluence link]
**Status**: Draft
**Date**: [today]

## Overview
[2–3 sentences summarising what this document covers]

## Scope
- **In scope**: [features/systems addressed]
- **Out of scope**: [explicitly excluded]

## Architecture Diagrams
[Mermaid diagrams for overall system context, container/component flow, data pipeline, ER model, sequence flow, state machine, or deployment topology where helpful. Omit this section only if diagrams would not clarify the document.]

## Requirements Coverage
| Req ID | Title | Status |
|--------|-------|--------|
| REQ-001 | ... | ✅ |
| REQ-002 | ... | ⚠️ Needs Human Review |

---
[REQ-001 section]
---
[REQ-002 section]
...

## Open Questions
[Consolidated list of all ⚠️ flagged items and unresolved design decisions]
```

## Step 6B: Assemble the Test Plan

*Always run.*

Reorganize the generated test cases by test type. Each test case belongs to exactly one top-level section based on its **Type** field:

| Type field value | Section |
|-----------------|---------|
| Happy path | Functional Tests |
| Boundary | Functional Tests |
| Negative | Functional Tests |
| Error path | Error & Recovery Tests |
| Performance | Performance Tests |

Within each section, group test cases under a sub-heading for the requirement they cover. Omit a section entirely if no test cases of that type were generated.

Assembled document structure:

```
# System Test Plan: [PRD title]

**Source PRD**: [Confluence link]
**Status**: Draft
**Date**: [today]

## Test Scope
- **In scope**: [features/requirements being tested]
- **Out of scope**: [explicitly excluded]

## Test Approach
- Unit tests are out of scope; this plan covers system-level and integration tests.
- Functional and error & recovery tests run against a staging environment with a
  real database and mocked external dependencies unless noted.
- Performance tests use [tool, e.g. k6] against a dedicated load-test environment;
  they must not run against shared staging.
- All tests are independently executable (no shared state between test cases).

## Environment Requirements
[Runtime, DB, external service mocks, seed data scripts, env vars]

## Entry Criteria
- All in-scope requirements implemented and deployed to staging.
- Seed data script executed successfully.
- External dependencies mocked or available.

## Exit Criteria
- All test cases executed.
- All "Must" requirement test cases pass.
- No unacknowledged P1 failures.
- Test results documented and linked from this page.

## Requirements Coverage
| Req ID | Title | Functional | Error & Recovery | Performance | Status |
|--------|-------|-----------|-----------------|------------|--------|
| REQ-001 | ... | 3 | 1 | 1 | ✅ |
| REQ-002 | ... | 3 | 1 | — | ✅ |

---

## Functional Tests
*(Happy path, boundary, and negative test cases)*

### REQ-001 — [Title]
[TC-001-1, TC-001-2, TC-001-3]

### REQ-002 — [Title]
[TC-002-1, TC-002-2, TC-002-3]

---

## Error & Recovery Tests
*(Failure injection, downstream unavailability, infrastructure faults)*

### REQ-001 — [Title]
[TC-001-4]

### REQ-002 — [Title]
[TC-002-4]

---

## Performance Tests
*(Load, latency, and throughput tests — only for requirements with a measurable target)*

### REQ-001 — [Title]
[TC-001-5]

---

## Risks
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| [Risk 1] | High/Med/Low | High/Med/Low | [Mitigation] |
```

## Step 6C: Assemble the Implementation Plan

*Always run.*

Combine all task groups into one document:

```
# Implementation Plan: [PRD title]

**Source PRD**: [Confluence link]
**Status**: Draft
**Date**: [today]

## Implementation Overview
[2–4 sentences summarising how the work is sequenced and what the main delivery risks are]

## Autonomous Execution Contract
- **No user intervention required:** [state the assumptions and defaults that let an AI agent proceed]
- **Repository discovery commands:** [commands the implementer should run first, e.g. rg/find/test discovery]
- **Validation commands:** [unit, integration, lint, typecheck, migration, and smoke-test commands]
- **Feature flags / config:** [flags, env vars, rollout defaults, and rollback switches]
- **Fallback rule:** If optional context is missing, use the documented assumptions and add/adjust tests rather than pausing for user input.

## Delivery Milestones
| Milestone | Goal | Requirement IDs | Exit Criteria |
|-----------|------|-----------------|---------------|
| M1 | ... | REQ-001, REQ-002 | ... |

## Cross-Requirement Dependency Map
[Mermaid dependency graph when useful; otherwise a table of dependency relationships]

## Task Summary
Grouped first by requirement, then by Owner Role within each requirement (same grouping and row order as each requirement's Task Breakdown in Step 5C):

### REQ-001 — [Title]

##### Backend Engineer
| Task ID | Task | Type | Target Files / Modules | Dependencies | Estimate | Acceptance Criteria | Validation | Status |
|---------|------|------|------------------------|--------------|----------|---------------------|------------|--------|
| IMP-REQ-001-01 | ... | Backend | src/... | — | M | ... | ... | Draft |

##### Frontend Engineer
| Task ID | Task | Type | Target Files / Modules | Dependencies | Estimate | Acceptance Criteria | Validation | Status |
|---------|------|------|------------------------|--------------|----------|---------------------|------------|--------|
| IMP-REQ-001-02 | ... | Frontend | src/... | IMP-REQ-001-01 | S | ... | ... | Draft |

### REQ-002 — [Title]
...

---
[REQ-001 implementation task group]
---
[REQ-002 implementation task group]
...

## Test Plan Implementation Breakdown
[For each requirement, include a table that maps generated test case IDs to the implementation work required to make the test executable and meaningful, including fixtures, test harness changes, synthetic data, automation scripts, and any required code hooks. Keep this section separate from the task groups so it can be reviewed independently.]

## Release Plan
[Feature flags, migrations, backfills, rollout sequence, monitoring, rollback, and documentation]

## Open Risks and Blockers
[Consolidated risks/blockers with owner and target date]
```
