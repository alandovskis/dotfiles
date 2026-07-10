---
name: plan-prd
description: |-
  Reads a PRD from Confluence and always generates all three planning artifacts:
  a Software Design Document, System Test Plan, and autonomous Implementation
  Plan with task breakdown plus a separate test-plan implementation breakdown.
  Uses a generator-reviewer loop per requirement and publishes the assembled
  documents to Confluence under the chosen space and parent page.
---

Turn a Confluence PRD into three artifacts every time: a Software Design Document (SDD), a System Test Plan, and an autonomous Implementation Plan. For each requirement, run a generator-reviewer loop per artifact, then publish the assembled documents back to Confluence. Follow the steps below precisely.

## Step 1: Resolve cloud ID and choose source PRD

**1a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**1b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass a `type` filter — omitting it returns all spaces, including collaboration spaces. Present every returned space via AskUserQuestion and ask which one contains the PRD.

**1c. Choose the PRD page** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. Paginate until all pages are listed, then present every title via AskUserQuestion and ask which is the PRD.

**1d. Fetch the PRD** — use the selected page's `id` as `pageId`. Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

## Step 2: Generate all artifacts

Do not ask which artifact(s) to generate. Always generate all three:
- **Software Design Document**
- **System Test Plan**
- **Implementation Plan**

## Step 3: Choose destination(s)

Ask the user via AskUserQuestion whether all generated artifacts should publish to the same space/parent page or to different ones.
- **Same** — resolve one destination using the destination-resolution procedure below and store it as `spaceId`/`parentId`, used for every generated document.
- **Different** — resolve a destination using the destination-resolution procedure below for each artifact, storing `sddSpaceId`/`sddParentId`, `tpSpaceId`/`tpParentId`, and `implSpaceId`/`implParentId`.

Destination-resolution procedure: ask whether to publish to the PRD's space or a different one. Same space: reuse the PRD space `id`. Different space: call `getConfluenceSpaces` again (no type filter) and present the list. Either way, call `getPagesInConfluenceSpace` with the destination space `id` and present every title via AskUserQuestion so the user can choose the parent page (include "space root" as an option). Store the resolved space/parent IDs under the variable names required by the chosen same/different mode.

## Step 4: Extract requirements

Parse the PRD content for individual requirements. They may appear as:
- A `## Requirements` table (columns may include ID, title, description, user story, UI Component, notes)
- A numbered or bulleted list of requirement statements
- Sections with requirement headings

For each requirement, record:
- **ID** — existing identifier or auto-generated (REQ-001, REQ-002…)
- **Title** — short label
- **Description** — full requirement text, including any acceptance criteria and notes
- **UI Component** — `Yes` if the requirement row or text indicates a user-facing screen, form, dashboard, report view, navigation, notification, visual workflow, or other interactive/visual interface; otherwise `No`

Also extract design-system context from the PRD:
- Links or notes in the Quick Links `Designs` entry
- Any `## Design` section content
- Named design system, component library, style guide, accessibility rules, platform conventions, or brand constraints

Present the list to the user and confirm before generating:
> "I found [N] requirements: [list with UI Component: Yes/No]. Shall I generate the SDD, system test plan, and autonomous implementation plan?"

If the document has no identifiable requirements, tell the user and stop.

## Step 5: Generator-reviewer loops

For **each requirement**, run all three loops below. The loops are independent of each other — run them in any order.

### Step 5A: SDD loop — one section per requirement

*Always run.*

#### Pass 1 — Generator

Draft the SDD section as an experienced software architect. Use concrete language — no "could", "might", "should consider". Populate every sub-section below; write "N/A — [reason]" only where it genuinely doesn't apply.

If `UI Component: Yes`, include a high-fidelity UI mockup following the extracted design-system context. It must read like a buildable screen or flow: page/component shell, header/body/footer structure, exact control labels, realistic example content, primary and secondary actions, empty/loading/error/disabled states, and the design-system components/tokens used. Use Mermaid, ASCII wireframe, a Markdown table, or concise HTML/CSS pseudomarkup that survives Confluence publishing. If the PRD names no design system, state the assumed baseline before the mockup and follow common accessible product UI conventions. Add responsive notes when the UI changes materially on mobile.

