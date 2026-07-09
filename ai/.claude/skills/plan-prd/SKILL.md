---
name: plan-prd
description: |-
  Reads a PRD from a Confluence page and always generates all three planning
  artifacts: a Software Design Document, System Test Plan, and autonomous
  Implementation Plan with task breakdown. Uses a generator-reviewer loop per
  requirement for each artifact and publishes the assembled documents to
  Confluence under a user-specified space and parent page.
  Trigger when user says: "generate an SDD from a Confluence PRD", "convert PRD
  to SDD", "create a software design document from requirements", "write a design
  doc from a Confluence page", "generate a test plan from a Confluence PRD",
  "create a system test plan from requirements", "convert PRD to test plan",
  "write a test plan from a Confluence page", "create an implementation plan
  from a PRD", "break a PRD into implementation tasks", "/plan-prd",
  "/prd-to-sdd", "/prd-to-test-plan", or asks to turn a PRD into a design doc,
  a test plan, an implementation plan, implementation tasks, or planning
  artifacts. Always generate all three even if the user names only one.
---

You are turning a Confluence PRD into three artifacts every time: a Software Design Document (SDD), a System Test Plan, and an autonomous Implementation Plan. For each requirement, run an internal generator-reviewer loop for every artifact to produce high-quality sections, then publish the assembled documents back to Confluence. Follow the steps below precisely.

## Step 1: Resolve cloud ID and choose source PRD

**1a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**1b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter — omitting it returns all spaces including collaboration spaces. Present every returned space to the user via AskUserQuestion and ask them to choose the space that contains the PRD.

**1c. Choose the PRD page** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. Present every returned page title to the user via AskUserQuestion and ask them to choose the PRD. If the space has more pages than fit in one response, paginate until all pages are listed before presenting.

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

Destination-resolution procedure: ask whether to publish to the same space as the PRD or a different one. If the same space, re-use the PRD space `id`. If a different space, call `getConfluenceSpaces` again (no type filter) and present the list. Then call `getPagesInConfluenceSpace` with the destination space `id` and present every returned page title via AskUserQuestion so the user can choose the parent page (include "space root" as an explicit option). Store the resolved destination space and parent IDs using the variable names required by the selected same/different destination mode.

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

Also extract any design-system context from the PRD, including:
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

Draft the SDD section. Write from the perspective of an experienced software architect. Use concrete language — no "could", "might", or "should consider". Every sub-section below must be populated; write "N/A — [reason]" if it genuinely does not apply.

If the requirement has `UI Component: Yes`, include a UI mockup that follows the extracted design-system context. The mockup must be concrete enough for engineering and design review: show layout, visible states, primary controls, empty/loading/error states where relevant, and the design-system components/tokens being used. Use Mermaid, ASCII wireframe, Markdown table, or concise HTML/CSS-style pseudomarkup that can survive Confluence publishing. If the PRD does not name a design system, state the assumed design-system baseline before the mockup and use common accessible product UI conventions.

Include Mermaid diagrams where they clarify the design. Use them for architecture flows, sequence diagrams, state machines, entity relationships, data pipelines, deployment topology, or decision workflows when prose or tables alone would be harder to review. Do not force a diagram for trivial requirements. Mermaid diagrams must be fenced code blocks with `mermaid` as the language and must have a short lead-in sentence explaining what the diagram shows.

Section structure:

**Requirement Summary** — verbatim or paraphrased requirement text.

**Design Approach** — 2–4 paragraphs: chosen design and why, key architectural patterns, integration points with existing systems. Include an "Alternatives considered" table (approach vs. reason rejected).

**Diagrams** — include one or more Mermaid diagrams when useful; otherwise write "N/A — diagram would not clarify this requirement."

**UI Mockup** — for `UI Component: Yes`, include a requirement-specific mockup following the design system; for `UI Component: No`, write "N/A — no user-facing UI component."

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

> You are a critical senior software engineer reviewing a draft SDD section. Your only job is to find gaps — do not rewrite the section yourself.
>
> **Requirement:**
> [requirement ID, title, full description, and UI Component: Yes/No]
>
> **Design-system context:**
> [design links, design section notes, component library, style guide, accessibility rules, platform conventions, or "not specified"]
>
> **Draft SDD section:**
> [full draft text]
>
> Review against these criteria:
>
> **Must pass** (flag any failure):
> - Requirement is fully addressed — trace every clause of the requirement text
> - No empty sections (only "N/A — reason" is acceptable)
> - No internal contradictions
> - No unowned TBDs
> - Mermaid diagrams are included where they would clarify non-trivial architecture, data relationships, lifecycle/state transitions, async flows, or review workflows; omitted diagrams have an explicit "N/A — diagram would not clarify..." reason
> - If UI Component is Yes, the section includes a **UI Mockup** that follows the design-system context and shows layout, primary controls, and relevant states
> - If UI Component is No, the **UI Mockup** section explicitly says "N/A — no user-facing UI component."
>
> **Should pass** (flag if 2 or more fail):
> - At least one alternative considered and rejected with a concrete reason
> - Mermaid diagrams use fenced `mermaid` code blocks and are valid enough for Confluence readers to understand without external explanation
> - Error table covers all five required conditions (400, 403, 404, 409, 503)
> - Schema changes include constraints and migration strategy
> - Security checklist covered (auth, validation, PII)
> - Test scenarios cover happy path, at least one error path, and one edge case
> - UI mockups identify the design-system components or tokens used, or clearly state the design-system assumption when none is specified
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

