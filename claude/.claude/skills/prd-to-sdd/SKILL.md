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

## Step 1: Gather inputs

If the user has not already provided both of the following, use AskUserQuestion to ask:

1. **PRD source** — Confluence page URL or page ID
2. **SDD destination** — Confluence space key and parent page title or URL (e.g. space: `ENG`, parent: `Design Documents/2024`)

## Step 2: Resolve cloud ID

Call `getAccessibleAtlassianResources`. Use the first result's `id` as `cloudId` for all subsequent calls.

## Step 3: Fetch the PRD

Extract the page ID from the URL:
- Tiny link: `/wiki/x/<ID>` — use `<ID>` directly
- Long format: `/wiki/spaces/<SPACE>/pages/<ID>/...` — use the numeric `<ID>`

Call `getConfluencePage` with `cloudId`, `pageId`, and `contentFormat: "markdown"`.

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

For **each requirement**, run these three passes internally before writing the final section:

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

### Pass 2 — Reviewer

Review the draft as a critical senior engineer. Check:

**Must pass** (block on any failure):
- Requirement is fully addressed — trace every clause of the requirement text
- No empty sections (only "N/A — reason" is acceptable)
- No internal contradictions
- No unowned TBDs

**Should pass** (revise if 2 or more fail):
- At least one alternative considered and rejected with a concrete reason
- Error table covers all five required conditions
- Schema changes include constraints and migration strategy
- Security checklist covered (auth, validation, PII)
- Test scenarios cover happy path, at least one error path, and one edge case

Output either:
- `APPROVED` — accept the section
- `REVISE:\n1. [section] — [specific gap and what to add]\n2. ...`

### Pass 3 — Revision

If REVISE: apply every cited gap. Re-run the reviewer once.

After the second revision, if still REVISE: accept the section with a `⚠️ Needs Human Review: [outstanding issues]` prefix. Maximum 2 revision rounds per requirement — never loop further.

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

Resolve the parent page: call `search` or `getConfluencePage` to find the parent page ID from the space key and path the user provided.

Call `createConfluencePage` with:
- `cloudId`
- `spaceKey` — user-provided space
- `title` — `"SDD: [PRD title]"`
- `parentId` — resolved parent page ID
- `content` — assembled SDD
- `contentFormat` — `"wiki"`

Convert markdown to Confluence wiki markup for headings (`h2.`), tables, and links (`[text|url]`).

If a page with that title already exists, call `updateConfluencePage` instead, or ask the user if they want a new page with a date suffix: `SDD: [PRD title] (YYYY-MM-DD)`.

On success:
> "✅ SDD published: [Confluence page URL]"

## Edge cases

**No explicit requirements section**: infer requirements from feature descriptions or user stories; group related items and confirm the grouping with the user before proceeding.

**Vague requirement**: generate the section with best effort, flag `⚠️ Insufficient detail — design decisions deferred`.

**Large PRD (10+ requirements)**: process in batches of 5 and report progress — "Processing requirements 1–5 of 14…"
