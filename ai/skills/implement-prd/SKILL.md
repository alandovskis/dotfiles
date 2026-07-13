---
name: implement-prd
description: |-
  Reads an autonomous Implementation Plan from Confluence — the artifact produced
  by /plan-prd — and implements the described system test-first using two
  planner-generator-reviewer loops: Loop A turns the plan's Test Plan
  Implementation Breakdown into executable tests; Loop B implements the Task
  Breakdown gated by unit tests and integration tests. The Implementation Plan
  is the only input; this skill does not read the SDD or Test Plan documents.
  After implementation, publishes an implementation report to Confluence as a
  child of the source Implementation Plan.
  Trigger when user says: "implement the implementation plan", "implement from
  the implementation plan", "code up this implementation plan", "build from the
  Confluence implementation plan", "/implement-prd", "/implement-prd --resume",
  or asks to turn an
  implementation plan into working code and verify it with tests.
---

Implement production code from a Confluence Implementation Plan, test-first. It is the **only** input — the plan is designed to stand alone, so don't fetch or depend on any SDD or Test Plan generated alongside it. Launch **two parallel planner-generator-reviewer loops**: Loop A implements the plan's Test Plan Implementation Breakdown as executable code; Loop B implements the Task Breakdown, gated by unit and integration tests. Follow these steps precisely.

**Host and connector independence:** Use the current host's equivalent interaction, delegation, filesystem, shell, and Confluence connector capabilities. Names such as `getConfluencePage` describe the required Confluence operation, not a required host-specific tool name. If a host cannot delegate, use the isolated-pass fallback described in the loop instructions.

## Invocation

Use `/implement-prd` for a new run. Use `/implement-prd --resume [target-directory]` to continue an interrupted run; when the optional target directory is omitted, use the current working directory. `--resume=<target-directory>` is equivalent. Reject any other option or positional argument rather than guessing its meaning.

Resume mode continues the exact plan recorded in `IMPLEMENTATION_CHECKLIST.md`; it does not start a new implementation or silently substitute another Confluence page.

> **Don't do — stubs in production code.** Never write stub implementations (`pass`, `TODO`, `raise NotImplementedError`, `return 501`, empty function bodies) in Loop B production code. If a task can't be fully implemented because the plan is ambiguous or a dependency is missing, stop and surface the blocker instead of shipping a partial implementation that merely compiles.

> **Don't do — xfail markers.** Never use `@pytest.mark.xfail`, `test.failing`, `xit`, `xtest`, or any other expected-failure mechanism. Loop A tests must fail outright, not xfail, because they exercise production code that doesn't exist yet; Loop B tests must pass. xfail masks real gaps and defeats the test gate.

## Step 0: Establish the test gate

Before doing anything else, identify the E2E or system-test command from the Implementation Plan or repository. Run it before the final summary and after any change that could invalidate it. If the host supports temporary lifecycle automation, it may be configured only with the user's approval and must be removed before the run ends. Do not create or modify host-specific configuration files merely to register a lifecycle hook.

## Step 1: Gather inputs and detect resume mode

For a new run, if the user has not already provided the following, use the host's user-interaction mechanism to ask:

1. **Target directory** — local path where code will be written (default: current working directory)
2. **Language / stack** — if not inferable from the Implementation Plan's Target Files / Modules columns, ask which language/framework to use

Do not ask for the Implementation Plan source — you will look it up from Confluence in Step 2. Do not ask about or reference an SDD or Test Plan document.

For `--resume`:

1. Resolve the target directory from the option or current working directory.
2. Read `<target-directory>/IMPLEMENTATION_CHECKLIST.md` before asking any question. If it is missing, stop: `--resume requires IMPLEMENTATION_CHECKLIST.md; run /implement-prd first or provide the correct target directory.`
3. Read the required `Source Implementation Plan` and `Target directory` metadata. If either is absent, or the recorded target differs from the resolved target after path normalization, stop and ask the user to repair the checklist or start a new run.
4. Infer language/stack from the existing repository and plan. Ask only if it cannot be inferred.

## Step 2: Resolve cloud ID, fetch the Implementation Plan

**2a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**2b. Choose the space** — for a new run, call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter. Present every returned space using the host's user-interaction mechanism and ask the user to choose the one containing the Implementation Plan. For `--resume`, extract the Confluence page ID from the checklist's `Source Implementation Plan` link and skip space selection. If the link does not contain a usable page ID, fall back to the new-run space/page selection flow and ask the user to confirm the matching page.

**2c. Choose the page** — for a new run (or resume fallback), call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. If there are more pages than fit in one response, paginate until all are listed. Present the full page list and ask the user to identify the **Implementation Plan** page (title typically "Implementation Plan: …"). Do not ask about SDD or Test Plan pages. In normal resume mode, use the extracted page ID directly.

**2d. Fetch the page** — call `getConfluencePage` for the Implementation Plan page with `contentFormat: "markdown"`.

