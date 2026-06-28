---
name: implement-prd
description: |-
  Reads a Software Design Document (SDD) and Test Plan from Confluence and
  implements the described system test-first using two planner-generator-reviewer
  loops: Loop A turns the test plan into executable code; Loop B implements the
  SDD gated by unit tests and integration tests. Trigger when user says:
  "implement from SDD", "implement the SDD from Confluence", "code up this design
  doc", "build from the software design document", "implement a Confluence SDD",
  "/implement-prd", or asks to turn a design document into working code
  and verify it with tests.
---

Implement production code from a Confluence Software Design Document (SDD) test-first. Start by launching **two parallel planner-generator-reviewer loops**: Loop A implements the test plan as executable code; Loop B implements the SDD, gated by unit tests and integration tests. Follow these steps precisely.

## Step 1: Gather inputs

If the user has not already provided the following, use AskUserQuestion to ask:

1. **Target directory** — local path where code will be written (default: current working directory)
2. **Language / stack** — if not specified in the SDD, ask which language/framework to use

Do not ask for the SDD or test plan sources — you will look them up from Confluence in Step 2.

## Step 2: Resolve cloud ID, fetch SDD and test plan

**2a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**2b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter. Present every returned space to the user via AskUserQuestion and ask them to choose the one containing both the SDD and the test plan.

**2c. Choose both pages** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. If there are more pages than fit in one response, paginate until all are listed. Present the full page list once and ask the user to identify:
- Which page is the **SDD** (title typically "SDD: …")
- Which page is the **Test Plan** (title typically "Test Plan: …")

**2d. Fetch both pages** — call `getConfluencePage` for the SDD page and for the test plan page in parallel, both with `contentFormat: "markdown"`.

## Step 3: Extract components and test cases

**From the SDD**, parse implementable units:
- **API endpoints** — method, path, request/response schema, auth
- **Data models / schema** — tables, fields, constraints, indexes, migration strategy
- **Service / module definitions** — class/function responsibilities, interfaces
- **Background jobs / workers** — triggers, payloads, failure handling
- **Configuration** — environment variables, feature flags

For each component record: **ID** (COMP-001…), **Name**, **Type** (api | model | service | job | config), **Specification** (full relevant SDD text).

Detect **dependency order**: data models before services, services before API handlers.

**From the test plan**, parse test cases grouped by requirement. For each test case record: **ID** (TC-REQ0XX-N), **Type** (Happy path | Boundary | Negative | Error path | Performance), **Preconditions**, **Steps**, **Pass criteria**.

Present a summary to the user and confirm before proceeding:

> "Found [N] SDD components and [M] test cases. Shall I implement both in [target directory]?"

---

## Step 4: Loop A — Implement the test plan as executable code

Loop A runs a full **planner → generator → reviewer** cycle to turn the Confluence test plan into a runnable test suite. Run this loop completely before starting Loop B.

### A1 — Planner

Produce a test implementation plan:
- **Test file map** — one file per requirement group (e.g. `tests/test_req001_fetch.py`), paths relative to target directory
- **Fixture catalogue** — shared DB seed data, mock factories, helper functions, and the file each lives in
- **Test runner setup** — config files needed (`pytest.ini`, `jest.config.js`, `docker-compose.test.yml`)
- **Existing code audit** — read the target directory for any existing test infrastructure to reuse

Summarise the plan in ≤10 lines, then proceed without waiting.

### A2 — Generator (per requirement group)

For each requirement's test cases:

1. Read any existing test helpers or fixtures that these tests will reuse.
2. Write executable test code that directly implements each TC exactly as specified: preconditions as test setup, steps as test body, pass criteria as assertions.
3. Each test must:
   - Assert **observable output only** — HTTP status codes, response bodies, DB state — not implementation internals
   - Be **independent** — no shared mutable state between tests
   - Be named after the TC ID and title (e.g. `test_TC_REQ001_1_fetch_toronto_minutes`)
   - Import only interfaces and paths from the file map; use stubs for production code that does not yet exist
4. Write minimal production stubs (functions returning 501 / empty) so the suite compiles.

Log: `"Loop A — written tests for REQ-00X: [file path]"`.

### A3 — Reviewer (subagent, per requirement group)

Spawn a fresh subagent (not a fork) via the Agent tool with this prompt:

