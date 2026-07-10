---
name: implement-prd
description: |-
  Reads an autonomous Implementation Plan from Confluence — the artifact produced
  by /plan-prd — and implements the described system test-first using two
  planner-generator-reviewer loops: Loop A turns the plan's Test Plan
  Implementation Breakdown into executable tests; Loop B implements the Task
  Breakdown gated by unit tests and integration tests. The Implementation Plan
  is the only input; this skill does not read the SDD or Test Plan documents.
  Trigger when user says: "implement the implementation plan", "implement from
  the implementation plan", "code up this implementation plan", "build from the
  Confluence implementation plan", "/implement-prd", or asks to turn an
  implementation plan into working code and verify it with tests.
---

Implement production code from a Confluence Implementation Plan test-first. The Implementation Plan is the **only** input — do not fetch or depend on the SDD or Test Plan documents that may have been generated alongside it; the Implementation Plan is designed to stand alone. Start by launching **two parallel planner-generator-reviewer loops**: Loop A implements the plan's Test Plan Implementation Breakdown as executable code; Loop B implements the Task Breakdown, gated by unit tests and integration tests. Follow these steps precisely.

> **Don't do — stubs in production code.** Never write stub implementations (`pass`, `TODO`, `raise NotImplementedError`, `return 501`, empty function bodies) in Loop B production code. If you cannot fully implement a task because the Implementation Plan is ambiguous or a dependency is missing, stop, surface the blocker explicitly, and ask the user before continuing. A partial implementation that compiles is worse than a clear gap report.

> **Don't do — xfail markers.** Never mark tests with `@pytest.mark.xfail`, `test.failing`, `xit`, `xtest`, or any other expected-failure decorator or mechanism. Tests in Loop A must fail outright (not xfail) because they exercise production code that does not yet exist; tests in Loop B must pass. Masking failures with xfail hides real gaps and defeats the test gate.

## Step 0: Register a Stop hook

Before doing anything else, add a `Stop` hook to `.claude/settings.local.json` so the E2E test suite runs automatically each time you end a turn. This ensures no turn completes with a broken test suite.

Read `.claude/settings.local.json` first, then merge this into the `hooks.Stop` array (preserve any existing hooks):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd apps/web && python3 -m pytest tests/e2e/ -q --tb=no 2>&1 | tail -5",
            "timeout": 120,
            "statusMessage": "Running E2E tests…"
          }
        ]
      }
    ]
  }
}
```

If `.claude/settings.local.json` does not exist, create it with only the above content.

Remove this hook entry in Step 6 after the summary report is complete.

## Step 1: Gather inputs

If the user has not already provided the following, use AskUserQuestion to ask:

1. **Target directory** — local path where code will be written (default: current working directory)
2. **Language / stack** — if not inferable from the Implementation Plan's Target Files / Modules columns, ask which language/framework to use

Do not ask for the Implementation Plan source — you will look it up from Confluence in Step 2. Do not ask about or reference an SDD or Test Plan document.

## Step 2: Resolve cloud ID, fetch the Implementation Plan

**2a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**2b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter. Present every returned space to the user via AskUserQuestion and ask them to choose the one containing the Implementation Plan.

**2c. Choose the page** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. If there are more pages than fit in one response, paginate until all are listed. Present the full page list and ask the user to identify the **Implementation Plan** page (title typically "Implementation Plan: …"). Do not ask about SDD or Test Plan pages.

**2d. Fetch the page** — call `getConfluencePage` for the Implementation Plan page with `contentFormat: "markdown"`.

## Step 3: Extract tasks and test objectives

Parse the Implementation Plan document for these sections (as produced by /plan-prd):

**From the Task Summary / Task Breakdown tables**, parse implementable units. Tables are grouped first by requirement (a `### REQ-...` sub-heading), then by Owner Role within each requirement (a `##### [Role]` sub-heading, e.g. Backend Engineer, Frontend Engineer, QA Engineer). For each row record: **Task ID** (as given, e.g. `IMP-REQ-001-01`), **Requirement** (from the enclosing requirement heading), **Owner Role** (from the enclosing role heading), **Task** (description), **Type** (Discovery | Backend | Frontend | Data | Infrastructure | Testing | Security | Documentation | Release), **Target Files / Modules**, **Dependencies**, **Acceptance Criteria**, **Validation**. Preserve the requirement-then-role grouping when presenting or batching tasks — do not flatten or re-sort it, though the Execution Order section (not this grouping) remains authoritative for build sequencing.

