# EKS Terraform - CI/CD Pipeline Guide

## Overview

This repository uses automated GitHub Actions CI/CD workflows to test, validate, plan, deploy, and visually document AWS EKS infrastructure. The pipeline incorporates security scans, linting, OIDC-based AWS authentication, and automated cloud architecture diagram generation via [tf-arch-diagram-generator](https://github.com/mchittineni/tf-arch-diagram-generator).

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       GitHub Actions Workflows                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Trigger Events (Push, Pull Request, Workflow Dispatch)                 │
│         ↓                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 1. Validate & Security Scan (.github/workflows/validate.yml)    │   │
│  │ - terraform fmt -check -recursive                               │   │
│  │ - terraform init -backend=false                                 │   │
│  │ - terraform validate                                            │   │
│  │ - tflint (AWS ruleset 0.38+)                                    │   │
│  │ - Checkov Terraform security scan                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│         ↓                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 2. Plan & Architecture Diagram (.github/workflows/plan.yml)     │   │
│  │ - AWS OIDC Authentication                                       │   │
│  │ - terraform plan -out=tfplan                                    │   │
│  │ - terraform show -json tfplan > plan.json                       │   │
│  │ - npx tf-arch-diagram-generator render plan.json -o arch.svg    │   │
│  │ - Upload plan & SVG artifacts                                   │   │
│  │ - Post PR comment with plan diff & diagram status               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│         ↓ (Merge to main / Dispatch)                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 3. Apply Workflow (.github/workflows/apply.yml)                 │   │
│  │ - terraform apply -auto-approve                                 │   │
│  │ - Render applied architecture diagram                           │   │
│  │ - Capture cluster & database outputs                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  Optional / Manual:                                                     │
│  • diagram.yml  - On-demand architecture diagram generation & commit    │
│  • destroy.yml  - Protected manual teardown workflow                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## GitHub Actions Workflows

### 1. Validate & Security Scan (`.github/workflows/validate.yml`)
Runs on every push to `main`, on pull requests, and on manual dispatch. Validates syntax, checks formatting, and audits configuration against AWS security benchmarks.

- **Action versions (Pinned by Full Commit SHA)**:
  - `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7.0.1`
  - `actions/setup-node@820762786026740c76f36085b0efc47a31fe5020  # v7.0.0` (Node 24)
  - `hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e #v4.0.1` (Terraform v1.16.1)
  - `terraform-linters/setup-tflint@1cf010d3c7aef302051ccdb68c14c5dc2efa34ef #v6.3.1`
  - `bridgecrewio/checkov-action@99bb2caf247dfd9f03cf984373bc6043d4e32ebf #v12.1347.0`
  - `actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1`
  - `aws-actions/configure-aws-credentials@cbe3b392738ccf3f987d68400dafcf4b0624a56c #6.2.4`
  - `aws-actions/aws-secretsmanager-get-secrets@2cb1a461cbd4865ac4299648312e4704c646cd53 #v3.0.1`
  - `actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3 #v9.0.0`

### 2. Plan & Architecture Diagram (`.github/workflows/plan.yml`)
Triggered on pull requests to `main`. Prepares the plan, inspects resources, renders the architecture diagram using `tf-arch-diagram-generator`, and publishes a sticky PR comment with full details.

- **Key Steps**:
  1. Configures AWS credentials via GitHub OIDC (`aws-actions/configure-aws-credentials@cbe3b392738ccf3f987d68400dafcf4b0624a56c #6.2.4`).
  2. Sets up Node.js 24 (`actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0`).
  3. Executes `terraform plan` and exports to JSON (`terraform show -json tfplan > plan.json`).
  4. Renders SVG architecture diagram:
     ```bash
     npx -y tf-arch-diagram-generator render plan.json --out docs/architecture.svg --title "AWS EKS Architecture Plan"
     npx -y tf-arch-diagram-generator inspect plan.json --json > plan-summary.json
     ```
  5. Uploads `tfplan`, `plan.json`, `docs/architecture.svg`, and `plan-summary.json` as job artifacts.
  6. Updates or creates an informative PR comment with markdown status and expandable plan output.

### 3. Deploy / Apply (`.github/workflows/apply.yml`)
Runs automatically upon merging changes into `main` or via manual dispatch with environment selection (`dev`, `staging`, `production`).

- Deploys infrastructure using `terraform apply -auto-approve`.
- Exports state plan and refreshes `docs/architecture.svg`.
- Publishes outputs (`eks_cluster_name`, `rds_endpoint`).

### 4. Dedicated Diagram Generator (`.github/workflows/diagram.yml`)
Manual workflow (`workflow_dispatch`) enabling on-demand plan generation, rendering via `tf-arch-diagram-generator`, and auto-committing the updated `docs/architecture.svg` back to the repository.

### 5. Protected Destroy (`.github/workflows/destroy.yml`)
Safely tears down infrastructure in non-production workspaces. Requires typing `DESTROY` in the confirmation input to prevent accidental resource deletion.

---

## Local Diagram Generation

Developers can also generate diagrams directly on their local machines:

```bash
# Generate architecture.svg from local plan
./scripts/generate_diagram.sh dev

# Generate diagram and launch interactive viewer in browser
./scripts/generate_diagram.sh dev --serve

# Render existing plan file
./scripts/generate_diagram.sh --plan plan.json -o docs/architecture.svg
```

The script automatically detects whether `tf-arch` CLI is installed (`brew install mchittineni/tap/tf-arch`) or executes via `npx -y tf-arch-diagram-generator`.
