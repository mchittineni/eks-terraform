#!/bin/bash
# Deploy infrastructure to specified environment (workspace)
set -euo pipefail

ENVIRONMENT="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

export TF_VAR_environment="${ENVIRONMENT}"
BACKEND_BUCKET="${TF_BACKEND_BUCKET:-terraform-state-multicloud-infra}"

if [[ "${SKIP_BACKEND_BOOTSTRAP:-false}" != "true" ]]; then
  "${SCRIPT_DIR}/ensure_backend_bucket.sh" "${BACKEND_BUCKET}"
fi

terraform init -reconfigure >/dev/null

terraform workspace select "${ENVIRONMENT}" >/dev/null 2>&1 || terraform workspace new "${ENVIRONMENT}"

PLAN_FILE="tfplan-${ENVIRONMENT}"

echo "Planning changes for workspace '${ENVIRONMENT}'..."
terraform plan -out="${PLAN_FILE}"

echo "Applying changes to workspace '${ENVIRONMENT}'..."
terraform apply "${PLAN_FILE}"

rm -f "${PLAN_FILE}"

echo "✓ Deployment complete!"
