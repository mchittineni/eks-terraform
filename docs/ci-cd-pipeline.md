# EKS Terraform - CI/CD Pipeline Guide

## Overview

This guide explains how to set up and configure a CI/CD pipeline for automated infrastructure deployment using GitHub Actions. The pipeline automates Terraform validation, security scanning, planning, and deployment workflows.

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Trigger Events (Push, Pull Request, Manual)                │
│         ↓                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Validate & Format Check                            │    │
│  │  - terraform fmt                                    │    │
│  │  - terraform validate                              │    │
│  └─────────────────────────────────────────────────────┘    │
│         ↓                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Security Scanning                                  │    │
│  │  - tfsec                                            │    │
│  │  - checkov                                          │    │
│  │  - tflint                                           │    │
│  └─────────────────────────────────────────────────────┘    │
│         ↓                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Plan (PR) / Plan & Apply (Main)                   │    │
│  │  - terraform plan                                   │    │
│  │  - (Optional) Manual approval                       │    │
│  │  - terraform apply                                  │    │
│  └─────────────────────────────────────────────────────┘    │
│         ↓                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Post-Deployment                                    │    │
│  │  - Output infrastructure details                    │    │
│  │  - Verify deployment                                │    │
│  │  - Notify team                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## GitHub Actions Workflows

### 1. Validation & Security Workflow

**File**: `.github/workflows/validate.yml`

```yaml
name: Terraform Validate & Security Scan

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, closed]

env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  terraform-validate-security:
    name: Terraform Validate & Security
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.13.0

      - name: Terraform Setup
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: latest

      - name: Show Terraform version
        run: terraform --version
      
      - name: Check Backend Initialization
        id: backend_check
        continue-on-error: true
        run: |
          if [ -d ".terraform" ]; then
            echo "backend_initialized=true" >> $GITHUB_OUTPUT
            echo "✓ Backend already initialized"
          else
            echo "backend_initialized=false" >> $GITHUB_OUTPUT
            echo "⚠ Backend not initialized, will run init.sh"
          fi
      
      - name: Run Init Script if Needed
        if: steps.backend_check.outputs.backend_initialized == 'false'
        run: |
          chmod +x scripts/init.sh
          bash scripts/init.sh
      - name: Terraform Init
        id: init
        run: terraform init -input=false

      - name: Terraform Format
        id: fmt
        run: terraform fmt -check -recursive

      # - name: Terraform Validate
      #   id: validate
      #   run: terraform validate
      #   uncomment the above step if you need the output in a colourful format

      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color

      - name: TFLint Setup
        uses: terraform-linters/setup-tflint@v6
        with:
          tflint_version: latest

      - name: Show TFLint version
        run: tflint --version

      - name: TFLint Init
        run: tflint --init

      - name: Run TFLint
        continue-on-error: true
        run: tflint --config=.tflint.hcl --format json . > tflint-report.json || true

      - name: Run TFSec
        continue-on-error: true
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: .
          config_file: .tfsec.yml

      - name: Bridgecrew Checkov GitHub Action
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .
          framework: terraform
          quiet: false
          soft_fail: false        

      - name: Upload Reports to Artifacts
        if: always()
        uses: actions/upload-artifact@v5
        with:
          name: security-reports
          path: |
            tflint-report.json
            checkov-report.json
```

### 2. Plan Workflow (Pull Requests)

**File**: `.github/workflows/plan.yml`

