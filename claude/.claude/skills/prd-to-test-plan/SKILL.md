---
name: prd-to-test-plan
description: |-
  Reads a PRD from a Confluence page and generates a System Test Plan using a
  generator-reviewer loop: one test-case group per requirement. Publishes the
  assembled test plan to Confluence under a user-specified space and parent page.
  Trigger when user says: "generate a test plan from a Confluence PRD",
  "create a system test plan from requirements", "convert PRD to test plan",
  "write a test plan from a Confluence page", "/prd-to-test-plan", or asks to
  turn a PRD into a test plan or QA plan.
---

You are generating a System Test Plan from a Confluence PRD. For each requirement, run an internal generator-reviewer loop to produce thorough, specific test cases, then publish the assembled plan back to Confluence. Follow the steps below precisely.

## Step 1: Gather inputs

If the user has not already provided both of the following, use AskUserQuestion to ask:

1. **PRD source** — Confluence page URL or page ID
2. **Test plan destination** — Confluence space key and parent page title or URL (e.g. space: `ENG`, parent: `Test Plans/2024`)

## Step 2: Resolve cloud ID

Call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

## Step 3: Fetch the PRD

Extract the page ID from the URL:
- Tiny link: `/wiki/x/<ID>` — use `<ID>` directly
- Long format: `/wiki/spaces/<SPACE>/pages/<ID>/...` — use the numeric `<ID>`

Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

## Step 4: Extract requirements

Parse the PRD content for individual requirements (table, numbered list, or section headings). For each requirement, record:
- **ID** — existing identifier or auto-generated (REQ-001, REQ-002…)
- **Title** — short label
- **Description** — full requirement text including any acceptance criteria and notes

Present the list to the user and confirm before generating:
> "I found [N] requirements: [list]. Shall I generate the test plan?"

If the document has no identifiable requirements, tell the user and stop.

## Step 5: Generator-reviewer loop — one group per requirement

For **each requirement**, launch three independent subagents using the Agent tool. Each agent is started fresh (not a fork) so the reviewer has no memory of the generation reasoning — giving genuinely independent feedback.

### Agent 1 — Generator

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

### Agent 2 — Reviewer

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

### Agent 3 — Revision (only if `review` starts with `REVISE`)

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

## Step 6: Assemble the test plan

After generating all test cases across all requirements, reorganize them by test type. Each test case belongs to exactly one top-level section based on its **Type** field:

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

### Resolve the space ID

Call `getConfluenceSpaces` with `cloudId` and `keys: [user-provided space key]`. Use the returned `id` field as `spaceId`. (`createConfluencePage` requires a numeric space ID, not the space key string.)

### Resolve the parent page ID

Call `search` with the parent page title, or call `getConfluencePage` if the user provided a URL, to obtain the numeric parent page ID.

### Create the page

Call `createConfluencePage` with:
- `cloudId`
- `spaceId` — numeric ID from `getConfluenceSpaces`
- `parentId` — numeric ID of the parent page
- `title` — `"Test Plan: [PRD title]"`
- `body` — assembled test plan as HTML
- `contentFormat` — `"html"`

Convert the assembled document to HTML. Use `<h2>`, `<h3>` for headings, `<table>`/`<thead>`/`<tbody>`/`<tr>`/`<th>`/`<td>` for tables, `<pre><code class="language-...">` for code blocks, `<ul>`/`<ol>`/`<li>` for lists, `<strong>` for bold. Do not wrap content in `<html>`, `<head>`, or `<body>` tags.

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user whether they want a date-suffixed title: `Test Plan: [PRD title] (YYYY-MM-DD)`.

On success:
> "✅ Test plan published: [Confluence page URL]"

## Edge cases

**No explicit requirements section**: infer requirements from feature descriptions or user stories; confirm grouping with user before proceeding.

**Requirement has no observable system behavior** (e.g., a pure internal implementation requirement): generate test cases that verify the external effects of the internal behavior (e.g., performance, correctness of output, absence of side effects).

**Large PRD (10+ requirements)**: process in batches of 5 and report progress — "Processing requirements 1–5 of 14…"

**Vague requirement with no acceptance criteria**: generate test cases based on reasonable interpretation, flag each with `⚠️ Acceptance criteria not defined — test cases based on interpretation`, and list the assumptions made.
