# Step 5: Loop B — Implement the Task Breakdown as production code

Read this file after Loop A (`references/loop-a.md`) completes. Loop B implements each task from the Task Breakdown, test-first, gated by review and passing tests. Generation, review, and the test-fix loop for a task run inside **one fresh isolated execution pass per task** — the main thread never holds a task's file contents, tool output, or reviewer transcript. It only keeps a short result line per task, so context stays flat regardless of how many tasks the plan has.

## B1 — Planner (main thread)

Produce a production implementation plan:
- **File map** — for each task: files to create or modify, taken from its Target Files / Modules column, paths relative to target directory
- **Interface contracts** — function signatures, class interfaces, or type definitions that cross task boundaries, inferred from Acceptance Criteria and Parallelizable Work's shared-interface notes
- **Build order** — the Execution Order sequence from Step 3, validated against each task's Dependencies column (models/data tasks → services/backend tasks → frontend/handlers → release tasks)
- **Existing code audit** — read the target directory; identify files already present that the plan must integrate with rather than replace
- **Unit test file map** — one unit test file per Backend/Frontend/Data task (e.g. `tests/unit/test_status_normaliser.py`)
- **Integration test file map** — one integration test file per subsystem boundary implied by task Dependencies (e.g. `tests/integration/test_fetch_pipeline.py`)

Summarise the plan in ≤15 lines, then proceed without waiting. Keep this summary — B2 hands the relevant slice of it to each task's subagent.

## B2 — Task execution pass (per task, in Execution Order)

For each task, one at a time, use a fresh agent or isolated execution pass. In `--resume` mode, skip tasks that remain checked after the validation required in Step 3; run only unchecked or `⚠️`-flagged tasks in Execution Order. Give the execution pass only what this task needs: its own row from the Task Breakdown, the relevant slice of B1's file map / interface contracts / build order, the repository discovery and validation commands from the Autonomous Execution Contract, and — only if this task's Dependencies reference an earlier task — that earlier task's one-line outcome from the checklist. Never pass a prior task's full generation, review, or test output forward.

Use this prompt, substituting the bracketed task fields:

> You are implementing one task from an Implementation Plan, test-first, end to end. Work entirely within this task's scope — do not touch files outside it.
>
> **Task:** [Task ID] [Task] ([Type])
> **Target Files / Modules:** [...]
> **Dependencies:** [...] — [prior task's one-line outcome, if any]
> **Acceptance Criteria:** [...]
> **Validation:** [...]
> **Repository discovery / validation commands:** [from the Autonomous Execution Contract]
>
> **1. Generate.**
> - Read existing files this task extends or depends on before writing.
> - Write unit tests for this task's functions/methods in isolation (mock all external I/O). Cover the happy path and every error condition implied by the Acceptance Criteria and Validation; assert exact return values, raised exceptions, or emitted log entries.
> - Write integration tests for this task's interactions (real DB, real queue, mocked external APIs). Establish real DB state (seed rows, not mocks); assert DB state changes, not just return values.
> - Write complete, production-ready implementation code: match the project's naming conventions, import style, and error handling idioms; implement **all** behaviour the Acceptance Criteria requires — no stubs, TODOs, or placeholders; include only the types, functions, and exports the task requires. For `Discovery` tasks, produce the repo-local artifact or decision the task specifies (not code). For `Release` tasks, implement the migration/flag/rollout/rollback work described.
> - Remove any Loop A stubs for this task.
>
> **2. Review.** Use a fresh reviewer agent or isolated review pass with this exact prompt, substituting this task's specification, implemented files, and their content. If delegation is unavailable, perform the review using only the supplied prompt material:
>
> """
> You are a critical senior engineer reviewing an implementation against its Implementation Plan task specification. Find gaps only — do not rewrite code.
>
> **Task:** [Task ID] [Task] ([Type])
> **Task specification:** Target Files / Modules: [...] · Dependencies: [...] · Acceptance Criteria: [...] · Validation: [...]
> **Files implemented:** [list of production file paths]
> **Unit test files:** [list of unit test file paths]
> **Integration test files:** [list of integration test file paths]
> **Code content:** [full content of each written file]
>
> **Must pass** (flag any failure):
> - Every clause of the Acceptance Criteria is met
> - No stubs remain: scan every production file for `pass`, `TODO`, `FIXME`, `raise NotImplementedError`, `return 501`, empty function bodies, and placeholder strings like `"not implemented"` — flag each occurrence with file and line number
> - Error handling matches what the Acceptance Criteria / Validation implies (correct HTTP status codes and error codes where applicable)
> - Security-relevant Acceptance Criteria enforced (auth checks, input validation, PII handling) when Type is Security or the criteria mention it
> - Unit tests cover every function's happy path and all error conditions implied by the Acceptance Criteria
> - Integration tests cover every cross-boundary interaction (DB writes, queue events) implied by Dependencies
> - No regressions: pre-existing interfaces in modified files are unchanged
>
> **Should pass** (flag if 2+ fail):
> - Naming matches the Target Files / Modules column exactly
> - The task's Validation command, when run, would pass against this implementation
> - Integration tests use real DB state, not mocks
> - Discovery/Release task outputs are recorded so later tasks can consume them without re-asking the user
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [file:line-range] — [specific gap and what to add]\n2. ...`
> """
>
> If `REVISE`: apply every cited gap, then run another fresh isolated reviewer pass with the same prompt above. After the second review, if still `REVISE`: stop revising — this task ends as `⚠️ Needs Human Review`.
>
> **3. Test gate.** Once reviewed (approved, or exhausted at `⚠️ Needs Human Review`), run this task's unit and integration tests. Detect the commands from, in priority order: the task's own Validation column if it names a runnable command; `package.json` scripts (`test:unit`, `test:integration`); `Makefile` targets (`make test-unit`, `make test-integration`); language defaults with path filters (`pytest tests/unit/test_task.py`, `go test ./internal/task/...`). If services are required (DB, queue), check `docker-compose.yml` and start them with the available command-execution capability first.
>
> The task is not done until both unit and integration tests pass. For any failing test: read the failing test and the implementation file it exercises; fix the implementation if the Acceptance Criteria backs the expected behaviour, or fix the test only if its assertion is wrong relative to the Acceptance Criteria; re-run after each fix, never batching fixes. Stop after 3 fix-and-rerun cycles per failing test — mark it `⚠️ Test unresolved` with the error output.
>
> **4. Final re-review gate.** If any production or test file changed after the review in step 2 (i.e. during the test-fix cycles in step 3), run one more fresh isolated reviewer pass (same prompt as step 2, updated file contents) against the final code. This counts toward the same 2-round cap as step 2 — if it returns `REVISE` again, stop and mark the task `⚠️ Needs Human Review` instead of done.
>
> **5. Return exactly this to the caller — nothing else** (no file contents, no tool output, no reviewer transcripts):
> - Task ID
> - Status: `done` | `⚠️ Needs Human Review: [one-line reason]` | `⚠️ Test unresolved: [one-line reason]`
> - Unit tests: [P]/[F], Integration tests: [P]/[F] (final counts from the last test run)
> - Files touched (production + unit test + integration test paths, one per line)
> - One-line summary of what was implemented

## B3 — Record result and commit (main thread)

Using only the isolated execution pass's returned summary (do not re-read the task's files):

**Update the checklist.** Check off (`- [x]`) the Task ID under its requirement/role heading if status is `done`; otherwise leave it unchecked and append the returned `⚠️` marker and reason.

**Commit the task.** If the target directory is a git repository, commit now — do not batch commits across tasks. Stage exactly the returned file list plus `IMPLEMENTATION_CHECKLIST.md` — never `git add -A` or `git add .`. Use a conventional commit:

```
<type>(<task-id>): <task, imperative mood, lowercase>
```

Map the task's Type to `<type>`: Backend | Frontend | Data | Infrastructure | Security → `feat`; Testing → `test`; Documentation → `docs`; Release | Discovery → `chore`. Use the Task ID (lowercased, e.g. `imp-req-001-01`) as the commit scope. If the task was flagged `⚠️`, append a body line with that exact marker and reason so it's visible in `git log`. Never use `--no-verify`; if a commit hook fails, fix the underlying issue and re-commit rather than skipping it. If the target directory is not a git repository, skip this step silently.

Log: `"After [Task ID]: [status], unit [P]/[F], integration [P]/[F]"`. Then move to the next B2 execution pass — carry forward only the checklist state and this task's one-line outcome (for the next task's Dependencies context, if applicable), nothing more.

## B4 — Full system test run (main thread)

After all tasks complete Loop B, run the full test suite from Loop A (system tests) against the completed production code:

For any system test that fails:
1. Determine whether the failure is in the test code (Loop A output) or the production code (Loop B output)
2. Fix whichever is wrong relative to the Test Plan Implementation Breakdown / Task Breakdown
3. Re-run after each fix

Stop after 3 fix-and-rerun cycles per failing system test; mark it `⚠️ System test unresolved`.

Log: `"System tests: [P] passing / [F] failing"`.

**Update the checklist.** Check off (`- [x]`) each Test Case ID under **System Tests** that passes; leave unchecked with `⚠️ System test unresolved` otherwise.

Loop B is now complete. Return to `SKILL.md` Step 6 for the summary report.