**From the Execution Order section**, record the dependency-ordered task ID sequence and any milestone groupings. Use this as the authoritative build order, cross-checked against the Dependencies column.

**From the Parallelizable Work section**, record which task IDs may be implemented concurrently and what shared interfaces/contracts must be agreed first.

**From the Test Plan Implementation Breakdown section**, parse test objectives. For each row record: **Test Case ID** (e.g. `TC-REQ001-1`), **Test Objective**, **Supporting Code / Fixture / Harness Work**, **Implementation Task IDs** (the Task IDs it depends on / verifies), **Validation**.

**From the Autonomous Execution Contract section**, record: repository discovery commands, validation commands (unit, integration, lint, typecheck, migration, smoke-test), feature flags/config/env vars, and the fallback rule for missing optional context.

**From the Release Plan section**, record migration, feature-flag, backfill, rollout, monitoring, rollback, and documentation tasks not already captured as `Release`-type rows in the Task Breakdown.

Present a summary to the user and confirm before proceeding:

> "Found [N] tasks across [M] requirements and [K] test objectives. Shall I implement both in [target directory]?"

**Write the implementation checklist.** Create `IMPLEMENTATION_CHECKLIST.md` in the target directory (or read it if it already exists — see the resuming edge case below) with one unchecked item per test objective and per task, grouped exactly like the source document:

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

This file is the single source of truth for run progress. Update it — never batch updates, never regenerate it from scratch — at every point called out in Steps 4 and 5 below, using Edit (not a full rewrite) so prior progress is never lost. Checkbox states:
- `- [ ]` — not started or not yet passing
- `- [x]` — clean pass (reviewer approved, tests green)
- `- [ ] ⚠️ [reason]` — accepted with `Needs Human Review` / `unresolved` after the maximum revision rounds; left **unchecked** so outstanding work stays visible even though the loop moved on

---

## Step 4: Loop A — Implement the Test Plan Implementation Breakdown as executable code

Loop A runs a full **planner → generator → reviewer** cycle to turn the plan's Test Plan Implementation Breakdown into a runnable test suite. Run this loop completely before starting Loop B.

### A1 — Planner

Produce a test implementation plan:
- **Test file map** — one file per requirement group (e.g. `tests/test_req001_fetch.py`), paths relative to target directory
- **Fixture catalogue** — derived from each row's Supporting Code / Fixture / Harness Work column: shared DB seed data, mock factories, helper functions, and the file each lives in
- **Test runner setup** — config files needed (`pytest.ini`, `jest.config.js`, `docker-compose.test.yml`)
- **Existing code audit** — read the target directory for any existing test infrastructure to reuse, using the repository discovery commands from the Autonomous Execution Contract

Summarise the plan in ≤10 lines, then proceed without waiting.

### A2 — Generator (per requirement group)

For each requirement's test objectives:

1. Read any existing test helpers or fixtures that these tests will reuse.
2. Build the Supporting Code / Fixture / Harness Work described for each Test Case ID first.
3. Write executable test code that implements the Test Objective, using the Validation column as the pass condition. Since the Implementation Plan does not carry full preconditions/steps text, infer concrete setup and steps from the Test Objective, the linked Implementation Task IDs' Acceptance Criteria, and the Supporting Code / Fixture / Harness Work description — do not leave any inferred value vague (name concrete inputs, statuses, error codes).
4. Each test must:
   - Assert **observable output only** — HTTP status codes, response bodies, DB state — not implementation internals
   - Be **independent** — no shared mutable state between tests
   - Be named after the Test Case ID and objective (e.g. `test_TC_REQ001_1_fetch_toronto_minutes`)
   - Import only interfaces and paths from the file map; use stubs for production code that does not yet exist
5. Write minimal production stubs (functions returning 501 / empty) so the suite compiles.

Log: `"Loop A — written tests for REQ-00X: [file path]"`.

