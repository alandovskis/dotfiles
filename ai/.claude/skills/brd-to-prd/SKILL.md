---
name: brd-to-prd
description: |-
  Reads a BRD from a Confluence page and generates one or more properly-scoped
  Product Requirements Documents using a generator-reviewer loop: one PRD per
  logical product scope derived from the BRD's business requirements. Publishes
  all PRDs to Confluence under a user-specified space and parent page, each
  linked back to the source BRD.
  Trigger when user says: "generate PRDs from a BRD", "turn BRD into PRDs",
  "convert business requirements to product requirements", "create PRDs from a
  Confluence BRD", "/brd-to-prd", or asks to decompose a BRD into product specs.
---

You are decomposing a Business Requirements Document (BRD) into one or more properly-scoped Product Requirements Documents (PRDs). For each proposed PRD scope, run a generator-reviewer loop to produce a high-quality PRD, then publish all of them to Confluence. Follow the steps below precisely.

## Step 1: Gather inputs

If the user has not already provided the following, use AskUserQuestion to ask:

1. **BRD source** — Confluence page URL or page ID

Do not ask for the destination space yet — you will look it up and present options in Step 2b.

## Step 2: Resolve cloud ID

Call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

## Step 2b: Choose destination space and parent page

Call `getConfluenceSpaces` with the `cloudId`. Do NOT pass any `type` filter — omitting it returns all spaces including collaboration spaces. Present every returned space to the user via AskUserQuestion and ask them to choose one. Then ask whether to place the PRDs under a specific parent page (if yes, ask for the page title or URL) or at the space root.

## Step 3: Fetch the BRD

Extract the page ID from the URL:
- Tiny link: `/wiki/x/<ID>` — use `<ID>` directly
- Long format: `/wiki/spaces/<SPACE>/pages/<ID>/...` — use the numeric `<ID>`

Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

## Step 4: Extract business requirements and propose scoping

Parse the BRD content for:
- **Business Requirements** — table rows or list items (ID, title, description, priority, category, UI component)
- **Business Rules** — rules that constrain or govern the requirements
- **Constraints** — budget, timeline, regulatory, technology
- **Business Objectives** — the outcomes the business wants to achieve

For each business requirement, determine whether it has a UI component:
- Mark **Yes** when satisfying the requirement requires a user-facing screen, form, dashboard, report view, navigation, notification, visual workflow, or other interactive/visual interface.
- Mark **No** when the requirement is purely backend, integration, data processing, operational, policy, compliance, or infrastructure work with no user-facing surface.
- If the BRD is ambiguous, infer the most likely value from the requirement wording and add the uncertainty to the Notes field in the generated PRD requirement row.

Then propose a PRD scoping plan. Apply these rules:

**Scoping rules:**
- Group BRs that share a common user-facing capability or system boundary into one PRD.
- A single Must-priority BR that represents a major capability (ingestion, extraction, user-facing dashboard) warrants its own PRD.
- Should/Could BRs that are tightly coupled to a Must BR may be folded into that PRD.
- Do not create a PRD that spans unrelated capabilities — over-scoped PRDs produce vague requirements.
- Do not create a PRD for a single small BR that could reasonably be a sub-requirement in a sibling PRD.
- Aim for 3–7 PRD requirements per PRD; flag any proposed PRD with fewer than 2 or more than 8.

Present the scoping plan to the user:

> "Based on the BRD I found [N] business requirements. I propose [M] PRDs:
> - **PRD 1: [title]** — covers BR-001 (UI: Yes), BR-002 (UI: No) ([one-sentence rationale])
> - **PRD 2: [title]** — covers BR-003 (UI: Yes) ([one-sentence rationale])
> - …
>
> Shall I proceed, or would you like to adjust the scoping?"

Wait for user confirmation before generating. If the user adjusts the scoping, update the plan accordingly.

## Step 5: Generator-reviewer loop — one PRD per scope

For **each proposed PRD**, run the following passes. Use fresh (non-fork) subagents for reviewer and revision so they have no memory of generation reasoning.

