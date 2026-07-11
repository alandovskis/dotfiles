---
name: conventional-commits
description: Commit changes in logical groups using conventional commit style. Use this skill whenever the user asks to commit, create commits, stage and commit, or "commit everything" — even if they don't mention conventional commits or logical grouping. Also trigger when the user says things like "make commits for my changes", "commit these files", "save my work with git", or "push my changes" (for the commit step). The goal is to never create a single undifferentiated "WIP" commit when the changes naturally break into distinct concerns.
---

# Conventional Commits in Logical Groups

Your job is to analyse all uncommitted changes, divide them into cohesive logical groups, and produce one conventional commit per group — in a single focused pass.

## Why this matters

A commit is a unit of meaning, not a unit of time. When changes span multiple concerns (a new feature, a bug fix, a dependency bump), bundling them destroys history and makes bisect, revert, and review harder. Keeping commits focused makes the repository a reliable narrative.

## Step 1 — Survey the full diff

Run these in parallel to get a complete picture before touching anything:

```bash
git status
git diff HEAD          # everything: staged + unstaged
git diff --cached      # staged only
git stash list         # any stashed work
```

If there is nothing to commit, say so and stop.

## Step 2 — Identify logical groups

Read the diff carefully and group changes by *intent*, not by file type or category label. Ask yourself:

- What problem does this change solve, or what capability does it add?
- Would reverting this group leave the repo in a coherent, working state?
- Would a reviewer want to see this separately from the rest?

**Group by the specific thing being changed, not by broad category.** For example:
- Changes to `.vimrc` and changes to `.gitconfig` are two separate concerns (different tools, independent changes) — commit them separately even though both are "config files"
- Changes to `package.json` and `package-lock.json` belong together because they're one atomic dep bump
- A new feature file and its test file belong together

Common grouping signals:
- A new feature or behaviour (including its tests)
- A bug fix
- A dependency or lock-file update
- Changes to a specific tool's config (one commit per tool)
- Refactors with no behaviour change
- Documentation or comment updates
- CI/build pipeline changes
- Style / formatting (only if truly mechanical)

**When in doubt, fewer larger commits beat many tiny ones.** Don't manufacture groups — if everything genuinely serves one purpose, one commit is correct.

## Step 3 — Plan the commits

Before staging anything, lay out your plan:

```
Group 1: feat(auth): add JWT refresh token support
  Files: src/auth/jwt.ts, src/auth/refresh.ts, tests/auth/jwt.test.ts

Group 2: fix(api): return 401 instead of 500 on expired token
  Files: src/api/middleware.ts

Group 3: chore(deps): upgrade jose to 5.2.0
  Files: package.json, package-lock.json

Group 4: chore(vim): switch to 2-space indent and enable cursorline
  Files: .vimrc

Group 5: chore(git): set default editor and enable rebase on pull
  Files: .gitconfig
```

Show the user this plan. If any grouping is unclear, ask before proceeding.

## Step 4 — Commit each group

For each group, in order:

1. Stage exactly the files (or hunks) for that group:
   - Whole files: `git add <file> [<file> ...]`
   - Partial files: `git add -p <file>` (interactive hunk selection)
2. Verify staging is correct: `git diff --cached --stat`
3. Commit using a heredoc to avoid shell escaping issues:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<optional body — explain WHY, not WHAT>

<optional footer — breaking changes, issue refs>
EOF
)"
```

Repeat for every group. Never stage the next group until the current commit succeeds.

## Conventional commit format

```
<type>[(<scope>)]: <short description>
```

**Types:**

| Type | Use when |
|------|----------|
| `feat` | New feature or user-visible behaviour |
| `fix` | Bug fix |
| `refactor` | Restructure without behaviour change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no logic change |
| `build` | Build system, tooling |
| `ci` | CI/CD pipeline |
| `chore` | Maintenance: deps, config, generated files |
| `revert` | Reverting a previous commit |

**Rules:**
- Description: imperative mood, lowercase, no trailing period (`add`, not `adds` / `Added`)
- Scope: optional, lowercase, names the specific area affected (`auth`, `vim`, `git`, `deps`)
- Body: explain *why* the change was needed, not what the diff shows
- Breaking changes: add `BREAKING CHANGE:` in the footer, and optionally `!` after the type (`feat!:`)
- Keep the subject line under 72 characters

**Examples:**

```
feat(search): add full-text index on user email

fix: prevent crash when config file is missing

chore(deps): bump eslint from 8.x to 9.x

chore(vim): switch to 2-space indent and show cursor line

chore(git): set vim as editor and rebase as default pull strategy

refactor(db): extract connection pool into separate module

feat!: drop support for Node 16

BREAKING CHANGE: minimum required Node version is now 18
```

## Step 5 — Confirm

After all commits, run `git log --oneline -10` and show the result to the user so they can see the clean history.

## Edge cases

- **Mix of staged and unstaged changes:** unstage everything first (`git reset HEAD .`) so you control staging precisely.
- **Binary files or generated files:** group with the commit that necessitated them; if truly standalone, use `chore`.
- **Merge conflicts or rebase in progress:** stop and tell the user — don't commit during a conflicted state.
- **User wants a single commit despite multiple concerns:** respect their preference; suggest a `chore: update various things` or `feat: <main thing> (includes minor fixes)` with a descriptive body.