> You are a QA engineer writing system-level test cases. Return only the test cases in the exact format specified — no explanation or preamble.
>
> **Requirement**
> ID: [REQ-ID] — [Title]
> Description: [full requirement text including acceptance criteria and notes]
>
> **System context**
> [2–3 sentences from the PRD: what the system does, the tech stack, and any success metrics stated for this requirement]
>
> **Instructions**
> Write 2–6 test cases covering ALL of the following types. Types 1–4 are always required. Type 5 is required only when the requirement or success metrics state a measurable target (latency, throughput, success rate, time window); otherwise write one line: "Performance: No measurable target defined — omitted."
>
> 1. Happy path — valid, normal inputs; system behaves correctly.
> 2. Boundary / edge case — inputs at valid-range limits (empty collections, maximum sizes, minimum values, exact threshold values).
> 3. Negative / invalid input — system rejects or handles invalid inputs gracefully.
> 4. Error / failure path — system recovers from a downstream failure, missing dependency, or infrastructure fault.
> 5. Performance — specify: load profile (N concurrent users or req/s), acceptance threshold (e.g. p95 < 2 s, error rate < 1 %), and recommended tool (k6 / wrk / locust).
>
> For every test case use exactly this format:
>
> **TC-[REQ_ID]-[N]**
> - **Title**: [short imperative phrase]
> - **Type**: Happy path | Boundary | Negative | Error path | Performance
> - **Preconditions**: [specific named DB records, config values, mock responses — never "the system is configured correctly"]
> - **Steps**: [numbered; one action per step; unambiguous subject, e.g. "The test runner calls POST /api/v1/…"]
> - **Expected result**: [exact HTTP status, DB state change, log entry, or UI state — never "returns success"]
> - **Pass criteria**: [one-line PASS/FAIL condition]
>
> Use concrete values throughout. Not "a valid URL" — use the actual example URL. Not "returns an error" — state the exact status code and body shape.

Store the agent's output as `draft`.

#### Agent 2 — Reviewer

Launch a fresh agent with this prompt. Pass only the requirement and `draft` — do not include any generation reasoning or prior context:

> You are a QA lead reviewing test cases written by someone else. Do not write new test cases. Only evaluate the draft provided.
>
> **Requirement**
> ID: [REQ-ID] — [Title]
> Description: [full requirement text including acceptance criteria and notes]
>
> **Draft test cases**
> [draft]
>
> **Must pass** — output REVISE if any of these fail:
> - Happy path, boundary, negative, and error-path types are all present.
> - Performance type is present if and only if the requirement contains a measurable target; missing with a target defined is a failure; present with no target defined is also a failure.
> - Every clause of the requirement description and every stated acceptance criterion is covered by at least one test case.
> - No precondition is vague ("the system is set up correctly" fails this check).
> - No expected result is vague ("the operation succeeds" fails this check).
> - All pass criteria are binary PASS/FAIL, not subjective.
>
> **Should pass** — output REVISE if 2 or more of these fail:
> - Preconditions name specific data values, not categories.
> - Steps can be executed by someone unfamiliar with the codebase.
> - Error-path cases name the exact failure injected (e.g. "mock returns HTTP 503").
> - Boundary cases state the exact boundary value under test.
> - Each test case is independent — no test requires another to have run first.
>
> Output exactly one of:
> - `APPROVED` (one optional sentence of commentary)
> - `REVISE:` followed by a numbered list where each item is: `[TC-ID or "missing case"] — [specific problem and exactly what to add or fix]`

Store the agent's output as `review`.

#### Agent 3 — Revision (only if `review` starts with `REVISE`)

Launch a fresh agent with this prompt:

> You are a QA engineer revising test cases based on reviewer feedback. Return the complete revised set — all original test cases with corrections applied, plus any new cases the feedback requires. Use the same format as the original draft.
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
> Apply every numbered item in the feedback exactly. Do not add cases beyond what the feedback requires.

Store the output as `revised_draft`. Then re-run Agent 2 (reviewer) against `revised_draft`.

**Termination:**
- Either review returns `APPROVED` → use those test cases as the final output for this requirement.
- Second review still returns `REVISE` → accept `revised_draft` as-is; prepend `⚠️ Needs Human Review: [paste the outstanding reviewer items]` to the test case block for this requirement.
- Maximum 2 revision rounds. Never loop further.