```yaml
name: Terraform Plan

on:
    branches:
        - main
    pull_request:
        types: [opened, synchronize, closed]

jobs:
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    # These permissions are needed to interact with GitHub's OIDC Token endpoint.
    environment: ${{ github.environment }}
    # Create a GitHub environment to deploy resources to

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: ${{ vars.AWS_DEPLOYMENT_ARN }}
          aws-region: ${{ vars.AWS_DEPLOYMENT_REGION }}
        # Update the role-to-assume and aws-region in respective GitHub environment secrets or variables

      - name: Fetch AWS Secret from AWS Secrets Manager
        uses: aws-actions/aws-secretsmanager-get-secrets@v2
        with:
          secret-ids: |
            ${{ vars.SECRETS_ARN_TERRAFORM }}
          parse-json-secrets: true
        #  updated the secret-ids either in respective github environment secrets or variables of your choice

      - name: Set Terraform Environment Variables
        run: |
          echo "TF_VAR_alert_email=${{ env.TERRAFORM_ALERT_EMAIL }}" >> "$GITHUB_ENV"
          echo "TF_VAR_environment=${{ env.TERRAFORM_ENVIRONMENT }}" >> "$GITHUB_ENV"
          echo "TF_VAR_grafana_admin_password=${{ env.TERRAFORM_GRAFANA_ADMIN_PASSWORD }}" >> "$GITHUB_ENV"
          echo "TF_VAR_owner_email=${{ env.TERRAFORM_OWNER_EMAIL }}" >> "$GITHUB_ENV"
        # store the TF_Var's as follows to loading the .tfvars while running the plan

      - name: Terraform Setup
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: latest

      - name: Show Terraform version
        run: terraform --version

      - name: Terraform Init
        id: init
        run: terraform init -input=false

      # - name: Terraform Plan
      #   id: plan
      #   continue-on-error: true
      #   run: terraform plan
      #   uncomment the above step if you need the output in a colourful format

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan -no-color -out=tfplan
          terraform show -no-color tfplan > tfplan.txt

      - name: Update Terraform Plan Comment on a Pull Request
        uses: actions/github-script@v8
        if: github.event_name == 'pull_request'
        env:
          PLAN: "terraform\n${{ steps.plan.outputs.stdout }}"
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            // 1. Retrieve existing bot comments for the PR
            const { data: comments } = await github.rest.issues.listComments({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
            })
            const botComment = comments.find(comment => {
                return comment.user.type === 'Bot' && comment.body.includes('Terraform Format and Style')
            })
            // 2. Prepare format of the comment
            const output = `#### Terraform Initialization ⚙️\`${{ steps.init.outcome }}\`
            #### Terraform Plan 📖\`${{ steps.plan.outcome }}\`
            <details><summary>Show Plan</summary>
            \`\`\`\n
            ${process.env.PLAN}
            \`\`\`
            </details>
            *Pusher: @${{ github.actor }},
            Action: \`${{ github.event_name }}\`,
            PR Number: \`${{ github.event.number }}\`,
            Workflow: \`${{ github.workflow }}\`*`;
            // 3. If we have a comment, update it, otherwise create a new one
            if (botComment) {
                github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: botComment.id,
                body: output
                })
            } else {
                github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: output
                })
            }

      - name: Upload Plan to Artifacts
        uses: actions/upload-artifact@v5
        with:
          name: tfplan
          path: tfplan
```

### 3. Apply Workflow (Main Branch)

**File**: `.github/workflows/apply.yml`

```yaml
name: Terraform Apply

on:
  push:
    branches:
        - main

jobs:
  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    # These permissions are needed to interact with GitHub's OIDC Token endpoint.
    environment: {{ github.environment}}
    # create a github environment to deploy the resources to

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: ${{ vars.AWS_DEPLOYMENT_ARN }}
          aws-region: ${{ vars.AWS_DEPLOYMENT_REGION }}
        #  updated the role-to-assume & aws-region either in respective github environment secrets or variables of your choice

      - name: Fetch AWS Secret from AWS Secrets Manager
        uses: aws-actions/aws-secretsmanager-get-secrets@v2
        with:
          secret-ids: |
            ${{ vars.SECRETS_ARN_TERRAFORM }}
          parse-json-secrets: true
        #  updated the secret-ids either in respective github environment secrets or variables of your choice

      - name: Set Terraform Environment Variables
        run: |
          echo "TF_VAR_alert_email=${{ env.TERRAFORM_ALERT_EMAIL }}" >> "$GITHUB_ENV"
          echo "TF_VAR_environment=${{ env.TERRAFORM_ENVIRONMENT }}" >> "$GITHUB_ENV"
          echo "TF_VAR_grafana_admin_password=${{ env.TERRAFORM_GRAFANA_ADMIN_PASSWORD }}" >> "$GITHUB_ENV"
          echo "TF_VAR_owner_email=${{ env.TERRAFORM_OWNER_EMAIL }}" >> "$GITHUB_ENV"
        # store the TF_Var's as follows to loading the .tfvars while running the plan

      - name: Terraform Setup
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: latest

      - name: Show Terraform version
        run: terraform --version

      - name: Terraform Init
        id: init
        run: terraform init -input=false

      # - name: Terraform Plan
      #   id: plan
      #   continue-on-error: true
      #   run: terraform plan
      #   uncomment the above step if you need the output in a colourful format

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan -no-color -out=tfplan
          terraform show -no-color tfplan > tfplan.txt

      - name: Terraform Apply
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve

      - name: Capture Outputs
        id: outputs
        run: |
          echo "eks_cluster_name=$(terraform output -raw eks_cluster_name)" >> $GITHUB_OUTPUT
          echo "rds_endpoint=$(terraform output -raw rds_endpoint)" >> $GITHUB_OUTPUT
