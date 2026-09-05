#!/bin/bash
# ==============================================================================
# Generate Architecture Diagram using tf-arch-diagram-generator
# Repository: https://github.com/mchittineni/tf-arch-diagram-generator
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

# Default parameters
ENVIRONMENT="dev"
OUTPUT_FILE="docs/architecture.svg"
SERVE_VIEWER=false
PLAN_INPUT=""

usage() {
  cat << 'EOF'
Usage: ./scripts/generate_diagram.sh [ENVIRONMENT] [OPTIONS]

Generate a cloud architecture diagram SVG from your Terraform plan using tf-arch-diagram-generator.

Arguments:
  ENVIRONMENT              Target environment: dev (default), staging, or production

Options:
  -p, --plan <file>        Use an existing plan.json or tfplan file instead of running terraform plan
  -o, --out <path>         Output diagram path (default: docs/architecture.svg)
  -s, --serve              Launch interactive local viewer in browser after generation
  -h, --help               Display this help message

Examples:
  ./scripts/generate_diagram.sh
  ./scripts/generate_diagram.sh staging -o docs/staging-arch.svg
  ./scripts/generate_diagram.sh --serve
  ./scripts/generate_diagram.sh --plan plan.json
EOF
  exit 0
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    dev|staging|production)
      ENVIRONMENT="$1"
      shift
      ;;
    -p|--plan)
      PLAN_INPUT="$2"
      shift 2
      ;;
    -o|--out)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -s|--serve)
      SERVE_VIEWER=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      ;;
  esac
done

echo "========================================================"
echo " AWS EKS Terraform Architecture Diagram Generator"
echo " Powered by tf-arch-diagram-generator"
echo " Environment: ${ENVIRONMENT}"
echo " Output File: ${OUTPUT_FILE}"
echo "========================================================"

# Determine diagram generator tool (prefers local tf-arch CLI if present, falls back to npx)
RUN_CMD=()
if command -v tf-arch >/dev/null 2>&1; then
  RUN_CMD=("tf-arch")
  echo "• Found installed tf-arch CLI ($(tf-arch --version 2>/dev/null || echo 'installed'))"
elif command -v npx >/dev/null 2>&1; then
  RUN_CMD=("npx" "-y" "tf-arch-diagram-generator")
  echo "• Using npx tf-arch-diagram-generator"
else
  echo "❌ Error: Neither tf-arch CLI nor npx/Node.js is available."
  echo "Please install Node.js 22+ or install tf-arch via:"
  echo "  brew install mchittineni/tap/tf-arch   # (macOS)"
  echo "  npm install -g tf-arch-diagram-generator"
  exit 1
fi

PLAN_JSON=""
CLEANUP_TEMP=false

if [[ -n "${PLAN_INPUT}" ]]; then
  if [[ ! -f "${PLAN_INPUT}" ]]; then
    echo "❌ Specified plan file '${PLAN_INPUT}' not found."
    exit 1
  fi
  if [[ "${PLAN_INPUT}" == *.json ]]; then
    PLAN_JSON="${PLAN_INPUT}"
  else
    PLAN_JSON="plan-temp.json"
    terraform show -json "${PLAN_INPUT}" > "${PLAN_JSON}"
    CLEANUP_TEMP=true
  fi
else
  if ! command -v terraform >/dev/null 2>&1; then
    echo "❌ Error: terraform is not installed."
    exit 1
  fi

  export TF_VAR_environment="${ENVIRONMENT}"
  TEMP_PLAN="tfplan-${ENVIRONMENT}"
  PLAN_JSON="plan-${ENVIRONMENT}.json"
  CLEANUP_TEMP=true

  echo "• Preparing Terraform workspace '${ENVIRONMENT}'..."
  terraform workspace select "${ENVIRONMENT}" >/dev/null 2>&1 || terraform workspace new "${ENVIRONMENT}" >/dev/null 2>&1 || true

  echo "• Generating plan for workspace '${ENVIRONMENT}'..."
  terraform plan -out="${TEMP_PLAN}" -input=false

  echo "• Converting binary plan to JSON..."
  terraform show -json "${TEMP_PLAN}" > "${PLAN_JSON}"
  rm -f "${TEMP_PLAN}"
fi

# Ensure target directory exists
mkdir -p "$(dirname "${OUTPUT_FILE}")"

echo "• Rendering architecture diagram..."
"${RUN_CMD[@]}" render "${PLAN_JSON}" --out "${OUTPUT_FILE}" --title "AWS EKS Architecture - ${ENVIRONMENT}"

echo ""
echo "• Plan Inspection Summary:"
"${RUN_CMD[@]}" inspect "${PLAN_JSON}"

if [[ "${CLEANUP_TEMP}" == "true" && -f "${PLAN_JSON}" ]]; then
  rm -f "${PLAN_JSON}"
fi

echo ""
echo "========================================================"
echo " ✓ Diagram generated successfully: ${OUTPUT_FILE}"
echo "========================================================"

if [[ "${SERVE_VIEWER}" == "true" ]]; then
  echo "• Launching interactive architecture viewer in browser..."
  "${RUN_CMD[@]}" serve "${OUTPUT_FILE}" --open
fi