> You are a QA lead verifying that test code faithfully implements a structured test plan. Do not rewrite tests — only flag gaps.
>
> **Requirement:** [REQ-ID] — [Title]
>
> **Test plan cases:**
> [full TC text from the test plan for this requirement group]
>
> **Generated test code:**
> [full content of the test file(s) for this requirement group]
>
> **Must pass** (flag any failure):
> - Every TC in the test plan has a corresponding test function
> - Preconditions are established in test setup (fixtures, DB seeds, mock responses)
> - Steps are executed in order in the test body
> - Pass criteria are directly encoded as assertions (not paraphrased)
> - No test passes trivially (no empty assertion, no `assert True`)
>
> **Should pass** (flag if 2 or more fail):
> - Test names include the TC ID
> - Assertions use exact values from the test plan (status codes, error codes, SQL results)
> - Error-path tests inject the exact failure described (e.g. TCP port blocked, mock raises 503)
> - Performance tests assert the stated threshold (latency, count, ratio)
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [test-name or "missing test"] — [specific gap and what to add or fix]\n2. ...`

If `REVISE`: apply every item and re-run the reviewer once. After the second review, if still `REVISE`: prepend `⚠️ Needs Human Review` to that test file and continue. Maximum 2 rounds per group — never loop further.

### A4 — Confirm compilation

After all requirement groups are written and reviewed, run the test suite once. All tests must **compile and fail** (not error). If any test errors on import, fix the import or stub. Log: `"Loop A complete: [N] tests compiled, [N] failing (expected — no production code yet)"`.

---

## Step 5: Loop B — Implement the SDD as production code

Loop B runs a full **planner → generator → reviewer** cycle to implement each SDD component. The approval gate for each component is: **the reviewer approves AND the component's unit tests AND integration tests all pass**. Start Loop B after Loop A completes.

### B1 — Planner

Produce a production implementation plan:
- **File map** — for each component: files to create or modify, paths relative to target directory
- **Interface contracts** — function signatures, class interfaces, or type definitions that cross component boundaries
- **Build order** — strict dependency sequence (models → repositories → services → handlers → routes)
- **Existing code audit** — read the target directory; identify files already present that the plan must integrate with rather than replace
- **Unit test file map** — one unit test file per service/module component (e.g. `tests/unit/test_status_normaliser.py`); these are written by Loop B and test individual functions in isolation
- **Integration test file map** — one integration test file per subsystem boundary (e.g. `tests/integration/test_fetch_pipeline.py`); these test component interactions against a real DB or queue

Summarise the plan in ≤15 lines, then proceed without waiting.

### B2 — Generator (per component, in dependency order)

For each component:

1. Read existing files this component extends or depends on before writing.
2. Write unit tests for this component's functions/methods in isolation (mock all external I/O). Each unit test must:
   - Cover the happy path and all error conditions from the SDD error table
   - Assert exact return values, raised exceptions, or emitted log entries
3. Write integration tests for this component's interactions (real DB, real queue, mocked external APIs). Each integration test must:
   - Establish real DB state (seed rows, not mocks)
   - Assert DB state changes, not just return values
4. Write complete, production-ready implementation code:
   - Match the project's naming conventions, import style, error handling idioms
   - Implement **all** SDD-specified behaviour — no stubs, TODOs, or placeholders
   - Include only types, functions, and exports the SDD requires
5. Remove any stubs written in Loop A for this component.

Log: `"Loop B — implemented COMP-00X: [Name]"`.

### B3 — Reviewer (subagent, per component)

Spawn a fresh subagent via the Agent tool with this prompt:

> You are a critical senior engineer reviewing an implementation against its SDD specification. Find gaps only — do not rewrite code yourself.
>
> **Component:** [ID] [Name] ([Type])
>
> **SDD specification:**
> [full relevant SDD text for this component]
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
> - Every SDD-specified field, endpoint, method, or behaviour is present
> - No unimplemented stubs or TODOs remain
> - Error handling matches SDD error table (correct HTTP status codes and error codes)
> - Security rules from SDD enforced (auth checks, input validation, PII handling)
> - Unit tests cover every function's happy path and all SDD-listed error conditions
> - Integration tests cover every cross-boundary interaction (DB writes, queue events)
> - No regressions: pre-existing interfaces in modified files are unchanged
>
> **Should pass** (flag if 2 or more fail):
> - Naming matches SDD exactly (table names, field names, endpoint paths)
> - Response shapes match SDD schema
> - Constraints and indexes from SDD data model are present
> - Auth/authz enforced at the correct layer
> - Integration tests use real DB state, not mocks
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [file:line-range] — [specific gap and what to add]\n2. ...`