### A3 — Reviewer (subagent, per requirement group)

Spawn a fresh subagent (not a fork) via the Agent tool with this prompt:

> You are a QA lead verifying that test code faithfully implements a Test Plan Implementation Breakdown. Do not rewrite tests — only flag gaps.
>
> **Requirement:** [REQ-ID] — [Title]
>
> **Test Plan Implementation Breakdown rows for this requirement:**
> [full Test Case ID | Test Objective | Supporting Code / Fixture / Harness Work | Implementation Task IDs | Validation rows]
>
> **Generated test code:**
> [full content of the test file(s) for this requirement group]
>
> **Must pass** (flag any failure):
> - Every Test Case ID in the breakdown has a corresponding test function
> - The Supporting Code / Fixture / Harness Work described for each row is present (fixtures, DB seeds, mock responses)
> - The test body exercises the stated Test Objective
> - The Validation column's condition is directly encoded as an assertion (not paraphrased)
> - No test passes trivially (no empty assertion, no `assert True`)
>
> **Should pass** (flag if 2 or more fail):
> - Test names include the Test Case ID
> - Assertions use concrete values (status codes, error codes, DB results) rather than vague categories
> - Tests linked to Implementation Task IDs of type Testing/Security/Data reflect that task's Acceptance Criteria
> - Performance-oriented rows assert a stated threshold (latency, count, ratio) when one is implied by the Validation column
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [test-name or "missing test"] — [specific gap and what to add or fix]\n2. ...`

If `REVISE`: apply every item and re-run the reviewer once. After the second review, if still `REVISE`: prepend `⚠️ Needs Human Review` to that test file and continue. Maximum 2 rounds per group — never loop further.

**Update the checklist.** For each Test Case ID in this requirement group, check it off (`- [x]`) if the reviewer approved; otherwise leave it unchecked and append `⚠️ Needs Human Review: [outstanding items]`.

### A4 — Confirm compilation

After all requirement groups are written and reviewed, run the test suite once. All tests must **compile and fail** (not error). If any test errors on import, fix the import or stub. Log: `"Loop A complete: [N] tests compiled, [N] failing (expected — no production code yet)"`.

---

## Step 5: Loop B — Implement the Task Breakdown as production code

Loop B runs a full **planner → generator → reviewer** cycle to implement each task from the Task Breakdown. The approval gate for each task is: **the reviewer approves AND the task's unit tests AND integration tests all pass**. Start Loop B after Loop A completes.

### B1 — Planner

Produce a production implementation plan:
- **File map** — for each task: files to create or modify, taken from its Target Files / Modules column, paths relative to target directory
- **Interface contracts** — function signatures, class interfaces, or type definitions that cross task boundaries, inferred from Acceptance Criteria and Parallelizable Work's shared-interface notes
- **Build order** — the Execution Order sequence from Step 3, validated against each task's Dependencies column (models/data tasks → services/backend tasks → frontend/handlers → release tasks)
- **Existing code audit** — read the target directory; identify files already present that the plan must integrate with rather than replace
- **Unit test file map** — one unit test file per Backend/Frontend/Data task (e.g. `tests/unit/test_status_normaliser.py`); these are written by Loop B and test individual functions in isolation
- **Integration test file map** — one integration test file per subsystem boundary implied by task Dependencies (e.g. `tests/integration/test_fetch_pipeline.py`); these test task interactions against a real DB or queue

Summarise the plan in ≤15 lines, then proceed without waiting.

### B2 — Generator (per task, in Execution Order)

For each task:

1. Read existing files this task extends or depends on before writing.
2. Write unit tests for this task's functions/methods in isolation (mock all external I/O). Each unit test must:
   - Cover the happy path and every error condition implied by the task's Acceptance Criteria and Validation columns
   - Assert exact return values, raised exceptions, or emitted log entries
3. Write integration tests for this task's interactions (real DB, real queue, mocked external APIs). Each integration test must:
   - Establish real DB state (seed rows, not mocks)
   - Assert DB state changes, not just return values
4. Write complete, production-ready implementation code:
   - Match the project's naming conventions, import style, error handling idioms
   - Implement **all** behaviour required by the task's Acceptance Criteria — no stubs, TODOs, or placeholders
   - For `Discovery` tasks, produce the repo-local artifact or decision the task specifies (not code) and record it where later tasks can reference it
   - For `Release` tasks, implement the migration/flag/rollout/rollback work described, following the Release Plan
   - Include only types, functions, and exports the task requires
5. Run the task's Validation command (if one is specified) and confirm it passes before marking the task done.
6. Remove any stubs written in Loop A for this task.

Log: `"Loop B — implemented [Task ID]: [Task]"`.

### B3 — Reviewer (subagent, per task)

Spawn a fresh subagent via the Agent tool with this prompt:

> You are a critical senior engineer reviewing an implementation against its Implementation Plan task specification. Find gaps only — do not rewrite code yourself.
>
> **Task:** [Task ID] [Task] ([Type])
>
> **Task specification:**
> Target Files / Modules: [...]
> Dependencies: [...]
> Acceptance Criteria: [...]
> Validation: [...]
>
> **Files implemented:**
> [list of production file paths]
>
> **Unit test files:**
> [list of unit test file paths]
>
> **Integration test files:**
> [list of integration test file paths]
>
> **Code content:**
> [full content of each written file]
>
> **Must pass** (flag any failure):
> - Every clause of the Acceptance Criteria is met
> - No stubs remain: scan every production file for `pass`, `TODO`, `FIXME`, `raise NotImplementedError`, `return 501`, empty function bodies, and placeholder strings like `"not implemented"` — flag each occurrence with file and line number
> - Error handling matches what the Acceptance Criteria / Validation implies (correct HTTP status codes and error codes where applicable)
> - Security-relevant Acceptance Criteria enforced (auth checks, input validation, PII handling) when the task Type is Security or the criteria mention it
> - Unit tests cover every function's happy path and all error conditions implied by the Acceptance Criteria
> - Integration tests cover every cross-boundary interaction (DB writes, queue events) implied by the Dependencies column
> - No regressions: pre-existing interfaces in modified files are unchanged
>
> **Should pass** (flag if 2 or more fail):
> - Naming matches the Target Files / Modules column exactly
> - The task's Validation command, when run, would pass against this implementation
> - Integration tests use real DB state, not mocks
> - Discovery/Release task outputs are recorded in a form later tasks can consume without re-asking the user
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [file:line-range] — [specific gap and what to add]\n2. ...`

