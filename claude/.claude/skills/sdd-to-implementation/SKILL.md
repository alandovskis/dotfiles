---
name: sdd-to-implementation
description: |-
  Reads a Software Design Document (SDD) from a Confluence page and implements
  the described system test-first: writes the full system test plan (red), then
  runs a planner → generator → reviewer loop per component until all tests pass
  (green). Trigger when user says:
  "implement from SDD", "implement the SDD from Confluence", "code up this design
  doc", "build from the software design document", "implement a Confluence SDD",
  "/sdd-to-implementation", or asks to turn a design document into working code
  and verify it with tests.
---

Implement production code from a Confluence Software Design Document (SDD) using a **test-first** (TDD) approach. Write the full system test plan before any implementation, then run a planner → generator → reviewer loop per component until every test is green. Follow these steps precisely.

## Step 1: Gather inputs

If the user has not already provided the following, use AskUserQuestion to ask:

1. **Target directory** — local path where code will be written (default: current working directory)
2. **Language / stack** — if not specified in the SDD, ask which language/framework to use

Do not ask for the SDD source — you will look it up from Confluence in Step 2.

## Step 2: Resolve cloud ID, choose space, choose page, fetch SDD

**2a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**2b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter — omitting it returns all spaces including collaboration spaces. Present every returned space to the user via AskUserQuestion and ask them to choose one.

**2c. Choose the SDD page** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. Present every returned page title to the user via AskUserQuestion and ask them to choose the SDD they want to implement. If the space has more pages than fit in one response, call again with the next cursor until all pages are listed.

**2d. Fetch the SDD** — use the selected page's `id` as `pageId`. Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

## Step 3: Extract design components

Parse the SDD for implementable units. These typically appear as:

- **API endpoints** — method, path, request/response schema, auth
- **Data models / schema** — tables, collections, fields, constraints
- **Service / module definitions** — class/function responsibilities, interfaces
- **Background jobs / workers** — triggers, payloads, failure handling
- **Configuration** — environment variables, feature flags

For each component, record:
- **ID** — existing identifier or auto-generated (COMP-001, COMP-002…)
- **Name** — short label (e.g. "User Registration API", "accounts table")
- **Type** — api | model | service | job | config
- **Specification** — full relevant SDD text

Detect **dependency order**: a component that another component consumes must be implemented first (e.g. data model before service, service before API handler).

Present the ordered list to the user and confirm before implementing:

> "I found [N] design components in dependency order:
> 1. COMP-001 (model) — accounts table
> 2. COMP-002 (service) — AuthService
> 3. COMP-003 (api) — POST /auth/register
> Shall I implement these in [target directory]?"

If the SDD has no identifiable components, tell the user and stop.

## Step 4: Planner pass

Before writing any code, produce a full implementation plan internally (do not show this to the user unless asked). The plan establishes:

- **File map** — for each component: which files to create or modify, with paths relative to the target directory
- **Interface contracts** — function signatures, class interfaces, or type definitions that cross component boundaries
- **Build order** — strict dependency sequence (models → repositories → services → handlers → routes)
- **Existing code audit** — read the target directory; identify files already present that the plan must integrate with rather than replace
- **Test plan** — all system test scenarios derived from the SDD, mapped to each component

Summarise the plan to the user in ≤15 lines, then proceed without waiting.

## Step 5: Write the full system test plan (red phase)

**Write all system tests before implementing any production code.** This is the red phase — every test must compile but fail at runtime because the code under test does not yet exist.

### Test derivation

For each component, derive test scenarios from:
- SDD "Testing" section (happy path, error paths, edge cases)
- SDD "Error Handling" table (one test per listed condition)
- SDD "API / Interface Changes" (one test per endpoint with valid and invalid inputs)

Minimum coverage per component:
- Happy path for every API endpoint and service method
- All error conditions from the SDD error table
- At least one edge case (boundary values, null/empty input)

### Writing the tests

Write tests to `tests/` or `__tests__/` (match the project convention). Each test must:
- Assert **observable output only** — HTTP status codes, response bodies, database state — not implementation internals
- Be **independent** — no shared mutable state between tests
- Have a name that states the scenario (`test_register_returns_201_on_valid_input`, `test_register_returns_400_on_missing_email`)
- Import the interfaces or routes that will be created — use the exact paths from the file map in Step 4

Where production code does not exist yet, write minimal stubs (empty function, route returning 501) so the test suite compiles. Log: `"Written system tests (red): [test file paths]"`.

### Confirm red

Run the test suite. **All tests must fail** (not compile-error — actually reach the assertion and fail). If any test passes without implementation, it is asserting nothing useful — fix the assertion.

Log the failure count: `"Red phase confirmed: [N] tests failing, 0 passing"`.

---

## Step 6: Generator → Reviewer loop per component (green phase)

For **each component** in dependency order, implement production code, then run the tests until the component's scenarios are green.

### Pass 1 — Generator

Write complete, production-ready code:

