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
- Could authorization, tenant boundaries, secrets, personal data, validation, or
  output encoding be bypassed or exposed?
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

### 4. Delegate test-evidence assessment

When delegated review is available and the change affects behavior, assign an
independent subagent a bounded, read-only assessment of test evidence. The primary
reviewer remains responsible for validating its evidence and deciding whether to
raise a finding.

Ask the subagent to:

- Map each changed behavior and credible risk to evidence at the relevant test
  boundary. Do not require every behavior to have all three layers.
- Classify tests by what they actually exercise, not their filename or framework:
  - **Unit:** an isolated component with controlled collaborators.
  - **Integration:** an interaction across internal boundaries or with a real or
    faithful test instance of a dependency.
  - **System:** an externally observable workflow through production-like entry
    points.
- Inspect test setup, inputs, boundaries crossed, assertions, and relevant test
  commands or configuration. Run narrow existing checks or coverage collection
  only when available and proportionate.
- Return a behavior-to-evidence matrix:

  ```text
  Changed behavior/risk | Unit evidence | Integration evidence | System evidence |
  Observable/assertion | Command and result | Gap or confidence
  ```

- Cite test locations and command output or artifacts. Mark unavailable,
  untested, blocked, and not applicable distinctly, with a reason.
- Do not edit code, invent tests, infer a test layer from its name, or turn a
  coverage number into a correctness claim.

Treat line and branch coverage as supplementary signals only. Assess whether the
test evidence exercises meaningful behavior, including relevant failure,
compatibility, contract, and side-effect paths. A missing layer is a finding only
when it leaves a specific, credible, material risk untested.

### 5. Delegate simplification assessment

When delegated review is available, assign an independent subagent a bounded,
read-only search for behavior-preserving simplification opportunities. The primary
reviewer validates its evidence and decides whether to raise a finding.

Ask the subagent to examine changed code and its immediate dependencies for:

- **KISS:** needless indirection, state, branching, or control flow that obscures
  a straightforward implementation.
- **YAGNI:** speculative generality, extension points, configuration, or
  abstractions with no current caller or stated requirement.
- Redundant logic, unreachable code, duplicate representations of the same state,
  and obsolete compatibility paths that the change makes unnecessary.

For every candidate, establish all of the following:

1. Identify the concrete code and behavior it currently provides.
2. Trace callers, configuration, public contracts, tests, and relevant runtime
   paths to show that removal or consolidation preserves required behavior.
3. Show a concrete payoff: fewer states, branches, dependencies, interfaces, or
   maintenance paths—not merely a personal preference.
4. State any unverified assumption or compatibility risk.

Return only substantiated candidates in this format:

```text
Candidate | Location | Evidence of unnecessary complexity | Behavior-preserving
simplification | Expected payoff | Compatibility assumptions | Confidence
```

Do not edit code. Do not propose style-only rewrites, renames, formatting,
subjective cleanliness, broad redesigns, or simplifications that change public
contracts, error handling, security boundaries, observability, performance
characteristics, or supported configuration unless the change explicitly permits
it. Omit a candidate when reachability, callers, or required behavior cannot be
verified.

### 6. Calibrate severity

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

## Final response

Return findings first, ordered P0 through P3. If there are no actionable
findings, say exactly: `No actionable findings.`

After findings, optionally include:

- `Residual risks:` assumptions or unverified paths that are important but not
  proven defects.
- `Checks:` relevant checks run and their results, plus meaningful limitations.
- `Test evidence:` the validated behavior-to-evidence matrix or a concise summary
  of it when test coverage materially affects the review.
- `Simplification opportunities:` the validated candidate matrix, excluding
  candidates that do not meet the finding standard.

Do not dilute findings with praise, a diff summary, or generic advice. Do not
claim the change is correct; state only the level of confidence justified by the
evidence.