Wait for the subagent verdict.

### B4 — Test gate (per task)

After the reviewer approves, run the task's unit tests and integration tests:

Detect the test commands from, in order of priority:
1. The task's own Validation column (if it names a runnable command)
2. `package.json` scripts (`test:unit`, `test:integration`)
3. `Makefile` targets (`make test-unit`, `make test-integration`)
4. Language defaults with path filters (`pytest tests/unit/test_task.py`, `go test ./internal/task/...`)

If services are required (DB, queue), check `docker-compose.yml` and start them via Bash before running.

**The task is not complete until both unit tests AND integration tests pass.** For any failing test:
1. Read the failing test and the implementation file it exercises
2. Fix the implementation if the task's Acceptance Criteria backs the expected behaviour
3. Fix the test only if the assertion is wrong relative to the Acceptance Criteria
4. Re-run after each fix; never batch multiple fixes before re-running

Stop after 3 fix-and-rerun cycles per failing test; mark it `⚠️ Test unresolved` with the error output.

If the reviewer returned `REVISE:`: apply every cited gap, re-run the reviewer once. After the second review, if still `REVISE:`: mark the task `⚠️ Needs Human Review: [outstanding issues]` and continue. Maximum 2 revision rounds — never loop further.

**Final re-review gate.** A task must never be marked complete on the strength of the B3 review alone if any production or test file changed afterward during fix-and-rerun cycles. If any such file changed, spawn one more fresh B3-reviewer subagent (same prompt, updated file contents) against the final code before checking the box. This final review counts toward the same 2-round revision cap as B3 — if it returns `REVISE` a second time, stop revising and mark the task `⚠️ Needs Human Review: [outstanding issues]` instead of checking it off.