Add Mermaid diagrams wherever they clarify the design — architecture flows, sequence diagrams, state machines, entity relationships, data pipelines, deployment topology, or decision workflows — but don't force one for a trivial requirement. Each diagram is a fenced `mermaid` code block with a short lead-in sentence explaining what it shows.

Section structure:

**Requirement Summary** — verbatim or paraphrased requirement text.

**Design Approach** — 2–4 paragraphs: chosen design and why, key architectural patterns, integration points with existing systems. Include an "Alternatives considered" table (approach vs. reason rejected).

**Diagrams** — include one or more Mermaid diagrams when useful; otherwise write "N/A — diagram would not clarify this requirement."

**UI Mockup** — for `UI Component: Yes`, include a requirement-specific, high-fidelity mockup with exact labels, example content, and state variations; for `UI Component: No`, write "N/A — no user-facing UI component."

**Data / Workflow Diagrams** — include Mermaid ER, flowchart, sequence, or state diagrams when the requirement introduces non-trivial data relationships, asynchronous processing, lifecycle states, integration flow, or approval/review workflow. If a diagram is already included under **Diagrams** and covers this, write "Covered above." If not useful, write "N/A — no non-trivial data or workflow diagram needed."

**Data Model Changes** — new tables/collections/fields with schema (column types, constraints, indexes, migration strategy). If none: "N/A — no schema changes required."

**API / Interface Changes** — new or modified endpoints (method, path, auth, request/response shapes) and internal interfaces. If none: "N/A."

**Error Handling** — table: Condition | HTTP Status | Error Code | User-Facing Message. Must include at minimum: invalid input (400), not found (404), unauthorized (403), conflict (409), downstream failure (503).

**Security** — authentication requirement, authorization rules, input validation approach, PII handling.

**Testing** — at least 3 unit test scenarios and 2 integration test scenarios (state what is asserted, not just "write tests").

**Dependencies** — upstream (what this feature requires), downstream (what consumes it), blocking (other REQ IDs that must land first).

**Open Questions** — any unresolved design decisions with owner and target date. Omit if none.

#### Pass 2 — Subagent Reviewer

Spawn a subagent using the Agent tool with the following prompt (substitute the actual requirement text and draft section):

