---
name: prd-to-sdd
description: |-
  Reads a PRD from a Confluence page and generates a Software Design Document
  using a generator-reviewer loop: one SDD section per requirement. Publishes
  the assembled SDD to Confluence under a user-specified space and parent page.
  Trigger when user says: "generate an SDD from a Confluence PRD", "convert PRD
  to SDD", "create a software design document from requirements", "write a design
  doc from a Confluence page", "/prd-to-sdd", or asks to turn a PRD into a design doc.
---

You are generating a Software Design Document (SDD) from a Confluence PRD. For each requirement, run an internal generator-reviewer loop to produce a high-quality design section, then publish the assembled SDD back to Confluence. Follow the steps below precisely.

## Step 1: Resolve cloud ID and choose source PRD

**1a. Resolve cloud ID** — call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

**1b. Choose the space** — call `getConfluenceSpaces` with `cloudId`. Do NOT pass any `type` filter — omitting it returns all spaces including collaboration spaces. Present every returned space to the user via AskUserQuestion and ask them to choose the space that contains the PRD.

**1c. Choose the PRD page** — call `getPagesInConfluenceSpace` with `cloudId` and the selected space's `id`. Present every returned page title to the user via AskUserQuestion and ask them to choose the PRD. If the space has more pages than fit in one response, paginate until all pages are listed before presenting.

**1d. Fetch the PRD** — use the selected page's `id` as `pageId`. Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

## Step 2: Choose SDD destination

**2a. Choose the destination space** — ask the user via AskUserQuestion whether to publish the SDD to the same space or a different one. If the same space, re-use the space `id` already resolved. If a different space, call `getConfluenceSpaces` again (no type filter) and present the list for the user to choose from.

**2b. Choose the parent page** — call `getPagesInConfluenceSpace` with `cloudId` and the destination space `id`. Present every returned page title via AskUserQuestion and ask the user to choose the parent page under which the SDD will be created. If they want it at the space root, include that as an explicit option.

Store the destination `spaceId` and `parentId` for use in Step 7.

## Step 4: Extract requirements

Parse the PRD content for individual requirements. They may appear as:
- A `## Requirements` table (columns: ID, title, description)
- A numbered or bulleted list of requirement statements
- Sections with requirement headings

For each requirement, record:
- **ID** — existing identifier or auto-generated (REQ-001, REQ-002…)
- **Title** — short label
- **Description** — full requirement text

Present the list to the user and confirm before generating:
> "I found [N] requirements: [list]. Shall I generate the SDD?"

If the document has no identifiable requirements, tell the user and stop.

## Step 5: Generator-reviewer loop — one section per requirement

For **each requirement**, run the following passes before writing the final section:

### Pass 1 — Generator

Draft the SDD section. Write from the perspective of an experienced software architect. Use concrete language — no "could", "might", or "should consider". Every sub-section below must be populated; write "N/A — [reason]" if it genuinely does not apply.

Section structure:

**Requirement Summary** — verbatim or paraphrased requirement text.

**Design Approach** — 2–4 paragraphs: chosen design and why, key architectural patterns, integration points with existing systems. Include an "Alternatives considered" table (approach vs. reason rejected).

**Data Model Changes** — new tables/collections/fields with schema (column types, constraints, indexes, migration strategy). If none: "N/A — no schema changes required."

**API / Interface Changes** — new or modified endpoints (method, path, auth, request/response shapes) and internal interfaces. If none: "N/A."

**Error Handling** — table: Condition | HTTP Status | Error Code | User-Facing Message. Must include at minimum: invalid input (400), not found (404), unauthorized (403), conflict (409), downstream failure (503).

**Security** — authentication requirement, authorization rules, input validation approach, PII handling.

**Testing** — at least 3 unit test scenarios and 2 integration test scenarios (state what is asserted, not just "write tests").

**Dependencies** — upstream (what this feature requires), downstream (what consumes it), blocking (other REQ IDs that must land first).

**Open Questions** — any unresolved design decisions with owner and target date. Omit if none.

### Pass 2 — Subagent Reviewer

Spawn a subagent using the Agent tool with the following prompt (substitute the actual requirement text and draft section):

> You are a critical senior software engineer reviewing a draft SDD section. Your only job is to find gaps — do not rewrite the section yourself.
>
> **Requirement:**
> [requirement ID, title, and full description]
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
>
> **Should pass** (flag if 2 or more fail):
> - At least one alternative considered and rejected with a concrete reason
> - Error table covers all five required conditions (400, 403, 404, 409, 503)
> - Schema changes include constraints and migration strategy
> - Security checklist covered (auth, validation, PII)
> - Test scenarios cover happy path, at least one error path, and one edge case
>
> Respond with exactly one of:
> - `APPROVED`
> - `REVISE:\n1. [section] — [specific gap and what to add]\n2. ...`

Wait for the subagent to return its verdict before proceeding.

### Pass 3 — Revision

If the subagent returned REVISE: apply every cited gap, then spawn a fresh reviewer subagent with the revised draft using the same prompt above.

After the second review, if still REVISE: accept the section with a `⚠️ Needs Human Review: [outstanding issues]` prefix. Maximum 2 revision rounds per requirement — never loop further.

---

## Step 6: Assemble the SDD

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

## Step 7: Publish to Confluence

Use the `spaceId` and `parentId` resolved in Step 2.

Call `createConfluencePage` with:
- `cloudId`
- `spaceId` — numeric ID resolved in Step 2
- `parentId` — resolved in Step 2 (omit if user chose space root)
- `title` — `"SDD: [PRD title]"`
- `body` — assembled SDD as HTML (headings, tables, lists — no `<html>`/`<head>`/`<body>` wrapper)
- `contentFormat` — `"html"`
- `status` — `"draft"`

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user if they want a new page with a date suffix: `SDD: [PRD title] (YYYY-MM-DD)`.

On success:
> "✅ SDD published: [Confluence page URL]"

## Edge cases

**No explicit requirements section**: infer requirements from feature descriptions or user stories; group related items and confirm the grouping with the user before proceeding.

**Vague requirement**: generate the section with best effort, flag `⚠️ Insufficient detail — design decisions deferred`.

**Large PRD (10+ requirements)**: process in batches of 5 and report progress — "Processing requirements 1–5 of 14…"