Log: `"After [Task ID]: unit [P]/[F], integration [P]/[F]"`.

**Update the checklist.** Check off (`- [x]`) this Task ID under its requirement/role heading only if: the B3 reviewer (and, when applicable, the final re-review) approved AND both unit and integration tests passed. Otherwise leave it unchecked and append the `⚠️ Needs Human Review` or `⚠️ Test unresolved` marker with a one-line reason.

**Commit the task.** If the target directory is a git repository, create one commit per task immediately after its checklist update, regardless of whether it was checked off or flagged — do not batch commits across tasks and do not wait until Loop B finishes. Stage exactly the files this task touched (production files, unit test files, integration test files, and `IMPLEMENTATION_CHECKLIST.md`) — never `git add -A` or `git add .`. Use a conventional commit:

```
<type>(<task-id>): <task, imperative mood, lowercase>
```

Map the task's Type to `<type>`: Backend | Frontend | Data | Infrastructure | Security → `feat`; Testing → `test`; Documentation → `docs`; Release | Discovery → `chore`. Use the Task ID (lowercased, e.g. `imp-req-001-01`) as the commit scope. If the task was flagged `⚠️ Needs Human Review` or `⚠️ Test unresolved`, append a body line with that exact marker and reason so it's visible in `git log`. Never use `--no-verify`; if a commit hook fails, fix the underlying issue and re-commit rather than skipping it. If the target directory is not a git repository, skip this step silently.

### B5 — Full system test run

After all tasks complete Loop B, run the full test suite from Loop A (system tests) against the completed production code:

For any system test that fails:
1. Determine whether the failure is in the test code (Loop A output) or the production code (Loop B output)
2. Fix whichever is wrong relative to the Test Plan Implementation Breakdown / Task Breakdown
3. Re-run after each fix

Stop after 3 fix-and-rerun cycles per failing system test; mark it `⚠️ System test unresolved`.

Log: `"System tests: [P] passing / [F] failing"`.

**Update the checklist.** Check off (`- [x]`) each Test Case ID under **System Tests** that passes; leave unchecked with `⚠️ System test unresolved` otherwise.

---

## Step 6: Summary report

Remove the Stop hook added in Step 0 from `.claude/settings.local.json` (leave all other hooks intact). If the file becomes empty, delete it.

Confirm `IMPLEMENTATION_CHECKLIST.md` reflects the final state of every item (do not delete it — it is the durable record of this run). Present a concise implementation report:

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

---

## Edge cases

**No Test Plan Implementation Breakdown section found**: derive test scaffolding directly from each task's Acceptance Criteria and Validation columns instead; note the gap and flag Loop A output as needing review against a formal test breakdown.

**No Task Breakdown / Task Summary table found**: the Implementation Plan is unusable as the sole input — stop and tell the user the page does not contain a Task Breakdown, and ask them to confirm they selected the correct Confluence page.

**Task Breakdown has no Testing-type rows**: derive unit and integration tests from each task's Acceptance Criteria and Validation columns only; note the gap.

**Monorepo / multi-service plan**: ask the user which requirement group(s) / milestone(s) to implement; scope both loops to those only.

**Task specifying infrastructure (Docker, Terraform, CI)**: implement config files in Loop B following the same generator → reviewer loop; verify by linting (`terraform validate`, `docker build`, `yamllint`) rather than unit/integration tests; Loop A skips pure-infra tasks.

**Conflicting Implementation Plan and existing code**: surface the conflict explicitly, ask the user which takes precedence before writing.

**Large plan (10+ tasks)**: process Loop B in batches of 5 following the Execution Order, report progress after each batch, and confirm before continuing. Loop A processes all test objective groups up front.

**Resuming an interrupted run**: if `IMPLEMENTATION_CHECKLIST.md` already exists in the target directory when Step 3 begins, read it instead of creating a new one. Treat every `- [x]` item as already done and skip re-generating or re-reviewing it; resume Loop A/B at the first unchecked or `⚠️`-flagged item. Confirm with the user which items are being resumed versus redone before proceeding.

## Additional resources

- **`references/implementation-patterns.md`** — language-specific patterns for common task-specification constructs (REST handlers, ORMs, auth middleware, migrations)
