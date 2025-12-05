#!/bin/bash
# Destroy infrastructure in specified environment (workspace)
set -euo pipefail

ENVIRONMENT="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

echo "⚠️  WARNING: This will destroy all resources in workspace '${ENVIRONMENT}'!"
read -r -p "Are you sure? (yes/no): " confirm

if [[ "${confirm}" != "yes" ]]; then
  echo "Cancelled."
  exit 0
fi

export TF_VAR_environment="${ENVIRONMENT}"
BACKEND_BUCKET="${TF_BACKEND_BUCKET:-terraform-state-multicloud-infra}"

if [[ "${SKIP_BACKEND_BOOTSTRAP:-false}" != "true" ]]; then
  "${SCRIPT_DIR}/ensure_backend_bucket.sh" "${BACKEND_BUCKET}"
fi

terraform init -reconfigure >/dev/null
terraform workspace select "${ENVIRONMENT}" >/dev/null 2>&1 || terraform workspace new "${ENVIRONMENT}"

terraform destroy

echo "✓ Resources destroyed!"