> You are a critical senior software engineer reviewing a draft SDD section. Find gaps only — do not rewrite it.
>
> **Requirement:** [ID, title, full description, UI Component: Yes/No]
>
> **Design-system context:** [design links, Design section notes, component library, style guide, accessibility rules, platform conventions, or "not specified"]
>
> **Draft SDD section:** [full draft text]
>
> **Must pass** (flag any failure):
> - Every clause of the requirement is addressed
> - No empty sections (only "N/A — reason" is acceptable)
> - No internal contradictions or unowned TBDs
> - Mermaid diagrams appear wherever they'd clarify non-trivial architecture, data relationships, lifecycle/state transitions, async flows, or review workflows; each omission has an explicit "N/A — diagram would not clarify..." reason
> - UI Mockup matches the UI Component flag: if Yes, a high-fidelity screen/flow with exact labels, example content, primary controls, and relevant states, following the design-system context; if No, "N/A — no user-facing UI component."
>
> **Should pass** (flag if 2+ fail):
> - At least one alternative considered and rejected with a concrete reason
> - Mermaid diagrams are fenced `mermaid` blocks a Confluence reader can follow unaided
> - Error table covers all five required conditions (400, 403, 404, 409, 503)
> - Schema changes include constraints and migration strategy
> - Security checklist covered (auth, validation, PII)
> - Test scenarios cover happy path, an error path, and an edge case
> - UI mockups name the design-system components/tokens used, state the assumption explicitly when none is specified, and include responsive/state details where relevant
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [section] — [specific gap and what to add]\n2. ...`

Wait for the subagent to return its verdict before proceeding.

#### Pass 3 — Revision

If the subagent returned REVISE: apply every cited gap, then spawn a fresh reviewer subagent with the revised draft using the same prompt above.

After the second review, if still REVISE: accept the section with a `⚠️ Needs Human Review: [outstanding issues]` prefix. Maximum 2 revision rounds per requirement — never loop further.

### Step 5B: Test Plan loop — one group per requirement

*Always run.*

Launch three independent subagents using the Agent tool. Each agent is started fresh (not a fork) so the reviewer has no memory of the generation reasoning — giving genuinely independent feedback.

#### Agent 1 — Generator

Launch a fresh agent with this prompt, substituting the bracketed values:

> You are a QA engineer writing system-level test cases. Return only the test cases in the format below — no preamble.
>
> **Requirement**
> ID: [REQ-ID] — [Title]
> Description: [full requirement text, including acceptance criteria and notes]
>
> **System context**
> [2–3 sentences: what the system does, the tech stack, and any success metrics stated for this requirement]
>
> **Instructions**
> Write 2–6 test cases covering types 1–4 below, always. Add type 5 only when the requirement or success metrics state a measurable target (latency, throughput, success rate, time window); otherwise write one line: "Performance: No measurable target defined — omitted."
>
> 1. Happy path — valid, normal inputs behave correctly.
> 2. Boundary / edge case — inputs at valid-range limits (empty collections, max/min sizes, exact thresholds).
> 3. Negative / invalid input — system rejects or gracefully handles invalid input.
> 4. Error / failure path — system recovers from a downstream failure, missing dependency, or infrastructure fault.
> 5. Performance — load profile (N concurrent users or req/s), acceptance threshold (e.g. p95 < 2s, error rate < 1%), recommended tool (k6 / wrk / locust).
>
> Format each test case exactly as:
>
> **TC-[REQ_ID]-[N]**
> - **Title**: [short imperative phrase]
> - **Type**: Happy path | Boundary | Negative | Error path | Performance
> - **Preconditions**: [specific named DB records, config values, mock responses — never "the system is configured correctly"]
> - **Steps**: [numbered, one action per step, unambiguous subject, e.g. "The test runner calls POST /api/v1/…"]
> - **Expected result**: [exact HTTP status, DB state change, log entry, or UI state — never "returns success"]
> - **Pass criteria**: [one-line PASS/FAIL condition]
>
> Use concrete values throughout — the actual example URL, not "a valid URL"; the exact status code and body shape, not "returns an error".

Store the agent's output as `draft`.

#### Agent 2 — Reviewer

Launch a fresh agent with this prompt. Pass only the requirement and `draft` — do not include any generation reasoning or prior context:

> You are a QA lead reviewing someone else's test cases. Evaluate only the draft below — do not write new cases.
>
> **Requirement**
> ID: [REQ-ID] — [Title]
> Description: [full requirement text, including acceptance criteria and notes]
>
> **Draft test cases**
> [draft]
>
> **Must pass** — REVISE if any fail:
> - Happy path, boundary, negative, and error-path types are all present
> - Performance type is present exactly when the requirement states a measurable target — never both-missing-with-target or present-without-target
> - Every clause of the requirement and every stated acceptance criterion is covered by at least one test case
> - No vague precondition ("the system is set up correctly") or vague expected result ("the operation succeeds")
> - All pass criteria are binary PASS/FAIL, not subjective
>
> **Should pass** — REVISE if 2+ fail:
> - Preconditions name specific data values, not categories
> - Steps are executable by someone unfamiliar with the codebase
> - Error-path cases name the exact failure injected (e.g. "mock returns HTTP 503")
> - Boundary cases state the exact boundary value under test
> - Each test case is independent — no test relies on another having run first
>
> Output exactly one of:
> - `APPROVED` (one optional sentence of commentary)
> - `REVISE:` followed by a numbered list: `[TC-ID or "missing case"] — [specific problem and exactly what to add or fix]`

Store the agent's output as `review`.

#### Agent 3 — Revision (only if `review` starts with `REVISE`)

Launch a fresh agent with this prompt:

> You are a QA engineer revising test cases per reviewer feedback. Return the complete revised set — original cases with corrections applied, plus any new cases the feedback requires — in the original format.
>
> **Requirement**
> ID: [REQ-ID] — [Title]
> Description: [full requirement text]
>
> **Original draft**
> [draft]
>
> **Reviewer feedback**
> [review]
>
> Apply every numbered feedback item exactly. Add nothing beyond what the feedback requires.

Store the output as `revised_draft`. Then re-run Agent 2 (reviewer) against `revised_draft`.

**Termination:**
- Either review returns `APPROVED` → use those test cases as the final output for this requirement.
- Second review still returns `REVISE` → accept `revised_draft` as-is; prepend `⚠️ Needs Human Review: [paste the outstanding reviewer items]` to the test case block for this requirement.
- Maximum 2 revision rounds. Never loop further.

### Step 5C: Implementation Plan loop — one task group per requirement

*Always run.*

#### Pass 1 — Generator

Draft an implementation task group the AI coding agent can execute without rereading the PRD or asking follow-up questions. Use concrete language: dependency order, validation gates, acceptance criteria, expected files/modules/interfaces where inferable, and explicit assumptions for any PRD gap. No vague tasks like "implement backend" or "add tests".

Make it autonomous-execution ready:
- No "ask user", "TBD", "decide later", "confirm approach", or unowned discovery as a blocker.
- Where the PRD lacks a detail, choose a conservative assumption, label it, and add a verification task that proves or disproves it without user intervention.
- Every task states its concrete output: code, schema migration, API contract, UI state, test, fixture, config, documentation, or rollout change.
- Every task includes enough context to implement safely: target component/module, input/output contract, data shape, error behavior, permissions, and validation command where applicable.
- Tasks may reference SDD/Test Plan sections when generated, but must stand alone if those artifacts are unavailable.

Each requirement task group must include:

**Requirement Summary** — requirement ID, title, and short implementation goal.

**Implementation Strategy** — 1–3 paragraphs explaining sequencing, ownership boundaries, architecture dependencies, and rollout approach.

**Task Breakdown** — grouped under a sub-heading per Owner Role (e.g. `##### Backend Engineer`, `##### Frontend Engineer`, `##### QA Engineer`), in the order roles first appear in the requirement's dependency chain. Within each role's sub-heading, a table with columns: Task ID | Task | Type | Target Files / Modules | Dependencies | Estimate | Acceptance Criteria | Validation, with rows in dependency order. Task IDs must be stable and requirement-scoped, e.g. `IMP-REQ-001-01`. Types must be one of: Discovery, Backend, Frontend, Data, Infrastructure, Testing, Security, Documentation, Release. Discovery tasks must produce repo-local artifacts or decisions and cannot require user input.

