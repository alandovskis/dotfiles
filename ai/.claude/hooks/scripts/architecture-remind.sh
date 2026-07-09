#!/usr/bin/env bash
# PostToolUse — Fires after Write/Edit/MultiEdit.
# If an architecture-relevant file was modified, instructs Claude to run /architecture.

set -uo pipefail

input=$(cat)

# Collect file path(s): Write/Edit use file_path; MultiEdit uses edits[].file_path
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)
edit_paths=$(echo "$input" | jq -r '(.tool_input.edits // [])[] | .file_path' 2>/dev/null || true)

# Architecture-relevant file patterns
arch_regex='(docker-compose[^/]*\.ya?ml$|/Dockerfile[^/]*$|^Dockerfile[^/]*$|/package\.json$|^package\.json$|go\.mod$|Cargo\.toml$|pyproject\.toml$|pom\.xml$|build\.gradle(\.kts)?$|/kubernetes/|/k8s/|/helm/|/terraform/|/pulumi/|\.proto$|schema\.graphql$|\.graphql$)'

# Skip the architecture output files themselves
skip_regex='docs/(c4-context|c4-containers|c4-components|architecture-patterns)'

triggered=0
while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    echo "$path" | grep -qE "$skip_regex" && continue
    if echo "$path" | grep -qE "$arch_regex"; then
        triggered=1
        break
    fi
done <<< "$(printf '%s\n%s' "$file_path" "$edit_paths")"

if [[ "$triggered" -eq 1 ]]; then
    echo "ARCHITECTURE DOCUMENTATION OUT OF DATE"
    echo "An architecture-relevant file was just modified: $path"
    echo "You MUST run /architecture before ending this task to regenerate"
    echo "the C4 diagrams and design patterns in docs/."
fi

exit 0
