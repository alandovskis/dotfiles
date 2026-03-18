#!/usr/bin/env bash
# Blocks writes to sensitive files and system paths.
#
# Covered paths:
#   - OS system directories (/etc, /usr, /bin, /sbin, /lib, /boot, /sys, /proc)
#   - SSH private keys (~/.ssh/id_*)
#   - AWS credentials (~/.aws/credentials)
#   - GCP credentials (~/.config/gcloud/)
#   - Azure credentials (~/.azure/)
#   - Docker registry auth (~/.docker/config.json)
#   - Kubernetes config (~/.kube/config)
#   - GPG keyring (~/.gnupg/)
#   - netrc (~/.netrc)
#   - npm / PyPI auth (~/.npmrc, ~/.pypirc)
#   - Vault token (~/.vault-token)
#   - Terraform credentials (~/.terraform.d/credentials.tfrc.json)
#   - Named credentials/secrets files (credentials.json, secrets.yaml, etc.)
#
# Applies to: Write, Edit, MultiEdit tools

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Expand ~ to actual home directory
file_path="${file_path/#\~/$HOME}"

deny() {
    printf 'BLOCKED: Cannot write to "%s" — %s\n' "$file_path" "$1" >&2
    exit 2
}

# OS system directories — any write here is dangerous
if echo "$file_path" | grep -qE '^/(etc|usr|bin|sbin|lib|lib64|boot|sys|proc)/'; then
    deny "this is a system path. Modifying OS files can destabilize the system."
fi

# SSH private keys — protect actual key files, not config/known_hosts/authorized_keys
if echo "$file_path" | grep -qE "^$HOME/\.ssh/id_(rsa|ed25519|ecdsa|dsa|ecdsa_sk|ed25519_sk)$"; then
    deny "this is an SSH private key. Overwriting it will lock you out of any servers using this key."
fi

# AWS credentials file
if echo "$file_path" | grep -qE "^$HOME/\.aws/credentials$"; then
    deny "this is the AWS credentials file. Overwriting it will break all AWS CLI access."
fi

# GCP credentials directory
if echo "$file_path" | grep -qE "^$HOME/\.config/gcloud/"; then
    deny "this is a GCP credentials file. Modifying it can revoke Google Cloud access."
fi

# Azure credentials directory
if echo "$file_path" | grep -qE "^$HOME/\.azure/"; then
    deny "this is an Azure credentials file. Modifying it can revoke Azure CLI access."
fi

# Docker registry auth
if echo "$file_path" | grep -qE "^$HOME/\.docker/config\.json$"; then
    deny "this is the Docker credentials file. Overwriting it will log you out of all container registries."
fi

# Kubernetes config — holds cluster certs and tokens
if echo "$file_path" | grep -qE "^$HOME/\.kube/config$"; then
    deny "this is the kubeconfig file. Overwriting it can destroy access to Kubernetes clusters."
fi

# GPG keyring directory
if echo "$file_path" | grep -qE "^$HOME/\.gnupg/"; then
    deny "this is the GPG keyring. Modifying GPG files can break signing and encryption."
fi

# netrc — stores plaintext credentials for FTP/HTTP/Git HTTPS
if echo "$file_path" | grep -qE "^$HOME/\.netrc$"; then
    deny "this is ~/.netrc which stores plaintext credentials. Overwriting it can break Git HTTPS auth."
fi

# npm auth token file
if echo "$file_path" | grep -qE "^$HOME/\.npmrc$"; then
    deny "this is ~/.npmrc which may contain npm registry auth tokens."
fi

# PyPI upload credentials
if echo "$file_path" | grep -qE "^$HOME/\.pypirc$"; then
    deny "this is ~/.pypirc which contains PyPI upload credentials."
fi

# HashiCorp Vault token
if echo "$file_path" | grep -qE "^$HOME/\.vault-token$"; then
    deny "this is the Vault authentication token. Overwriting it will break Vault CLI access."
fi

# Terraform Cloud credentials
if echo "$file_path" | grep -qE "^$HOME/\.terraform\.d/credentials\.tfrc\.json$"; then
    deny "this is the Terraform credentials file. Overwriting it will break Terraform Cloud access."
fi

# Named credentials/secrets files (e.g. credentials.json, app-secrets.yaml)
# Note: this catches project-level secrets files too. If you intentionally need to write
# such a file, ask Claude to explain what it is writing first.
if echo "$file_path" | grep -iqE '/(credentials?|secrets?|api[-_]?keys?)\.(json|yaml|yml|toml|ini|env)$'; then
    deny "this file name suggests it contains credentials or secrets. If intentional, write to a differently-named file and rename it manually."
fi

exit 0