## Step 3: Extract tasks and test objectives

Parse the Implementation Plan document for these sections (as produced by /plan-prd):

**From the Task Summary / Task Breakdown tables**, parse implementable units. Tables are grouped first by requirement (`### REQ-...`), then by Owner Role within each requirement (`##### [Role]`, e.g. Backend Engineer, Frontend Engineer, QA Engineer). For each row record: **Task ID** (e.g. `IMP-REQ-001-01`), **Requirement** and **Owner Role** (from the enclosing headings), **Task**, **Type** (Discovery | Backend | Frontend | Data | Infrastructure | Testing | Security | Documentation | Release), **Target Files / Modules**, **Dependencies**, **Acceptance Criteria**, **Validation**. Preserve this grouping when presenting or batching tasks — the Execution Order section, not this grouping, is authoritative for build sequencing.

**From the Execution Order section**, record the dependency-ordered task ID sequence and any milestone groupings. Use this as the authoritative build order, cross-checked against the Dependencies column.

**From the Parallelizable Work section**, record which task IDs may be implemented concurrently and what shared interfaces/contracts must be agreed first.

**From the Test Plan Implementation Breakdown section**, parse test objectives. For each row record: **Test Case ID** (e.g. `TC-REQ001-1`), **Test Objective**, **Supporting Code / Fixture / Harness Work**, **Implementation Task IDs** (the Task IDs it depends on / verifies), **Validation**.

**From the Autonomous Execution Contract section**, record: repository discovery commands, validation commands (unit, integration, lint, typecheck, migration, smoke-test), feature flags/config/env vars, and the fallback rule for missing optional context.

**From the Release Plan section**, record migration, feature-flag, backfill, rollout, monitoring, rollback, and documentation tasks not already captured as `Release`-type rows in the Task Breakdown.

For a new run, present a summary to the user and confirm before proceeding:

> "Found [N] tasks across [M] requirements and [K] test objectives. Shall I implement both in [target directory]?"

**Write or validate the implementation checklist.** For a new run, create `IMPLEMENTATION_CHECKLIST.md` in the target directory with one unchecked item per test objective and per task, grouped exactly like the source document:

```markdown
# Implementation Checklist: [Implementation Plan title]

**Source Implementation Plan:** [Confluence link]
**Target directory:** [path]

## REQ-001 — [Title]

### Loop A — Test Plan Implementation Breakdown
- [ ] TC-REQ001-1 — [Test Objective]
- [ ] TC-REQ001-2 — [Test Objective]

### Loop B — Task Breakdown
#### Backend Engineer
- [ ] IMP-REQ-001-01 — [Task]
#### Frontend Engineer
- [ ] IMP-REQ-001-02 — [Task]

## REQ-002 — [Title]
...

## System Tests (Loop A suite vs. Loop B production code)
- [ ] TC-REQ001-1
- [ ] TC-REQ001-2
...
```

This file is the single source of truth for run progress. Update it incrementally — never batch updates or regenerate it from scratch — at every point called out in Steps 4 and 5 below, so prior progress is never lost. Checkbox states:
- `- [ ]` — not started or not yet passing
- `- [x]` — clean pass (reviewer approved, tests green)
- `- [ ] ⚠️ [reason]` — accepted with `Needs Human Review` / `unresolved` after the maximum revision rounds; left **unchecked** so outstanding work stays visible even though the loop moved on

For `--resume`, do not rewrite or add duplicate checklist entries. Validate that the fetched plan has exactly one matching checklist entry for every Task ID, one Loop A entry for every Test Case ID, and one System Tests entry for every Test Case ID. If IDs are missing, duplicated within a section, or the source link resolves to a different plan, stop and report the mismatch. Treat `- [x]` as complete; treat every unchecked or `⚠️` item as pending. Present the resume summary and continue without a new-run confirmation:

> "Resuming [plan title] in [target directory]: [C] complete, [P] pending ([T] test objectives, [K] tasks). Next item: [ID]."

Resume in the source document's Execution Order. Complete pending Loop A objectives before pending Loop B tasks. If all Loop A and Loop B items are checked but any System Tests are pending, go directly to B4. Before skipping any checked Loop B task, run its recorded validation command when available; if it fails, uncheck that task, append the failure reason, and resume it rather than trusting stale state.

---

## Step 4: Loop A — Implement the Test Plan Implementation Breakdown as executable code

Read `references/loop-a.md` now and follow it completely (A1 Planner → A2 Generator → A3 Reviewer → A4 Confirm compilation). Loop A must finish before Loop B starts.

## Step 5: Loop B — Implement the Task Breakdown as production code

Read `references/loop-b.md` now and follow it completely (B1 Planner → B2 Task execution pass, one per task, containing its own generate → review → test-fix cycle → B3 Record result and commit → B4 Full system test run).

---

## Step 6: Assemble and publish the implementation report

