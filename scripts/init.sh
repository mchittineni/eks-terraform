#!/bin/bash
# Initialize Terraform and prepare workspaces
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

BACKEND_BUCKET="${TF_BACKEND_BUCKET:-terraform-state-multicloud-infra}"

# Ensure an AWS Secrets Manager secret named 'terraform' exists. Create it if missing.
ensure_secrets_manager_secret() {
  local secret_name="Terraform"

  if aws secretsmanager describe-secret --secret-id "${secret_name}" >/dev/null 2>&1; then
    echo "• Secrets Manager secret '${secret_name}' already exists"
  else
    echo "• Secrets Manager secret '${secret_name}' not found — creating..."
    # Create an empty JSON object as the initial secret value; adjust as needed
    aws secretsmanager create-secret --name "${secret_name}" --secret-string '{}' >/dev/null
    echo "✓ Created Secrets Manager secret '${secret_name}'"
  fi
}

if [[ "${SKIP_BACKEND_BOOTSTRAP:-false}" != "true" ]]; then
  echo "Ensuring Secrets Manager secret 'terraform' exists..."
  ensure_secrets_manager_secret

  echo "Ensuring remote backend bucket '${BACKEND_BUCKET}' exists..."
  "${SCRIPT_DIR}/ensure_backend_bucket.sh" "${BACKEND_BUCKET}"
else
  echo "Skipping backend bucket bootstrap (SKIP_BACKEND_BOOTSTRAP=true)"
fi

echo "Initializing Terraform backend..."
terraform init -reconfigure

echo "Ensuring workspaces exist..."
readarray -t WORKSPACES < <(terraform workspace list | sed 's/^[* ]\+//')

ensure_workspace() {
  local name="$1"
  if printf '%s\n' "${WORKSPACES[@]}" | grep -qx "${name}"; then
    echo "• Workspace '${name}' already present"
  else
    terraform workspace new "${name}"
  fi
}

ensure_workspace "dev"
ensure_workspace "staging"
ensure_workspace "production"

echo "✓ Initialization complete."
