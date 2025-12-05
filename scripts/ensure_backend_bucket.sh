#!/usr/bin/env bash

set -euo pipefail

BUCKET="${1:-terraform-state-multicloud-infra}"
REGION="${TF_BACKEND_REGION:-${AWS_REGION:-us-east-1}}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found in PATH" >&2
  exit 1
fi

echo "Checking for S3 bucket '${BUCKET}' in region '${REGION}'..."
if aws s3api head-bucket --bucket "${BUCKET}" >/dev/null 2>&1; then
  echo "Bucket '${BUCKET}' already exists. Nothing to do."
  exit 0
fi

echo "Bucket not found. Creating..."
CREATE_ARGS=(--bucket "${BUCKET}")
if [[ "${REGION}" != "us-east-1" ]]; then
  CREATE_ARGS+=(--create-bucket-configuration "LocationConstraint=${REGION}")
fi

aws s3api create-bucket "${CREATE_ARGS[@]}"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

echo "Bucket '${BUCKET}' created and versioning enabled."

# Apply tags to the backend bucket. Can be influenced via environment variables:
# - TF_PROJECT_NAME (default: multicloud-infra)
# - TF_ENVIRONMENT (default: dev)
# - TF_OWNER_EMAIL (default: unknown@example.com)
# - TF_BACKEND_ADDITIONAL_TAGS (optional, comma-separated key=value pairs)

PROJECT_NAME="${TF_PROJECT_NAME:-multicloud-infra}"
ENVIRONMENT="${TF_ENVIRONMENT:-dev}"
OWNER_EMAIL="${TF_OWNER_EMAIL:-unknown@example.com}"
ADDITIONAL_TAGS="${TF_BACKEND_ADDITIONAL_TAGS:-}"

tagset="[]"

# Build TagSet JSON array entries
tags_json_parts=(
  "{Key=Project,Value=${PROJECT_NAME}}"
  "{Key=Environment,Value=${ENVIRONMENT}}"
  "{Key=ManagedBy,Value=Terraform}"
  "{Key=Owner,Value=${OWNER_EMAIL}}"
)

if [[ -n "${ADDITIONAL_TAGS}" ]]; then
  # Expecting comma-separated key=value pairs
  IFS=',' read -r -a extras <<< "${ADDITIONAL_TAGS}"
  for kv in "${extras[@]}"; do
    key="${kv%%=*}"
    val="${kv#*=}"
    tags_json_parts+=("{Key=${key},Value=${val}}")
  done
fi

# Join parts with commas
IFS=','; tagset="${tags_json_parts[*]}"; unset IFS

echo "Applying tags to bucket '${BUCKET}': ${tagset}"
aws s3api put-bucket-tagging --bucket "${BUCKET}" --tagging "TagSet=[${tagset}]"

echo "Tags applied to bucket '${BUCKET}'."