Confirm `IMPLEMENTATION_CHECKLIST.md` reflects the final state of every item (do not delete it — it is the durable record of this run). Assemble this concise implementation report:

```
## Implementation complete

**Source Implementation Plan:** [Confluence link]
**Target directory:** [path]

### Loop A — Test Plan Implementation Breakdown

[N] test objectives → [N] executable tests written across [F] files.
Loop A result: [N] compiled, all failing before production code (expected).

### Loop B — Task Breakdown implementation

| Task ID | Task | Type | Unit | Integration | Status | Files |
|---------|------|------|------|-------------|--------|-------|
| IMP-REQ-001-01 | accounts table migration | Data | 4/4 | 2/2 | ✅ | db/schema.sql |
| IMP-REQ-001-02 | StatusNormaliser | Backend | 7/7 | 3/3 | ✅ | src/normaliser.py |
| IMP-REQ-002-01 | POST /timeline | Backend | 5/5 | 4/4 | ⚠️ Needs Human Review | src/routes/timeline.py |

### System tests (Loop A suite against Loop B production code)

**Final:** [P] passing / [F] failing

| Test Case ID | Requirement | Status |
|-------|-------------|--------|
| TC-REQ001-1 | REQ-001 | ✅ |
| TC-REQ001-4 | REQ-001 | ✅ |
| TC-REQ003-5 | REQ-003 | ⚠️ System test unresolved |

### Outstanding issues
- IMP-REQ-002-01: [specific gap from reviewer]
- TC-REQ003-5: [error output]

### Next steps
- [ ] Resolve ⚠️ items above
- [ ] Wire up to CI pipeline (unit, integration, system test stages)
- [ ] Complete Release Plan tasks (migrations, flags, rollout, monitoring) if not yet executed
```

Convert the assembled report to Confluence HTML. Use `<h2>` and `<h3>` for headings, `<table>`/`<thead>`/`<tbody>`/`<tr>`/`<th>`/`<td>` for tables, `<ul>`/`<li>` for lists, `<strong>` for bold, and `<code>` for commands, paths, and IDs. Do not wrap the content in `<html>`, `<head>`, or `<body>` tags.

Publish the report in the same Confluence space as the source Implementation Plan and make it a child of that plan. Call `createConfluencePage` with:

- `cloudId` — resolved in Step 2
- `spaceId` — from the fetched source Implementation Plan
- `parentId` — the source Implementation Plan page ID
- `title` — `"Implementation Report: [Implementation Plan title without the \"Implementation Plan: \" prefix]"`
- `body` — the assembled report as HTML
- `contentFormat` — `"html"`

If a child page with that title already exists, update it with `updateConfluencePage` so resumed or repeated runs keep one durable report; do not create a duplicate or date-suffixed page. Preserve the existing page's required version metadata when the connector requires it.

Confluence publication is part of completion. If creating or updating the report fails, retry after refreshing the source page, destination page, and required version metadata. If it still fails, report the error and do not claim the run is complete.

After publication succeeds, present the same concise report to the user and include:

> "✅ Implementation report published: [Confluence page URL]"

---

## Edge cases

**No Test Plan Implementation Breakdown section found**: derive test scaffolding directly from each task's Acceptance Criteria and Validation columns instead; note the gap and flag Loop A output as needing review against a formal test breakdown.

**No Task Breakdown / Task Summary table found**: the Implementation Plan is unusable as the sole input — stop and tell the user the page does not contain a Task Breakdown, and ask them to confirm they selected the correct Confluence page.

**Task Breakdown has no Testing-type rows**: derive unit and integration tests from each task's Acceptance Criteria and Validation columns only; note the gap.

**Monorepo / multi-service plan**: ask the user which requirement group(s) / milestone(s) to implement; scope both loops to those only.

**Task specifying infrastructure (Docker, Terraform, CI)**: implement config files in Loop B following the same generator → reviewer loop; verify by linting (`terraform validate`, `docker build`, `yamllint`) rather than unit/integration tests; Loop A skips pure-infra tasks.

**Conflicting Implementation Plan and existing code**: surface the conflict explicitly, ask the user which takes precedence before writing.

**Large plan (10+ tasks)**: process Loop B in batches of 5 following the Execution Order, report progress after each batch, and confirm before continuing. Loop A processes all test objective groups up front.

**Resume requested but no checklist exists**: stop with the `--resume requires IMPLEMENTATION_CHECKLIST.md` message from Step 1. Do not create an empty checklist or begin a new run.

## Additional resources

- **`references/loop-a.md`** — Step 4 in full: A1–A4, including the A3 reviewer prompt
- **`references/loop-b.md`** — Step 5 in full: B1–B4. Each task's generate/review/test-fix cycle runs in a fresh, isolated per-task execution pass so the main thread only keeps a one-line result per task
- **`references/implementation-patterns.md`** — language-specific patterns for common task-specification constructs (REST handlers, ORMs, auth middleware, migrations)
