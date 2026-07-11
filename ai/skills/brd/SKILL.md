---
name: brd
description: |-
  Generate a Business Requirements Document (BRD) by interactively gathering information
  from the user and producing a structured Markdown document. Covers executive summary,
  business context, objectives, stakeholders, business requirements, business rules,
  constraints, risks, success criteria, and approvals.
  Trigger when user says: "create a BRD", "write a BRD", "business requirements document",
  "draft a BRD for", "/brd", or describes a business initiative and wants it formally documented.
---

You are helping the user create a Business Requirements Document (BRD). Gather the necessary information through targeted questions, then produce a polished Markdown document following the exact template below.

**Host and connector independence:** Use the current host's equivalent interaction, filesystem, and Confluence connector capabilities. Names such as `getConfluenceSpaces` describe the required Confluence operation, not a required host-specific tool name.

## Step 1: Gather information

If the user invoked this skill with a project or initiative name in their message, use it as context. Then use the host's user-interaction mechanism to collect the following in batches (max 4 questions per call):

**Round 1 — Overview & ownership:**
1. What is the project / initiative name and a one-sentence description?
2. What is the target completion date?
3. What is the current document status? (e.g. Draft, In Review, Approved)
4. Who is the document author and who are the key stakeholders (name, role, department)?

**Round 2 — Business context & objectives:**
1. What is the business problem or opportunity being addressed? (the "why now")
2. What are the business objectives? (the outcomes the organisation wants to achieve)
3. What are the success criteria / KPIs? (provide as Objective → Measurable Target pairs, e.g. "Reduce manual processing → cut processing time by 40% within 6 months")
4. Are there any quick links to share? (business case, exec sponsor deck, work tracker — skip any that don't exist yet)

**Round 3 — Scope & requirements:**
1. What is explicitly in scope?
2. What is explicitly out of scope?
3. List the business requirements. For each, provide: requirement name, business need ("In order to [outcome], [stakeholder] must be able to [capability]"), priority (Must / Should / Could / Won't), category (Functional / Non-functional / Regulatory / Data), and any notes.
4. Are there any business rules that govern this initiative? (policies, calculations, decision logic, regulatory mandates)

**Round 4 — Constraints, risks & approvals:**
1. What constraints apply? (budget ceiling, hard deadlines, technology limitations, regulatory requirements)
2. What assumptions is the team making?
3. What risks have been identified? For each: risk description, likelihood (High / Medium / Low), impact (High / Medium / Low), and proposed mitigation.
4. Who must sign off on this document and by when?

Skip any round or question the user marks as not applicable. If anything is ambiguous, confirm before generating the final document.

## Step 2: Generate a draft BRD

Produce a first-draft Markdown document using exactly this structure:

```markdown
# [Project / Initiative Name]
### Business Requirements Document

## Document Information

| Field | Value |
|-------|-------|
| **Author** | … |
| **Status** | … |
| **Target Date** | … |
| **Version** | 1.0 |

---

## Quick Links

- **Business Case:** [link or —]
- **Executive Deck:** [link or —]
- **Work Tracker:** [link or —]

---

## Executive Summary

[2–3 sentences: what this initiative is, the problem it solves, and the primary business outcome expected.]

---

## Business Context

### Problem Statement

[Clear description of the current-state pain points, inefficiencies, or missed opportunities that prompted this initiative.]

### Opportunity

[Description of what becomes possible if this initiative succeeds — market, operational, or strategic upside.]

---

## Business Objectives

| # | Objective | Success Metric | Target |
|---|-----------|----------------|--------|
| 1 | … | … | … |

---

## Stakeholders

| Name | Role | Department | Interest / Influence |
|------|------|------------|----------------------|
| … | … | … | … |

---

## Scope

### In Scope

- …

### Out of Scope

- …

---

## Business Requirements

| ID | Requirement | Business Need | Priority | Category | Notes |
|----|-------------|---------------|----------|----------|-------|
| BR-001 | … | In order to [outcome], [stakeholder] must be able to [capability] | … | … | … |

---

## Business Rules

| ID | Rule | Source / Authority |
|----|------|--------------------|
| RULE-001 | … | … |

---

## Constraints

| Type | Description |
|------|-------------|
| Budget | … |
| Timeline | … |
| Regulatory | … |
| Technology | … |

---

## Assumptions & Dependencies

### Assumptions

- …

### Dependencies

- …

---

## Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| RISK-001 | … | … | … | … |

---

## Approvals

| Name | Role | Signature | Date |
|------|------|-----------|------|
| … | … | Pending | … |

---

## Glossary

| Term | Definition |
|------|------------|
| … | … |
```

## Formatting rules

- Use `—` for any field the user said is not applicable or unknown.
- Priority values must be one of: **Must**, **Should**, **Could**, **Won't**.
- Category values must be one of: **Functional**, **Non-functional**, **Regulatory**, **Data**.
- Likelihood and Impact values must be one of: **High**, **Medium**, **Low**.
- Business needs follow the format: *In order to [outcome], [stakeholder] must be able to [capability].*
- The Executive Summary must describe business value, not implementation approach.
- Do not add sections beyond the template above.

## Step 3: Run an independent reviewer pass

Use a fresh reviewer agent or isolated review context when the host supports delegation. Pass the draft BRD explicitly and give the reviewer only the material below. If delegation is unavailable, perform the reviewer pass yourself without relying on generation reasoning. The reviewer evaluates only the supplied draft.

Reviewer prompt to use (substitute `{{DRAFT}}` with the full draft markdown):

> You are a senior business analyst doing an adversarial review of the following BRD draft. Your job is to find weaknesses, not validate. Be specific and actionable.
>
> Evaluate each of these dimensions and list concrete findings (not vague praise):
> 1. **Business clarity** — Does the Problem Statement clearly articulate pain points with evidence? Is the Opportunity grounded in business reality or is it aspirational fluff?
> 2. **Objective measurability** — Do Business Objectives have concrete, time-bound success metrics, or are they hand-wavy statements?
> 3. **Requirement quality** — Are Business Requirements atomic and testable? Do they express WHAT the business needs, not HOW to build it? Does each Business Need follow the mandated format?
> 4. **Stakeholder completeness** — Are any decision-makers, impacted teams, or regulatory bodies missing from the stakeholder list?
> 5. **Scope discipline** — Is anything in scope that should be out of scope, or vice versa? Are there hidden assumptions smuggled into scope statements?
> 6. **Risk realism** — Are risks specific and plausible, or generic filler? Does every High-impact risk have a concrete mitigation?
> 7. **Business rules coverage** — Are there implicit rules in the requirements that should be surfaced as explicit Business Rules?
>
> Return ONLY a numbered list of specific improvements. If a section is genuinely solid, skip it. Do not reproduce the BRD.
>
> ---
> {{DRAFT}}

Complete the reviewer pass before continuing.

## Step 4: Revise

Apply all findings from the reviewer to produce a revised BRD. Output only the final revised document — do not show the review notes or a diff.

## Step 5: Offer to save or publish

After outputting the revised document, use the host's user-interaction mechanism to ask:
1. Would you like to save this as a `.md` file locally? (provide a suggested slugified filename, e.g. `brd-initiative-name.md`)
2. Would you like to publish this to Confluence?

If the user wants a local file, write it to the current directory with the agreed filename.

If the user wants to publish to Confluence, proceed to **Step 5a**.

### Step 5a: Publish to Confluence

1. **Resolve the cloud ID** — call `getAccessibleAtlassianResources` to get the user's Confluence cloud ID.

2. **Choose the space** — call `getConfluenceSpaces` with the cloud ID to retrieve all available spaces. Present every returned space using the host's user-interaction mechanism and ask the user to select one. Do not ask the user to type a space key.

3. **Choose the parent page** — ask the user, using the host's user-interaction mechanism, whether to place the BRD under a specific parent page or at the space root. If they specify a parent page, call `searchConfluenceUsingCql` with:
   `type = page AND space = "SPACEKEY" AND title = "Parent Page Title"`
   Use the returned page ID as `parentId`. If they choose the space root, omit `parentId`.

4. **Convert the BRD to HTML** — render the Markdown BRD as clean HTML suitable for Confluence (headings, paragraphs, `<table>` for tables, `<ul>`/`<ol>` for lists). Do not wrap in `<html>`, `<head>`, or `<body>` tags.

5. **Create the page** — call `createConfluencePage` with:
   - `cloudId` — resolved above
   - `spaceId` — resolved above
   - `parentId` — resolved above (if applicable)
   - `title` — the BRD initiative name
   - `body` — the HTML content
   - `contentFormat` — `"html"`
   - `status` — `"current"` (published) or `"draft"` based on the document status field in the BRD

6. **Confirm** — report the URL of the created page to the user.

## Step 6: User iteration loop

After presenting the revised BRD, ask the user: "Would you like any changes?" If yes, apply their feedback, then repeat Steps 3–4 (independent review + revise) before presenting the updated version. If the document was already published to Confluence, offer to update it via `updateConfluencePage` after each accepted revision. Continue until the user is satisfied.