```

### 4. Destroy Workflow (Manual)

**File**: `.github/workflows/destroy.yml`

```yaml
name: Terraform Destroy (Manual)

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to destroy (dev/staging)'
        required: true
        default: 'dev'

jobs:
  terraform-destroy:
    name: Terraform Destroy
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    # These permissions are needed to interact with GitHub's OIDC Token endpoint.
    environment: ${{ github.environment }}
    # Create a GitHub environment to deploy resources to

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: ${{ vars.AWS_DEPLOYMENT_ARN }}
          aws-region: ${{ vars.AWS_DEPLOYMENT_REGION }}
        # Update the role-to-assume and aws-region in respective GitHub environment secrets or variables

      - name: Fetch AWS Secret from AWS Secrets Manager
        uses: aws-actions/aws-secretsmanager-get-secrets@v2
        with:
          secret-ids: |
            ${{ vars.SECRETS_ARN_TERRAFORM }}
          parse-json-secrets: true
        #  updated the secret-ids either in respective github environment secrets or variables of your choice

      - name: Terraform Setup
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: latest

      - name: Show Terraform version
        run: terraform --version

      - name: Terraform Init
        id: init
        run: terraform init -input=false

      - name: Confirm Destruction
        run: |
          echo "⚠️  WARNING: About to destroy infrastructure in ${{ github.event.inputs.environment }}"
          echo "This action cannot be undone!"
          sleep 5

      - name: Terraform Destroy
        run: |
          terraform workspace select ${{ github.event.inputs.environment }}
          terraform destroy -auto-approve
```

## GitHub Secrets Configuration

Configure the following secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

| Secret / Variable Name | Description | Example |
|-------------|-------------|---------|
| `AWS_DEPLOYMENT_ARN` | AWS OIDC IAM Role used for deployment |  |
| `AWS_DEPLOYMENT_REGION` | AWS region for deployment | `us-east-1` |
| `SECRETS_ARN_TERRAFORM` | AWS Secrets Manager ARN for storing sensitive variables required for deployment | (sensitive) |

### Creating AWS OIDC IAM Role for CI/CD

Follow the steps mentioned to configure GitHub OpenID Connect in Amazon Web Services [OIDC](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws)


## Pipeline Execution

### Automatic Triggers

1. **Validation Workflow** - Runs on:
   - Push to `main` or `develop` branches
   - Pull requests to `main` branch
   - Purpose: Validate code, run security scans

2. **Plan Workflow** - Runs on:
   - Pull requests to `main` branch
   - Purpose: Show infrastructure changes before merge

3. **Apply Workflow** - Runs on:
   - Push to `main` branch (after PR merge)
   - Purpose: Deploy approved infrastructure changes

### Manual Triggers

**Destroy Workflow**:
```
GitHub UI > Actions > Terraform Destroy (Manual) > Run workflow > Select environment
```

## Best Practices

### 1. Branch Strategy

```
main (production)
  ↑
  └─ Pull Request
       ↑
       └─ feature/env-setup
       └─ bugfix/networking
       └─ develop (staging)