### Step 5C: Implementation Plan loop — one task group per requirement

*Always run.*

#### Pass 1 — Generator

Draft an implementation task group for the requirement. Write tasks that an AI coding agent can execute without rereading the PRD and without asking the user follow-up questions. Use concrete language and include dependency order, validation gates, acceptance criteria, expected files/modules/interfaces where inferable, and explicit assumptions for any PRD gap. Do not create vague tasks such as "implement backend" or "add tests".

The implementation plan must be autonomous-execution ready:
- Do not leave "ask user", "TBD", "decide later", "confirm approach", or unowned discovery as implementation blockers.
- If the PRD lacks a detail, choose a conservative implementation assumption, label it, and add a verification task that can prove or disprove it without user intervention.
- Every task must state the concrete output an AI should produce: code, schema migration, API contract, UI state, test, fixture, config, documentation, or rollout change.
- Every task must include enough context to implement safely: target component/module, input/output contract, data shape, error behavior, permissions, and validation command when applicable.
- Tasks may reference SDD/Test Plan sections when generated, but must still stand alone if those artifacts are unavailable.

Each requirement task group must include:

**Requirement Summary** — requirement ID, title, and short implementation goal.

**Implementation Strategy** — 1–3 paragraphs explaining sequencing, ownership boundaries, architecture dependencies, and rollout approach.

**Task Breakdown** — table with columns: Task ID | Task | Type | Target Files / Modules | Owner Role | Dependencies | Estimate | Acceptance Criteria | Validation. Task IDs must be stable and requirement-scoped, e.g. `IMP-REQ-001-01`. Types must be one of: Discovery, Backend, Frontend, Data, Infrastructure, Testing, Security, Documentation, Release. Discovery tasks must produce repo-local artifacts or decisions and cannot require user input.

**Execution Order** — numbered list of task IDs in dependency order, grouped into milestones when useful.

**Parallelizable Work** — list task IDs that can run in parallel and note what shared interfaces or contracts must be agreed first.

**Testing and Verification Tasks** — include at least one unit/integration/system verification task, and link each to SDD design areas or Test Plan cases when those artifacts are also generated.

**Autonomous Execution Notes** — list implementation assumptions, inferred defaults, repo discovery commands, validation commands, required fixtures, feature flags, environment variables, and rollback commands. This section must make clear how an AI agent should proceed if it encounters missing optional context.

**Release / Migration Tasks** — data migrations, feature flags, backfills, rollout, monitoring, rollback, and documentation tasks. If none: "N/A — no release or migration tasks required."

**Risks and Blockers** — table: Risk/Blocker | Impact | Mitigation | Owner | Target Date. Include open PRD questions that block implementation.

#### Pass 2 — Reviewer

Spawn a subagent using the Agent tool with the following prompt:

> You are a critical engineering manager reviewing an implementation plan task group. Your only job is to find planning gaps — do not rewrite the plan yourself.
>
> **Requirement:**
> [requirement ID, title, full description, and UI Component: Yes/No]
>
> **Draft implementation task group:**
> [full draft text]
>
> Review against these criteria:
>
> **Must pass** (flag any failure):
> - Every material clause of the requirement is represented by at least one task
> - The task group is suitable for an AI coding agent to implement without user intervention: no "ask user", unowned TBDs, unresolved choices, or vague discovery blockers remain
> - Missing PRD details are handled with explicit conservative assumptions plus verification tasks, not deferred to the user
> - Task breakdown has stable task IDs, target files/modules where inferable, concrete owners by role, dependencies, estimates, acceptance criteria, and validation commands
> - Execution order is coherent and no task depends on work that appears later without being declared
> - Testing/verification work is explicit and not collapsed into implementation tasks
> - Release, migration, feature flag, monitoring, rollback, or documentation work is included where relevant, or explicitly marked N/A with a reason
> - Risks/blockers have owners and target dates
>
> **Should pass** (flag if 2 or more fail):
> - Tasks are small enough to become Jira stories or sub-tasks
> - Tasks state concrete code/data/config/doc outputs rather than activities
> - Parallelizable work is identified
> - Estimates are plausible relative sizes such as S/M/L or day ranges
> - Cross-artifact references to SDD/Test Plan are included when those artifacts are generated
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
| Task ID | Requirement | Task | Type | Target Files / Modules | Owner Role | Dependencies | Estimate | Acceptance Criteria | Validation | Status |
|---------|-------------|------|------|------------------------|------------|--------------|----------|---------------------|------------|--------|
| IMP-REQ-001-01 | REQ-001 | ... | Backend | src/... | Backend Engineer | — | M | ... | ... | Draft |

---
[REQ-001 implementation task group]
---
[REQ-002 implementation task group]
...

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
