# Step 5: Loop B — Implement the Task Breakdown as production code

Read this file after Loop A (`references/loop-a.md`) completes. Loop B runs a full **planner → generator → reviewer** cycle to implement each task from the Task Breakdown. The approval gate for each task is: **the reviewer approves AND the task's unit tests AND integration tests all pass**.

## B1 — Planner

Produce a production implementation plan:
- **File map** — for each task: files to create or modify, taken from its Target Files / Modules column, paths relative to target directory
- **Interface contracts** — function signatures, class interfaces, or type definitions that cross task boundaries, inferred from Acceptance Criteria and Parallelizable Work's shared-interface notes
- **Build order** — the Execution Order sequence from Step 3, validated against each task's Dependencies column (models/data tasks → services/backend tasks → frontend/handlers → release tasks)
- **Existing code audit** — read the target directory; identify files already present that the plan must integrate with rather than replace
- **Unit test file map** — one unit test file per Backend/Frontend/Data task (e.g. `tests/unit/test_status_normaliser.py`); these are written by Loop B and test individual functions in isolation
- **Integration test file map** — one integration test file per subsystem boundary implied by task Dependencies (e.g. `tests/integration/test_fetch_pipeline.py`); these test task interactions against a real DB or queue

Summarise the plan in ≤15 lines, then proceed without waiting.

## B2 — Generator (per task, in Execution Order)

For each task:

1. Read existing files this task extends or depends on before writing.
2. Write unit tests for this task's functions/methods in isolation (mock all external I/O). Cover the happy path and every error condition implied by the Acceptance Criteria and Validation columns; assert exact return values, raised exceptions, or emitted log entries.
3. Write integration tests for this task's interactions (real DB, real queue, mocked external APIs). Establish real DB state (seed rows, not mocks); assert DB state changes, not just return values.
4. Write complete, production-ready implementation code:
   - Match the project's naming conventions, import style, error handling idioms
   - Implement **all** behaviour the Acceptance Criteria requires — no stubs, TODOs, or placeholders
   - For `Discovery` tasks, produce the repo-local artifact or decision the task specifies (not code) and record it where later tasks can reference it
   - For `Release` tasks, implement the migration/flag/rollout/rollback work described, following the Release Plan
   - Include only the types, functions, and exports the task requires
5. Run the task's Validation command, if one is specified, and confirm it passes before marking the task done.
6. Remove any Loop A stubs for this task.

Log: `"Loop B — implemented [Task ID]: [Task]"`.

## B3 — Reviewer (subagent, per task)

Spawn a fresh subagent via the Agent tool with this prompt:

> You are a critical senior engineer reviewing an implementation against its Implementation Plan task specification. Find gaps only — do not rewrite code.
>
> **Task:** [Task ID] [Task] ([Type])
>
> **Task specification:** Target Files / Modules: [...] · Dependencies: [...] · Acceptance Criteria: [...] · Validation: [...]
>
> **Files implemented:** [list of production file paths]
>
> **Unit test files:** [list of unit test file paths]
>
> **Integration test files:** [list of integration test file paths]
>
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

Wait for the subagent verdict.

## B4 — Test gate (per task)

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

## B5 — Full system test run

After all tasks complete Loop B, run the full test suite from Loop A (system tests) against the completed production code:

For any system test that fails:
1. Determine whether the failure is in the test code (Loop A output) or the production code (Loop B output)
2. Fix whichever is wrong relative to the Test Plan Implementation Breakdown / Task Breakdown
3. Re-run after each fix

Stop after 3 fix-and-rerun cycles per failing system test; mark it `⚠️ System test unresolved`.

Log: `"System tests: [P] passing / [F] failing"`.

**Update the checklist.** Check off (`- [x]`) each Test Case ID under **System Tests** that passes; leave unchecked with `⚠️ System test unresolved` otherwise.

Loop B is now complete. Return to `SKILL.md` Step 6 for the summary report.