**Test Plan Implementation Breakdown** — a separate table that maps the requirement's generated test plan cases to the implementation work needed to support them. Include columns: Test Case ID | Test Objective | Supporting Code / Fixture / Harness Work | Implementation Task IDs | Validation. This table must explicitly cover all generated happy path, boundary, negative, error, and performance cases for the requirement when such cases exist.

**Execution Order** — numbered list of task IDs in dependency order, grouped into milestones when useful.

**Parallelizable Work** — list task IDs that can run in parallel and note what shared interfaces or contracts must be agreed first.

**Testing and Verification Tasks** — include at least one unit/integration/system verification task, and link each to SDD design areas or Test Plan cases when those artifacts are also generated.

**Autonomous Execution Notes** — list implementation assumptions, inferred defaults, repo discovery commands, validation commands, required fixtures, feature flags, environment variables, and rollback commands. This section must make clear how an AI agent should proceed if it encounters missing optional context.

**Release / Migration Tasks** — data migrations, feature flags, backfills, rollout, monitoring, rollback, and documentation tasks. If none: "N/A — no release or migration tasks required."

**Risks and Blockers** — table: Risk/Blocker | Impact | Mitigation | Owner | Target Date. Include open PRD questions that block implementation.

#### Pass 2 — Reviewer

Spawn a subagent using the Agent tool with the following prompt:

