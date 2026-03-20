#!/usr/bin/env bash
# Blocks reads of files whose contents should never be seen by an AI assistant.
#
# Covered paths:
#   - SSH private keys (~/.ssh/id_*)
#   - /etc/shadow (hashed system passwords)
#   - GPG private keys (~/.gnupg/private-keys-v1.d/, secring.gpg)
#   - AWS credentials (~/.aws/credentials)
#   - GCP credentials (~/.config/gcloud/credentials.db, access_tokens.db)
#   - Azure credentials (~/.azure/accessTokens.json, msal_token_cache.json)
#   - Docker registry auth (~/.docker/config.json)
#   - Kubernetes config (~/.kube/config)
#   - netrc (~/.netrc)
#   - npm / PyPI auth (~/.npmrc, ~/.pypirc)
#   - Vault token (~/.vault-token)
#   - Terraform credentials (~/.terraform.d/credentials.tfrc.json)
#   - .env files (not .env.example / .env.sample / .env.template)
#
# Applies to: Read tool

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Expand ~ to actual home directory
file_path="${file_path/#\~/$HOME}"

deny() {
    printf 'BLOCKED: Cannot read "%s" — %s\n' "$file_path" "$1" >&2
    exit 2
}

# SSH private keys
if echo "$file_path" | grep -qE "^$HOME/\.ssh/id_(rsa|ed25519|ecdsa|dsa|ecdsa_sk|ed25519_sk)$"; then
    deny "this is an SSH private key. Its contents must never be exposed to an AI assistant."
fi

# /etc/shadow — hashed system passwords
if echo "$file_path" | grep -qE '^/etc/shadow$'; then
    deny "/etc/shadow contains hashed system passwords and must not be read."
fi

# GPG private keys
if echo "$file_path" | grep -qE "^$HOME/\.gnupg/(secring\.gpg|private-keys-v1\.d/)"; then
    deny "this is a GPG private key. Its contents must never be exposed to an AI assistant."
fi

# AWS credentials (not config — config is safe)
if echo "$file_path" | grep -qE "^$HOME/\.aws/credentials$"; then
    deny "this is the AWS credentials file containing secret access keys."
fi

# GCP token files (not the general config directory)
if echo "$file_path" | grep -qE "^$HOME/\.config/gcloud/(credentials\.db|access_tokens\.db|application_default_credentials\.json)$"; then
    deny "this GCP file contains OAuth tokens or application default credentials."
fi

# Azure token cache files
if echo "$file_path" | grep -qE "^$HOME/\.azure/(accessTokens\.json|msal_token_cache\.json)$"; then
    deny "this Azure file contains authentication tokens."
fi

# Docker registry auth (contains base64-encoded credentials or token helpers)
if echo "$file_path" | grep -qE "^$HOME/\.docker/config\.json$"; then
    deny "~/.docker/config.json contains container registry credentials."
fi

# Kubernetes config (contains cluster certs and tokens)
if echo "$file_path" | grep -qE "^$HOME/\.kube/config$"; then
    deny "~/.kube/config contains Kubernetes cluster certificates and authentication tokens."
fi

# netrc — plaintext credentials
if echo "$file_path" | grep -qE "^$HOME/\.netrc$"; then
    deny "~/.netrc contains plaintext credentials for FTP/HTTP/Git HTTPS."
fi

# npm auth token file
if echo "$file_path" | grep -qE "^$HOME/\.npmrc$"; then
    deny "~/.npmrc may contain npm registry authentication tokens."
fi

# PyPI credentials
if echo "$file_path" | grep -qE "^$HOME/\.pypirc$"; then
    deny "~/.pypirc contains PyPI upload credentials."
fi

# HashiCorp Vault token
if echo "$file_path" | grep -qE "^$HOME/\.vault-token$"; then
    deny "~/.vault-token contains a Vault authentication token."
fi

# Terraform Cloud credentials
if echo "$file_path" | grep -qE "^$HOME/\.terraform\.d/credentials\.tfrc\.json$"; then
    deny "this file contains Terraform Cloud API tokens."
fi

# .env files — block actual env files but allow templates/examples
# Allow: .env.example, .env.sample, .env.template, .env.test, .env.local.example
# Block: .env, .env.local, .env.production, .env.staging, .env.development
if echo "$file_path" | grep -qE '\.env(\.[a-z]+)?$' && \
   ! echo "$file_path" | grep -qE '\.(example|sample|template)$'; then
    deny "this .env file may contain secrets (API keys, passwords, tokens). Read the .env.example instead."
fi

exit 0