### Pass 1 — Generator

Spawn a fresh subagent with this prompt (substitute the bracketed values):

> You are a senior product manager writing a Product Requirements Document. Return only the completed PRD in the exact Markdown format specified — no explanation or preamble.
>
> **Source BRD context**
> Title: [BRD title]
> Objectives: [business objectives from the BRD, verbatim]
> Constraints: [constraints from the BRD, verbatim]
>
> **Business requirements to cover in this PRD**
> [For each BR being covered: ID, title, full description, priority, UI component: Yes/No, business rules that apply]
>
> **PRD title**
> [proposed PRD title]
>
> **Instructions**
> Write a complete PRD using exactly the structure below. Every section must be populated — write "—" only for fields with no available information. The PRD must be a PRODUCT document: it describes what users need and why, not how engineers should build it.
>
> Rules:
> - User stories follow: *As a [persona], I want [action] so that [benefit].* The persona must be a real user type, not "the system".
> - Success metrics must have concrete numbers and timeframes derived from the BRD's business objectives.
> - Importance values: Must / Should / Could / Won't — derived from the source BR priority.
> - UI Component values: Yes / No — derived from whether the source BR requires a user-facing screen, form, dashboard, report view, navigation, notification, visual workflow, or other interactive/visual interface.
> - The Objective section describes user and business outcomes, not implementation.
> - Out of Scope must explicitly exclude anything from the BRD that this PRD does not cover, plus any adjacent capability that readers might assume is included.
> - Every requirement in the table must be independently testable.
> - Every requirement in the table must preserve the source BR's UI Component value. If the value is inferred from ambiguous wording, explain that uncertainty in Notes.
>
> ```markdown
> # [PRD title]
>
> ## Product Overview
>
> [One paragraph: what this product area does, who it serves, and why it matters. Written from the user's perspective.]
>
> ---
>
> **Target date:** [from BRD constraints]
> **Document status:** Draft
> **Source BRD:** [BRD title]
> **Covers BRD requirements:** [BR-IDs]
>
> **Team members:**
> | Name | Role |
> |------|------|
> | — | — |
>
> ---
>
> ## Quick Links
>
> - **Designs:** —
> - **Work tracker:** —
>
> ---
>
> ## Objective
>
> [Outcome-focused: the problem this PRD solves for users and the business result expected. No implementation language.]
>
> ---
>
> ## Success Metrics
>
> | Goal | Metric |
> |------|--------|
> | … | … |
>
> ---
>
> ## Assumptions
>
> - …
>
> ---
>
> ## Milestones
>
> | Milestone | Target Date |
> |-----------|-------------|
> | … | … |
>
> ---
>
> ## Requirements
>
> | Requirement | User Story | Importance | UI Component | Jira Issue | Notes |
> |-------------|------------|------------|--------------|------------|-------|
> | … | As a [persona], I want [action] so that [benefit]. | … | Yes/No | — | … |
>
> ---
>
> ## Out of Scope
>
> - …
>
> ---
>
> ## Design
>
> [Design notes or constraints from the BRD that are relevant to this PRD scope. If none: —]
>
> ---
>
> ## Open Questions
>
> | Question | Answer | Date Answered |
> |----------|--------|---------------|
> | … | … | … |
>
> ---
>
> ## Reference Links
>
> - Source BRD: [BRD Confluence URL]
> ```

Store the subagent's output as `draft`.

### Pass 2 — Reviewer

Spawn a fresh subagent with this prompt. Pass only the BRD context and `draft` — do not include any generation reasoning:

> You are a senior product manager doing an adversarial review of a PRD draft. Your only job is to find weaknesses — do not rewrite the PRD.
>
> **Source BRD requirements covered by this PRD:**
> [For each BR: ID, title, full description, priority, UI component: Yes/No]
>
> **Draft PRD:**
> [draft]
>
> **Must pass** (flag any failure with REVISE):
> - Every source BR is traceable to at least one row in the Requirements table.
> - No requirement row describes HOW to build something — each must describe WHAT the user needs.
> - Every user story follows: *As a [persona], I want [action] so that [benefit].* The persona must be a named user type, not "the system" or "the platform".
> - Every requirement is independently testable — no row depends on another row to be meaningful.
> - Every requirement row includes a UI Component value of `Yes` or `No`.
> - Every requirement row's UI Component value matches the source BR classification.
> - Out of Scope explicitly lists at least one adjacent capability that readers might assume is included.
>
> **Should pass** (flag if 2 or more fail with REVISE):
> - Success metrics have concrete numbers and timeframes, not "improve X" or "reduce Y".
> - Assumptions are stated as assumptions, not facts.
> - The Objective describes outcomes, not features or implementation steps.
> - Open Questions captures at least one genuine uncertainty relevant to this scope.
> - Milestone dates are present or explicitly deferred with a reason.
>
> Respond with exactly one of:
> - `APPROVED` (one optional sentence of commentary)
> - `REVISE:` followed by a numbered list where each item is: `[section] — [specific problem and exactly what to add or fix]`

Store the output as `review`.

### Pass 3 — Revision (only if `review` starts with `REVISE`)

Spawn a fresh subagent with this prompt:

> You are a product manager revising a PRD based on reviewer feedback. Return the complete revised PRD in the same Markdown format — all original content with corrections applied. Do not add content beyond what the feedback requires. Return the revised PRD as text — do NOT write any files.
>
> **Original draft:**
> [draft]
>
> **Reviewer feedback:**
> [review]
>
> Apply every numbered item in the feedback exactly.

Store the output as `revised_draft`. Then re-run Pass 2 (reviewer) against `revised_draft`.

**Termination:**
- Either review returns `APPROVED` → use that PRD as the final output for this scope.
- Second review still returns `REVISE` → accept `revised_draft` as-is; prepend `⚠️ Needs Human Review: [paste the outstanding reviewer items]` to the PRD title for this scope.
- Maximum 2 revision rounds. Never loop further.

---

## Step 6: Publish all PRDs to Confluence

### Resolve the space ID

Use the space `id` already obtained in Step 2b — do not call `getConfluenceSpaces` again.

### Resolve the parent page ID

If the user chose a parent page in Step 2b, call `searchConfluenceUsingCql` with:
`type = page AND space = "SPACEKEY" AND title = "Parent Page Title"`

Use the returned page ID as `parentId`. If no parent page was specified, omit `parentId`.

### Create one page per PRD

For each final PRD, call `createConfluencePage` with:
- `cloudId`
- `spaceId`
- `parentId` — if resolved above
- `title` — the PRD title (prefix `⚠️ ` if flagged for human review)
- `body` — the PRD converted to HTML (headings, tables, lists — no `<html>`/`<head>`/`<body>` wrapper)
- `contentFormat` — `"html"`
- `status` — `"draft"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user whether they want a date-suffixed title.

After all pages are created, report:

> "✅ [M] PRDs published:
> - [PRD 1 title]: [URL]
> - [PRD 2 title]: [URL]
> - …"

## Step 7: Traceability check

After publishing, verify that every BR from the BRD is covered by at least one published PRD. Report:

| BR ID | Title | UI Component | Covered by PRD |
|-------|-------|--------------|----------------|
| BR-001 | … | Yes/No | [PRD title] |
| BR-002 | … | Yes/No | [PRD title] |

If any BR is uncovered, flag it:
> "⚠️ The following BRD requirements are not covered by any PRD: [BR-IDs]. Would you like to create an additional PRD for these, or note them as out of scope?"

## Edge cases

**BRD has no Requirements section**: infer BRs from the Business Objectives and Scope sections; confirm the inferred list with the user before proceeding.

**Single BR covers an enormous capability**: propose splitting it into two PRDs by user persona or functional boundary; present the rationale to the user and ask for confirmation.

**Conflicting constraints between BRs being grouped**: surface the conflict explicitly in the Open Questions section of the generated PRD; do not silently pick one.

**Large BRD (8+ BRs)**: process PRDs in batches of 3 and report progress — "Generating PRD 1 of 4…"
