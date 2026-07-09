---
name: prd
description: |-
  Generate a Product Requirements Document (PRD) by interactively gathering information
  from the user and producing a structured Markdown document. Covers product overview,
  objective, success metrics, assumptions, milestones, requirements table, out-of-scope,
  design notes, open questions, and reference links.
  Trigger when user says: "create a PRD", "write a PRD", "product requirements document",
  "draft a PRD for", "/prd", or describes a feature and wants it formally documented.
---

You are helping the user create a Product Requirements Document (PRD). Gather the necessary information through targeted questions, then produce a polished Markdown document following the exact template below.

## Step 1: Gather information

If the user invoked this skill with a feature or product name in their message, use it as context. Then use AskUserQuestion to collect the following in batches (max 4 questions per call):

**Round 1 — Overview & ownership:**
1. What is the product / feature name and a one-sentence description?
2. What is the target ship date?
3. What is the current document status? (e.g. Draft, In Review, Approved)
4. Who are the team members and their roles?

**Round 2 — Goals & links:**
1. What is the objective? (the "why" — problem being solved, outcome desired)
2. What are the success metrics? (provide as Goal → Metric pairs, e.g. "Increase activation → 30-day retention ≥ 40%")
3. Are there any quick links to share? (designs, Loom demo, work tracker — skip any that don't exist yet)

**Round 3 — Scope & requirements:**
1. What assumptions is the team making?
2. What are the key milestones and target dates?
3. List the requirements. For each, provide: requirement name, user story ("As a … I want … so that …"), importance (Must / Should / Could / Won't), Jira issue key (optional), and any notes.
4. What is explicitly out of scope?

**Round 4 — Design & questions:**
1. Any design notes or constraints worth capturing?
2. Are there any open questions? (provide question text, answer if known, and date answered if resolved)
3. Any reference links (RFCs, prior art, analytics dashboards, etc.)?

Skip any round or question the user marks as not applicable. If anything is ambiguous, confirm before generating the final document.

## Step 2: Generate a draft PRD

Produce a first-draft Markdown document using exactly this structure:

```markdown
# [Product / Feature Name]

## Product Overview

[One-paragraph summary of what this is and why it matters.]

---

**Target date:** [date]

**Document status:** [status]

**Team members:**
| Name | Role |
|------|------|
| … | … |

---

## Quick Links

- **Designs:** [link or —]
- **Loom demo:** [link or —]
- **Work tracker:** [link or —]

---

## Objective

[Clear statement of the problem being solved and the desired outcome.]

---

## Success Metrics

| Goal | Metric |
|------|--------|
| … | … |

---

## Assumptions

- …

---

## Milestones

| Milestone | Target Date |
|-----------|-------------|
| … | … |

---

## Requirements

| Requirement | User Story | Importance | Jira Issue | Notes |
|-------------|------------|------------|------------|-------|
| … | … | … | … | … |

---

## Out of Scope

- …

---

## Design

[Design notes, constraints, or link to design artifacts.]

---

## Open Questions

| Question | Answer | Date Answered |
|----------|--------|---------------|
| … | … | … |

---

## Reference Links

- …
```

## Formatting rules

- Use `—` for any field the user said is not applicable or unknown.
- Importance values must be one of: **Must**, **Should**, **Could**, **Won't**.
- User stories follow the format: *As a [persona], I want [action] so that [benefit].*
- Keep the Objective section focused on outcomes, not implementation.
- Do not add sections beyond the template above.

## Step 3: Fork a reviewer subagent

Use the `Agent` tool with `subagent_type: "fork"` to spawn an independent reviewer. The fork inherits your conversation context, so pass the draft PRD explicitly in the prompt. The reviewer must have no access to your reasoning — it evaluates only what you give it.

Reviewer prompt to use (substitute `{{DRAFT}}` with the full draft markdown):

> You are a senior product manager doing an adversarial review of the following PRD draft. Your job is to find weaknesses, not validate. Be specific and brutal.
>
> Evaluate each of these dimensions and list concrete, actionable findings (not vague praise):
> 1. **Clarity** — Is the objective outcome-focused or vague/implementation-focused?
> 2. **Completeness** — Are any sections thin, missing, or contradictory? Are requirements atomic and testable?
> 3. **Measurability** — Do success metrics have concrete numbers and timeframes, or are they hand-wavy?
> 4. **Scope discipline** — Does anything in Requirements belong in Out of Scope, or vice versa?
> 5. **Assumption validity** — Are assumptions stated as facts when they should be flagged as risks?
> 6. **User stories** — Do they follow "As a [persona], I want [action] so that [benefit]" and describe user value, not technical tasks?
>
> Return ONLY a numbered list of specific improvements. If a section is genuinely solid, skip it. Do not reproduce the PRD.
>
> ---
> {{DRAFT}}

Wait for the fork to return its findings.

## Step 4: Revise

Apply all findings from the reviewer to produce a revised PRD. Output only the final revised document — do not show the review notes or a diff.

## Step 5: Offer to save or publish

After outputting the revised document, use AskUserQuestion to ask:
1. Would you like to save this as a `.md` file locally? (provide a suggested slugified filename, e.g. `prd-feature-name.md`)
2. Would you like to publish this to Confluence? If yes, what space and parent page should it live under?

If the user wants a local file, write it to the current directory with the agreed filename.

If the user wants to publish to Confluence, proceed to **Step 5a**.

### Step 5a: Publish to Confluence

1. **Resolve the cloud ID** — call `getAccessibleAtlassianResources` to get the user's Confluence cloud ID.

2. **Resolve the space** — call `getConfluenceSpaces` with the cloud ID. If the user gave a space key, filter by it. If ambiguous, present the matching spaces and ask the user to confirm.

3. **Resolve the parent page** — if the user specified a parent page title or path, call `searchConfluenceUsingCql` with a CQL query like:
   `type = page AND space = "SPACEKEY" AND title = "Parent Page Title"`
   Use the returned page ID as `parentId`. If the user did not specify a parent page, create the page at the space root (omit `parentId`).

4. **Convert the PRD to HTML** — render the Markdown PRD as clean HTML suitable for Confluence (headings, paragraphs, `<table>` for tables, `<ul>`/`<ol>` for lists). Do not wrap in `<html>`, `<head>`, or `<body>` tags.

5. **Create the page** — call `createConfluencePage` with:
   - `cloudId` — resolved above
   - `spaceId` — resolved above
   - `parentId` — resolved above (if applicable)
   - `title` — the PRD feature name
   - `body` — the HTML content
   - `contentFormat` — `"html"`
   - `status` — `"current"` (published) or `"draft"` based on the document status field in the PRD

6. **Confirm** — report the URL of the created page to the user.

## Step 6: User iteration loop

After presenting the revised PRD, ask the user: "Would you like any changes?" If yes, apply their feedback, then repeat Steps 3–4 (fork reviewer + revise) before presenting the updated version. If the document was already published to Confluence, offer to update it via `updateConfluencePage` after each accepted revision. Continue until the user is satisfied.