> You are a critical engineering manager reviewing an implementation plan task group. Find planning gaps only — do not rewrite the plan.
>
> **Requirement:** [ID, title, full description, UI Component: Yes/No]
>
> **Draft implementation task group:** [full draft text]
>
> **Must pass** (flag any failure):
> - Every material clause of the requirement maps to at least one task
> - The task group is executable by an AI coding agent without user intervention: no "ask user", unowned TBDs, unresolved choices, or vague discovery blockers
> - Missing PRD details carry an explicit conservative assumption plus a verification task, not a deferral to the user
> - Task Breakdown is grouped by Owner Role, with stable task IDs, target files/modules where inferable, dependencies, estimates, acceptance criteria, and validation commands per role table
> - Execution order is coherent — no task depends on undeclared later work
> - Testing/verification work is explicit, not folded into implementation tasks
> - Release, migration, feature flag, monitoring, rollback, and documentation work is present where relevant, or marked N/A with a reason
> - Risks/blockers have owners and target dates
>
> **Should pass** (flag if 2+ fail):
> - Tasks are small enough to become Jira stories or sub-tasks
> - Tasks state concrete code/data/config/doc outputs, not activities
> - Parallelizable work is identified
> - Estimates are plausible relative sizes (S/M/L or day ranges)
> - Cross-artifact references to SDD/Test Plan appear when those artifacts are generated
> - User-facing requirements include frontend, accessibility, and UX verification tasks
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [section] — [specific gap and what to add]\n2. ...`

#### Pass 3 — Revision

If the subagent returned REVISE: apply every cited gap, then spawn a fresh reviewer subagent with the revised draft using the same prompt above.

After the second review, if still REVISE: accept the task group with a `⚠️ Needs Human Review: [outstanding issues]` prefix. Maximum 2 revision rounds per requirement — never loop further.

---

## Step 6: Assemble the document(s)

### Step 6A: Assemble the SDD

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

### Step 6B: Assemble the Test Plan

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

### Step 6C: Assemble the Implementation Plan

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

---

## Step 7: Publish to Confluence

Convert each assembled document to HTML. Use `<h2>`, `<h3>` for headings, `<table>`/`<thead>`/`<tbody>`/`<tr>`/`<th>`/`<td>` for tables, `<pre><code class="language-...">` for code blocks, `<ul>`/`<ol>`/`<li>` for lists, `<strong>` for bold. Preserve Mermaid diagrams as `<pre><code class="language-mermaid">...</code></pre>` blocks so Confluence keeps the source text even when it does not render Mermaid natively. Do not wrap content in `<html>`, `<head>`, or `<body>` tags.

**7a. Publish the SDD** — use the `spaceId`/`parentId` resolved in Step 3 (or `sddSpaceId`/`sddParentId` if separate destinations were chosen). Call `createConfluencePage` with:
- `cloudId`
- `spaceId`, `parentId` (omit `parentId` if the user chose space root)
- `title` — `"SDD: [PRD title]"`
- `body` — assembled SDD as HTML
- `contentFormat` — `"html"`
- `status` — `"draft"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user if they want a new page with a date suffix: `SDD: [PRD title] (YYYY-MM-DD)`.

**7b. Publish the Test Plan** — use the `spaceId`/`parentId` resolved in Step 3 (or `tpSpaceId`/`tpParentId` if separate destinations were chosen). Call `createConfluencePage` with:
- `cloudId`
- `spaceId`, `parentId` (omit `parentId` if the user chose space root)
- `title` — `"Test Plan: [PRD title]"`
- `body` — assembled test plan as HTML
- `contentFormat` — `"html"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user whether they want a date-suffixed title: `Test Plan: [PRD title] (YYYY-MM-DD)`.

**7c. Publish the Implementation Plan** — use the `spaceId`/`parentId` resolved in Step 3 (or `implSpaceId`/`implParentId` if separate destinations were chosen). Call `createConfluencePage` with:
- `cloudId`
- `spaceId`, `parentId` (omit `parentId` if the user chose space root)
- `title` — `"Implementation Plan: [PRD title]"`
- `body` — assembled implementation plan as HTML
- `contentFormat` — `"html"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user whether they want a date-suffixed title: `Implementation Plan: [PRD title] (YYYY-MM-DD)`.

On success, report every page published:
> "✅ SDD published: [Confluence page URL]"
> "✅ Test plan published: [Confluence page URL]"
> "✅ Implementation plan published: [Confluence page URL]"

## Edge cases

**No explicit requirements section**: infer requirements from feature descriptions or user stories; group related items and confirm the grouping with the user before proceeding.

**Vague requirement (SDD)**: generate the section with best effort, flag `⚠️ Insufficient detail — design decisions deferred`.

**Vague requirement with no acceptance criteria (Test Plan)**: generate test cases based on reasonable interpretation, flag each with `⚠️ Acceptance criteria not defined — test cases based on interpretation`, and list the assumptions made.

**Requirement has no observable system behavior** (e.g., a pure internal implementation requirement): generate test cases that verify the external effects of the internal behavior (e.g., performance, correctness of output, absence of side effects).

**Large PRD (10+ requirements)**: process in batches of 5 and report progress — "Processing requirements 1–5 of 14…"
