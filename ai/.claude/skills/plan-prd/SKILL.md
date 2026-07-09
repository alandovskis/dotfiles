---
name: plan-prd
description: |-
  Reads a PRD from a Confluence page and generates a Software Design Document
  and/or a System Test Plan, using a generator-reviewer loop per requirement
  for each. Publishes the assembled document(s) to Confluence under a
  user-specified space and parent page.
  Trigger when user says: "generate an SDD from a Confluence PRD", "convert PRD
  to SDD", "create a software design document from requirements", "write a design
  doc from a Confluence page", "generate a test plan from a Confluence PRD",
  "create a system test plan from requirements", "convert PRD to test plan",
  "write a test plan from a Confluence page", "/plan-prd", "/prd-to-sdd",
  "/prd-to-test-plan", or asks to turn a PRD into a design doc, a test plan, or both.
---

You are turning a Confluence PRD into a Software Design Document (SDD), a System Test Plan, or both. For each requirement, run an internal generator-reviewer loop per selected artifact to produce a high-quality section, then publish the assembled document(s) back to Confluence. Follow the steps below precisely.

## Step 1: Resolve cloud ID and choose source PRD

**1a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**1b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter — omitting it returns all spaces including collaboration spaces. Present every returned space to the user via AskUserQuestion and ask them to choose the space that contains the PRD.

**1c. Choose the PRD page** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. Present every returned page title to the user via AskUserQuestion and ask them to choose the PRD. If the space has more pages than fit in one response, paginate until all pages are listed before presenting.

**1d. Fetch the PRD** — use the selected page's `id` as `pageId`. Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

## Step 2: Choose what to generate

Ask the user via AskUserQuestion which artifact(s) to generate:
- **Software Design Document**
- **System Test Plan**
- **Both**

This choice gates which parts of Steps 3, 5, 6, and 7 run below.

## Step 3: Choose destination(s)

**3a. Single artifact selected** — ask the user via AskUserQuestion whether to publish to the same space as the PRD or a different one. If the same space, re-use the space `id` already resolved. If a different space, call `getConfluenceSpaces` again (no type filter) and present the list. Then call `getPagesInConfluenceSpace` with the destination space `id` and present every returned page title via AskUserQuestion so the user can choose the parent page (include "space root" as an explicit option). Store the resolved `spaceId` and `parentId`.

**3b. Both artifacts selected** — ask the user via AskUserQuestion whether the SDD and Test Plan should publish to the same space/parent page or to different ones.
- **Same** — resolve one destination as in 3a and store it as `spaceId`/`parentId`, used for both documents.
- **Different** — resolve a destination as in 3a for the SDD (`sddSpaceId`/`sddParentId`), then resolve a second destination the same way for the Test Plan (`tpSpaceId`/`tpParentId`).

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
> "I found [N] requirements: [list with UI Component: Yes/No]. Shall I generate the [SDD / test plan / SDD and test plan]?"

If the document has no identifiable requirements, tell the user and stop.

## Step 5: Generator-reviewer loops

For **each requirement**, run the loop(s) below for each artifact type chosen in Step 2. The two loops are independent of each other — run whichever apply, in either order.

### Step 5A: SDD loop — one section per requirement

*Run only if the SDD (or Both) was selected in Step 2.*

#### Pass 1 — Generator

Draft the SDD section. Write from the perspective of an experienced software architect. Use concrete language — no "could", "might", or "should consider". Every sub-section below must be populated; write "N/A — [reason]" if it genuinely does not apply.

If the requirement has `UI Component: Yes`, include a UI mockup that follows the extracted design-system context. The mockup must be concrete enough for engineering and design review: show layout, visible states, primary controls, empty/loading/error states where relevant, and the design-system components/tokens being used. Use Mermaid, ASCII wireframe, Markdown table, or concise HTML/CSS-style pseudomarkup that can survive Confluence publishing. If the PRD does not name a design system, state the assumed design-system baseline before the mockup and use common accessible product UI conventions.

Section structure:

**Requirement Summary** — verbatim or paraphrased requirement text.

**Design Approach** — 2–4 paragraphs: chosen design and why, key architectural patterns, integration points with existing systems. Include an "Alternatives considered" table (approach vs. reason rejected).

**UI Mockup** — for `UI Component: Yes`, include a requirement-specific mockup following the design system; for `UI Component: No`, write "N/A — no user-facing UI component."

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
> - If UI Component is Yes, the section includes a **UI Mockup** that follows the design-system context and shows layout, primary controls, and relevant states
> - If UI Component is No, the **UI Mockup** section explicitly says "N/A — no user-facing UI component."
>
> **Should pass** (flag if 2 or more fail):
> - At least one alternative considered and rejected with a concrete reason
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

*Run only if the System Test Plan (or Both) was selected in Step 2.*

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

---

## Step 6: Assemble the document(s)

### Step 6A: Assemble the SDD

*Run only if the SDD was generated in Step 5A.*

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

*Run only if the Test Plan was generated in Step 5B.*

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

---

## Step 7: Publish to Confluence

Convert each assembled document to HTML. Use `<h2>`, `<h3>` for headings, `<table>`/`<thead>`/`<tbody>`/`<tr>`/`<th>`/`<td>` for tables, `<pre><code class="language-...">` for code blocks, `<ul>`/`<ol>`/`<li>` for lists, `<strong>` for bold. Do not wrap content in `<html>`, `<head>`, or `<body>` tags.

**7a. Publish the SDD** *(if generated)* — use the `spaceId`/`parentId` resolved in Step 3 (or `sddSpaceId`/`sddParentId` if separate destinations were chosen). Call `createConfluencePage` with:
- `cloudId`
- `spaceId`, `parentId` (omit `parentId` if the user chose space root)
- `title` — `"SDD: [PRD title]"`
- `body` — assembled SDD as HTML
- `contentFormat` — `"html"`
- `status` — `"draft"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user if they want a new page with a date suffix: `SDD: [PRD title] (YYYY-MM-DD)`.

**7b. Publish the Test Plan** *(if generated)* — use the `spaceId`/`parentId` resolved in Step 3 (or `tpSpaceId`/`tpParentId` if separate destinations were chosen). Call `createConfluencePage` with:
- `cloudId`
- `spaceId`, `parentId` (omit `parentId` if the user chose space root)
- `title` — `"Test Plan: [PRD title]"`
- `body` — assembled test plan as HTML
- `contentFormat` — `"html"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user whether they want a date-suffixed title: `Test Plan: [PRD title] (YYYY-MM-DD)`.

On success, report every page published:
> "✅ SDD published: [Confluence page URL]"
> "✅ Test plan published: [Confluence page URL]"

## Edge cases

**No explicit requirements section**: infer requirements from feature descriptions or user stories; group related items and confirm the grouping with the user before proceeding.

**Vague requirement (SDD)**: generate the section with best effort, flag `⚠️ Insufficient detail — design decisions deferred`.

**Vague requirement with no acceptance criteria (Test Plan)**: generate test cases based on reasonable interpretation, flag each with `⚠️ Acceptance criteria not defined — test cases based on interpretation`, and list the assumptions made.

**Requirement has no observable system behavior** (e.g., a pure internal implementation requirement): generate test cases that verify the external effects of the internal behavior (e.g., performance, correctness of output, absence of side effects).

**Large PRD (10+ requirements)**: process in batches of 5 and report progress — "Processing requirements 1–5 of 14…"