```

- **main**: Production-ready code, all workflows run
- **develop**: Staging/testing, validation only
- **feature/***: Feature branches, validation only

### 2. Code Review Process

1. Create feature branch from `develop`
2. Make changes and commit
3. Push to GitHub and create Pull Request
4. Wait for validation workflow to pass
5. Review plan output in PR comments
6. Code review by team members
7. Merge to `develop` for staging test
8. Create PR to `main` for production
9. Final approval and merge triggers apply workflow

### 3. Environment Protection

Enable branch protection rules on `main`:
- Require pull request reviews (2+ reviewers)
- Require status checks to pass
- Require branches to be up to date
- Include administrators in restrictions
- Restrict who can push (admins only)

### 4. Approval Gates

Configure GitHub Environments for additional security:

```yaml
# Settings > Environments > production
- Required reviewers (2+)
- Required branch: main
- Deployment branches: main only
```

### 5. Monitoring & Alerts

Set up notifications for:
- Failed validations
- Deployment failures
- Security scan findings
- Manual approvals pending

## Troubleshooting

### Issue: Terraform Backend Lock

**Symptoms**: Workflow fails with "Error acquiring state lock"

**Solution**:
```bash
# Manually unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Issue: AWS Credentials Expired

**Symptoms**: "UnrecognizedClientException" or authentication errors

**Solution**:
1. Rotate AWS access keys
2. Update GitHub secrets with new credentials
3. Re-run workflow

### Issue: Plan Shows Unexpected Changes

**Symptoms**: terraform plan detects changes that shouldn't exist

**Solution**:
```bash
# Refresh state
terraform refresh

# Check for configuration drift
terraform plan -no-color | grep -A5 "changes"
```

### Issue: Workspace Selection Error

**Symptoms**: "No such workspace"

**Solution**:
```bash
# Create workspace if it doesn't exist
terraform workspace new staging
terraform workspace select staging
```

## Advanced Configuration

### Cost Estimation

Integrate Infracost to estimate costs:

```yaml
- name: Install Infracost
  run: |
    curl https://raw.githubusercontent.com/infracosthq/infracost/master/scripts/install.sh | bash

- name: Run Infracost
  run: |
    infracost breakdown --path . --format json > infracost.json
    infracost comment github --path ./infracost.json \
      --github-token ${{ github.token }}
```

### Policy as Code

Enforce policies using OPA (Open Policy Agent):

```yaml
- name: OPA Policy Check
  run: |
    opa eval -d policies/ -b 'data.terraform.main' tfplan.json
```

### Automated Testing

Run Terratest for module testing:

```yaml
- name: Run Terratest
  run: |
    cd tests/
    go test -v -timeout 30m
```

## Security Considerations

### 1. Secret Management

- Never commit secrets to Git
- Use GitHub Secrets for sensitive values
- Rotate credentials regularly
- Use short-lived credentials when possible

### 2. State File Protection

- Enable state file encryption (S3 + KMS)
- Restrict access to S3 backend bucket
- Enable versioning on backend bucket
- Use DynamoDB for state locking

### 3. Audit Logging

- Enable GitHub Actions logs retention
- Log all infrastructure changes
- Use CloudTrail for AWS API audit
- Review logs regularly

### 4. Access Control

- Limit who can approve deployments
- Use GitHub team reviews
- Enforce MFA for critical actions
- Separate production and staging access

## Integration Examples

### Slack Notifications

```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: |
      Terraform ${{ job.status }}
      Author: ${{ github.actor }}
      Branch: ${{ github.ref }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
    fields: repo,message,commit,author
```

### Email Notifications

```yaml
- name: Send Email Alert
  uses: davisulrich/email-action@v1.6.0
  with:
    server_address: ${{ secrets.EMAIL_SERVER }}
    server_port: ${{ secrets.EMAIL_PORT }}
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: 'EKS Terraform Deployment Complete'
    body: 'Check GitHub Actions for details.'
    to: devops-team@example.com
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [HashiCorp Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS CLI GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)
- [Security Best Practices for GitHub Actions](https://docs.github.com/en/actions/security-guides)
- [Terraform Cloud Integration](https://www.terraform.io/cloud-docs)

## Next Steps

1. Copy workflow files to `.github/workflows/` directory
2. Configure GitHub Secrets
3. Set up branch protection rules
4. Configure GitHub Environments
5. Test workflows with a feature branch
6. Verify Slack/email notifications
7. Document team runbooks
8. Train team on deployment process
