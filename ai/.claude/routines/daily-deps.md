# Daily Dependency Audit

Audit all dependency manifests in the current project for security, freshness, and compatibility issues.

## Steps

1. Locate dependency files: `package.json`, `Gemfile`, `requirements.txt`, `Cargo.toml`, `go.mod`, `*.podspec`, etc.
2. For each manifest found:
   - List outdated packages (use the appropriate tool: `npm outdated`, `bundle outdated`, `pip list --outdated`, `cargo outdated`, `go list -m -u all`, etc.)
   - Flag any packages with known CVEs or security advisories
   - Note packages that are pinned to very old majors (lagging > 1 major version)
3. Summarize findings grouped by severity: **critical** (CVEs), **stale** (> 1 major behind), **minor** (patch/minor updates available)
4. Suggest upgrade commands for critical and stale packages only — do not auto-apply.

## Output

Report in this format:

```
## Dependency Audit — <date>

### Critical (CVEs / security)
- <package>@<current> — <advisory summary> — upgrade to <target>

### Stale (major version lag)
- <package>@<current> — latest: <latest> — upgrade command: <cmd>

### Minor updates available
<count> packages have patch/minor updates (run `<cmd>` to see full list)
```

Keep the report concise. Flag blockers clearly; de-emphasize minor noise.
