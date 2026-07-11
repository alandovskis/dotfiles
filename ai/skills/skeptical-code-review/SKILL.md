---
name: skeptical-code-review
description: >-
  Review a code change with evidence-based skepticism. Use for pull-request, diff,
  patch, or change reviews when correctness, regressions, security, reliability,
  data integrity, performance, or missing tests may be at risk. Report only
  actionable findings that the change introduces or materially worsens.
---

# Skeptical Code Review

Review as an independent engineer trying to disprove that the change is safe.
Be rigorous, but do not manufacture findings. A quiet review is preferable to a
weak objection.

## Core standard

Raise a finding only when all of these are true:

1. **Specific:** You can identify the changed code and the relevant execution path.
2. **Credible:** You can explain a realistic input, state, timing, environment, or
   caller that triggers the problem.
3. **Caused by this change:** The issue is introduced by the change or meaningfully
   worsened by it; do not report an unrelated pre-existing defect as a change
   blocker.
4. **Material:** It affects correctness, security, reliability, data integrity,
   compatibility, performance at expected scale, or maintainability enough to
   justify the author's attention.
5. **Actionable:** The author can take a concrete next step from the finding.

If any condition is missing, investigate further or omit the finding. State
uncertainty plainly; never present a guess as a defect.

## Review workflow

### 1. Establish intent and boundaries

- Read the change description, issue context, tests, and the complete diff.
- Identify the behavior that is meant to change and the behavior that must remain
  unchanged.
- Inspect the surrounding implementation, direct callers, data contracts,
  configuration, and error paths. Do not review isolated lines without their
  context.
- Treat generated files, formatting-only changes, and explicitly accepted tradeoffs
  according to their stated scope.

### 2. Build a failure model

For each changed behavior, actively ask:

- What happens for empty, malformed, oversized, duplicated, or boundary inputs?
- What happens when dependencies fail, time out, return partial results, or are
  retried?
- What happens with concurrent requests, repeated delivery, cancellation, restart,
  stale state, or partial completion?
- Could serialization, schema, API, database, configuration, or command-line
  compatibility break existing consumers?
- Could the new ordering, caching, resource use, or algorithm become unsafe at
  expected production scale?
- Which invariant is assumed here, and where is it enforced?

Prioritize paths that can lose or corrupt data, weaken security, make the system
unavailable, or silently produce a wrong result.

### 3. Verify with evidence

- Trace the relevant code path rather than inferring behavior from names or
  comments.
- Compare old and new behavior when a regression is alleged.
- Inspect tests for both coverage and meaningful assertions; a passing test does
  not prove the asserted behavior is the one users need.
- Run the narrowest relevant checks when they are available and proportionate to
  the change. Report checks that could not be run only when that meaningfully
  limits confidence.
- Distinguish facts observed in code or test output from assumptions that need
  confirmation.

### 4. Delegate focused assessments

Assign independent, bounded, read-only subagents as follows. Give each the full
change context, relevant source and tests, and the named reference file. Validate
their evidence before raising a finding.

| Trigger | Subagent reference |
| --- | --- |
| The change affects behavior | [Test-evidence assessment](references/test-evidence-assessment.md) |
| The change touches a trust boundary, identity decision, data handling, external interaction, configuration, dependency, or privileged operation | [Security assessment](references/security-assessment.md) |
| A PRD is provided, linked, or discoverable | [PRD-compliance assessment](references/prd-compliance-assessment.md) |
| Always | [Simplification assessment](references/simplification-assessment.md) |
| The change affects domain behavior | [Domain-model assessment](references/domain-model-assessment.md) |

### 5. Calibrate severity

Use these priorities:

| Priority | Meaning |
| --- | --- |
| P0 | Blocks release: broad outage, critical security exposure, or likely irreversible data loss. |
| P1 | Must fix before merge: a realistic path yields incorrect behavior, security failure, or material reliability/data-integrity harm. |
| P2 | Should fix soon: a bounded but meaningful defect, regression, or missing protection that can affect users or operators. |
| P3 | Minor: low-impact improvement with a concrete benefit. Do not use P3 for taste or hypothetical concerns. |

Do not inflate severity for theoretical paths that require an unsupported
assumption. Do not downgrade a credible security or data-integrity issue because
it is uncommon.

## What to report

Each finding must be concise and self-contained:

```text
[P1] Short imperative title

Location: path/to/file.ext:line

Explain the triggering condition, the observed consequence, and why this change
causes it. Include only the minimum context needed to establish the claim.
Suggest a direction for the fix when it is clear.
```

Use a narrow location that overlaps the change. One finding should describe one
root cause; do not combine unrelated problems.

## What not to report

- Style preferences, naming taste, or refactors with no demonstrated payoff.
- Missing tests when the changed code is already adequately exercised, or when no
  specific untested risk can be named.
- PRD-compliance claims without an identified applicable requirement and a
  traceable implementation mismatch.
- Treating an unavailable, ambiguous, contradictory, or non-applicable PRD as
  evidence that the change is wrong.
- Speculative race conditions, performance concerns, or security issues without a
  plausible path.
- Pre-existing issues unless the change makes them worse or prevents a safe fix.
- Requests for broad redesign when a local, reviewable correction addresses the
  actual problem.
- Simplification suggestions without evidence of a concrete reduction and a
  behavior-preserving path.
- Removing apparent dead code or unused options without tracing dynamic callers,
  configuration, generated code, and compatibility commitments.
- Replacing explicit, locally understandable code with a cleverer construct or
  abstraction merely to reduce lines.
- Duplicates of another finding.

## Optional `--fix` mode

When invoked with `--fix`, complete the review and validate findings before
editing. Subagents remain read-only; the primary reviewer owns every change.

Fix only findings that are:

- Confirmed by the review evidence and introduced or materially worsened by the
  change under review.
- Local, behavior-preserving except for correcting the defect, and within the
  requested change's scope.
- Safe to verify with focused tests, checks, or a direct reproduction.

Do not use `--fix` for speculative concerns, broad redesigns, unverified security
or compatibility assumptions, unrelated cleanup, dependency upgrades, or changes
that require product, architectural, or operational approval. Report those as
findings or residual risks instead.

For every applied fix:

1. State the finding and evidence that justified it.
2. Make the smallest appropriate change.
3. Run the narrowest relevant verification.
4. Report the modified files, verification result, and remaining limitations.

## Final response

Return findings first, ordered P0 through P3. If there are no actionable
findings, say exactly: `No actionable findings.`

In `--fix` mode, lead with `Applied fixes:` before any remaining findings.

After findings, optionally include:

- `Residual risks:` assumptions or unverified paths that are important but not
  proven defects.
- `Checks:` relevant checks run and their results, plus meaningful limitations.
- `Test evidence:` the validated behavior-to-evidence matrix or a concise summary
  of it when test coverage materially affects the review.
- `Security evidence:` the validated security assessment or material residual
  risks when security review materially affects the result.
- `PRD compliance:` the validated requirements-to-evidence matrix when a PRD was
  available and materially informed the review.
- `Simplification opportunities:` the validated candidate matrix, excluding
  candidates that do not meet the finding standard.
- `Domain-model evidence:` the validated domain-rule or boundary assessment when
  it materially affects the review.

Do not dilute findings with praise, a diff summary, or generic advice. Do not
claim the change is correct; state only the level of confidence justified by the
evidence.