- Read existing files that this component extends or depends on before writing
- Match the project's naming conventions, import style, error handling idioms, and file layout
- Implement **all** SDD-specified behaviour — do not stub, TODO, or leave placeholders
- Include only the types, functions, and exports the SDD requires; do not add extras
- Write inline comments only where the SDD specifies a non-obvious constraint
- Remove any stubs written in Step 5 for this component

Write each file using the Write or Edit tool. Log: `"Implemented COMP-00X: [Name]"`.

### Pass 2 — Reviewer (subagent)

Spawn a subagent via the Agent tool with this prompt (substitute actual values):

> You are a critical senior engineer reviewing an implementation against its SDD specification. Find gaps only — do not rewrite code yourself.
>
> **Component:** [ID] [Name] ([Type])
>
> **SDD specification:**
> [full relevant SDD text for this component]
>
> **Files implemented:**
> [list of file paths written in Pass 1]
>
> **Code content:**
> [full content of each written file]
>
> Review against these criteria:
>
> **Must pass** (flag any failure):
> - Every SDD-specified field, endpoint, method, or behaviour is present
> - No unimplemented stubs or TODOs remain
> - Error handling matches SDD error table (correct status codes, error codes)
> - Security rules from SDD are enforced (auth checks, input validation, PII handling)
> - No regressions in files that were modified (pre-existing interfaces unchanged)
>
> **Should pass** (flag if 2 or more fail):
> - Naming matches SDD exactly (table names, field names, endpoint paths)
> - Response shapes match SDD schema
> - Constraints and indexes from SDD data model are present
> - Auth/authz requirements are enforced at the correct layer
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [file:line-range] — [specific gap and what to add]\n2. ...`

Wait for the subagent to return its verdict.

### Pass 3 — Revision

If the subagent returned `REVISE:`: apply every cited gap using Edit or Write, then spawn a fresh reviewer subagent with the revised code using the same prompt.

After the second review, if still `REVISE:`: mark the component `⚠️ Needs Human Review: [outstanding issues]` and continue to the next component. Maximum 2 revision rounds per component — never loop further.

### Run tests after each component

After each component's reviewer approves (or is marked ⚠️), run the full test suite:

Detect the test command from:
1. `package.json` scripts (`test`, `test:integration`)
2. `Makefile` targets (`make test`, `make test-integration`)
3. Language defaults (`pytest`, `go test ./...`, `cargo test`)

If the project requires a running server or database, check `docker-compose.yml` or similar; start services if needed using Bash.

For any newly failing test:
1. Read the failing test and the implementation file it exercises
2. Fix the implementation (not the test) if the SDD backs the expected behaviour
3. Fix the test only if the assertion is wrong relative to the SDD
4. Re-run after each fix; do not accumulate fixes and re-run once

Stop after 3 fix-and-rerun cycles per failing test; mark it `⚠️ Test unresolved` with the error output.

Log progress: `"After COMP-00X: [P] passing / [F] failing"`.

---

## Step 7: Summary report

Present a concise implementation report:

```
## Implementation complete

**Source SDD:** [Confluence link]
**Target directory:** [path]
**Test suite:** [test file paths]

### Red phase
[N] tests written, all confirmed failing before implementation.

### Components ([N] total)

| ID | Name | Status | Files |
|----|------|--------|-------|
| COMP-001 | accounts table | ✅ | db/schema.sql, db/migrations/001_accounts.sql |
| COMP-002 | AuthService | ✅ | src/services/auth.ts |
| COMP-003 | POST /auth/register | ⚠️ Needs Human Review | src/routes/auth.ts |

### Green phase — system tests

| Scenario | Component | Status |
|----------|-----------|--------|
| register returns 201 on valid input | COMP-003 | ✅ |
| register returns 400 on missing email | COMP-003 | ✅ |
| register returns 409 on duplicate email | COMP-003 | ✅ |
| login returns 401 on wrong password | COMP-004 | ⚠️ Test unresolved |

**Final:** [P] passing / [F] failing

### Outstanding issues
- COMP-003: [specific gap from reviewer]
- login 401 test: [error output]

### Next steps
- [ ] Resolve ⚠️ items above
- [ ] Add load / performance tests if SDD specifies throughput targets
- [ ] Wire up to CI pipeline
```

---

## Edge cases

**SDD with no Testing section**: derive test scenarios from API specs and error tables only; note the gap.

**Monorepo / multi-service SDD**: ask the user which service(s) to implement; scope the plan to those only.

**SDD specifying infrastructure (Docker, Terraform, CI)**: implement config files following the same generator → reviewer loop; skip system tests for pure infra — verify by linting (`terraform validate`, `docker build`, `yamllint`).

**Conflicting SDD and existing code**: surface the conflict explicitly, ask the user which takes precedence before writing.

**Large SDD (10+ components)**: process in batches of 5, report progress, and confirm before continuing.

## Additional resources

- **`references/implementation-patterns.md`** — language-specific patterns for common SDD constructs (REST handlers, ORMs, auth middleware, migrations)