Wait for the subagent verdict.

### B4 — Test gate (per component)

After the reviewer approves, run the component's unit tests and integration tests:

Detect the test commands from:
1. `package.json` scripts (`test:unit`, `test:integration`)
2. `Makefile` targets (`make test-unit`, `make test-integration`)
3. Language defaults with path filters (`pytest tests/unit/test_comp.py`, `go test ./internal/comp/...`)

If services are required (DB, queue), check `docker-compose.yml` and start them via Bash before running.

**The component is not complete until both unit tests AND integration tests pass.** For any failing test:
1. Read the failing test and the implementation file it exercises
2. Fix the implementation if the SDD backs the expected behaviour
3. Fix the test only if the assertion is wrong relative to the SDD
4. Re-run after each fix; never batch multiple fixes before re-running

Stop after 3 fix-and-rerun cycles per failing test; mark it `⚠️ Test unresolved` with the error output.

If the reviewer returned `REVISE:`: apply every cited gap, re-run the reviewer once. After the second review, if still `REVISE:`: mark the component `⚠️ Needs Human Review: [outstanding issues]` and continue. Maximum 2 revision rounds — never loop further.

Log: `"After COMP-00X: unit [P]/[F], integration [P]/[F]"`.

### B5 — Full system test run

After all components complete Loop B, run the full test suite from Loop A (system tests) against the completed production code:

For any system test that fails:
1. Determine whether the failure is in the test code (Loop A output) or the production code (Loop B output)
2. Fix whichever is wrong relative to the test plan / SDD
3. Re-run after each fix

Stop after 3 fix-and-rerun cycles per failing system test; mark it `⚠️ System test unresolved`.

Log: `"System tests: [P] passing / [F] failing"`.

---

## Step 6: Summary report

Present a concise implementation report:

```
## Implementation complete

**Source SDD:** [Confluence link]
**Source Test Plan:** [Confluence link]
**Target directory:** [path]

### Loop A — Test plan implementation

[N] test cases from test plan → [N] executable tests written across [F] files.
Loop A result: [N] compiled, all failing before production code (expected).

### Loop B — SDD implementation

| ID | Name | Type | Unit | Integration | Status | Files |
|----|------|------|------|-------------|--------|-------|
| COMP-001 | accounts table | model | 4/4 | 2/2 | ✅ | db/schema.sql |
| COMP-002 | StatusNormaliser | service | 7/7 | 3/3 | ✅ | src/normaliser.py |
| COMP-003 | POST /timeline | api | 5/5 | 4/4 | ⚠️ Needs Human Review | src/routes/timeline.py |

### System tests (Loop A suite against Loop B production code)

**Final:** [P] passing / [F] failing

| TC ID | Requirement | Type | Status |
|-------|-------------|------|--------|
| TC-REQ001-1 | Fetch | Happy path | ✅ |
| TC-REQ001-4 | Fetch | Error path | ✅ |
| TC-REQ003-5 | Extraction | Performance | ⚠️ System test unresolved |

### Outstanding issues
- COMP-003: [specific gap from reviewer]
- TC-REQ003-5: [error output]

### Next steps
- [ ] Resolve ⚠️ items above
- [ ] Wire up to CI pipeline (unit, integration, system test stages)
- [ ] Add load / performance test infrastructure if SDD specifies throughput targets
```

---

## Edge cases

**No test plan page found**: if no "Test Plan: …" page exists in the space, run Loop A against test scenarios derived from the SDD's Testing sections and error tables; note the gap and flag the output as needing review against a formal test plan.

**SDD with no Testing section**: Loop B derives unit and integration tests from API specs and error tables only; note the gap.

**Monorepo / multi-service SDD**: ask the user which service(s) to implement; scope both loops to those only.

**SDD specifying infrastructure (Docker, Terraform, CI)**: implement config files in Loop B following the same generator → reviewer loop; verify by linting (`terraform validate`, `docker build`, `yamllint`) rather than unit/integration tests; Loop A skips pure-infra components.

**Conflicting SDD and existing code**: surface the conflict explicitly, ask the user which takes precedence before writing.

**Large SDD (10+ components)**: process Loop B in batches of 5, report progress after each batch, and confirm before continuing. Loop A processes all test groups up front.

## Additional resources

- **`references/implementation-patterns.md`** — language-specific patterns for common SDD constructs (REST handlers, ORMs, auth middleware, migrations)
