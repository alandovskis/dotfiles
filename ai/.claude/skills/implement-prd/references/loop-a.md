# Step 4: Loop A — Implement the Test Plan Implementation Breakdown as executable code

Read this file when Step 3 confirms and the checklist is written. Loop A runs a full **planner → generator → reviewer** cycle to turn the plan's Test Plan Implementation Breakdown into a runnable test suite. Run this loop completely before starting Loop B (`references/loop-b.md`).

## A1 — Planner

Produce a test implementation plan:
- **Test file map** — one file per requirement group (e.g. `tests/test_req001_fetch.py`), paths relative to target directory
- **Fixture catalogue** — derived from each row's Supporting Code / Fixture / Harness Work column: shared DB seed data, mock factories, helper functions, and the file each lives in
- **Test runner setup** — config files needed (`pytest.ini`, `jest.config.js`, `docker-compose.test.yml`)
- **Existing code audit** — read the target directory for any existing test infrastructure to reuse, using the repository discovery commands from the Autonomous Execution Contract

Summarise the plan in ≤10 lines, then proceed without waiting.

## A2 — Generator (per requirement group)

For each requirement's test objectives:

0. In `--resume` mode, skip a requirement group only when every one of its Test Case IDs is checked in the checklist. For a partially complete group, generate and review only its unchecked or `⚠️`-flagged objectives; preserve existing approved tests unless their imports or shared fixtures must change to make the pending objectives compile.

1. Read any existing test helpers or fixtures these tests will reuse.
2. Build the Supporting Code / Fixture / Harness Work for each Test Case ID first.
3. Write executable test code implementing the Test Objective, using the Validation column as the pass condition. The plan carries no full preconditions/steps text, so infer concrete setup and steps from the Test Objective, the linked Implementation Task IDs' Acceptance Criteria, and the Supporting Code / Fixture / Harness Work — name concrete inputs, statuses, and error codes; leave nothing vague.
4. Each test must:
   - Assert **observable output only** — HTTP status codes, response bodies, DB state — not implementation internals
   - Be **independent** — no shared mutable state between tests
   - Be named after the Test Case ID and objective (e.g. `test_TC_REQ001_1_fetch_toronto_minutes`)
   - Import only interfaces and paths from the file map; use stubs for production code that does not yet exist
5. Write minimal production stubs (functions returning 501 / empty) so the suite compiles.

Log: `"Loop A — written tests for REQ-00X: [file path]"`.

## A3 — Reviewer (subagent, per requirement group)

Spawn a fresh subagent (not a fork) via the Agent tool with this prompt:

> You are a QA lead verifying test code against a Test Plan Implementation Breakdown. Flag gaps only — do not rewrite tests.
>
> **Requirement:** [REQ-ID] — [Title]
>
> **Test Plan Implementation Breakdown rows for this requirement:** [full Test Case ID | Test Objective | Supporting Code / Fixture / Harness Work | Implementation Task IDs | Validation rows]
>
> **Generated test code:** [full content of the test file(s) for this requirement group]
>
> **Must pass** (flag any failure):
> - Every Test Case ID has a corresponding test function
> - The row's Supporting Code / Fixture / Harness Work is present (fixtures, DB seeds, mock responses)
> - The test body exercises the stated Test Objective
> - The Validation column's condition is directly encoded as an assertion, not paraphrased
> - No test passes trivially (no empty assertion, no `assert True`)
>
> **Should pass** (flag if 2+ fail):
> - Test names include the Test Case ID
> - Assertions use concrete values (status codes, error codes, DB results), not vague categories
> - Tests linked to Testing/Security/Data Implementation Task IDs reflect that task's Acceptance Criteria
> - Performance-oriented rows assert the threshold (latency, count, ratio) implied by the Validation column
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [test-name or "missing test"] — [specific gap and what to add or fix]\n2. ...`

If `REVISE`: apply every item and re-run the reviewer once. After the second review, if still `REVISE`: prepend `⚠️ Needs Human Review` to that test file and continue. Maximum 2 rounds per group — never loop further.

**Update the checklist.** For each Test Case ID in this requirement group, check it off (`- [x]`) if the reviewer approved; otherwise leave it unchecked and append `⚠️ Needs Human Review: [outstanding items]`.

## A4 — Confirm compilation

After all requirement groups are written and reviewed, run the test suite once. All tests must **compile**; tests that exercise production code still absent must fail rather than error. If any test errors on import, fix the import or stub. In `--resume` mode, existing production code may make some system tests pass; passing tests are valid. Log: `"Loop A complete: [N] tests compiled, [N] failing (expected where production is absent)"`.

Loop A is now complete. Read `references/loop-b.md` to begin Step 5.
