# tf-gcp-workflow-templates

Reusable GitHub Actions workflows for Terraform-based GCP repositories.

## Workflows

### reusable-gcp-auth-smoke.yml

Validates GitHub OIDC auth to Google Cloud, confirms project access, and runs `terraform fmt -check` against a target directory.

**Inputs:**
- `runner` (optional, default: `arc-runner-set`)
- `terraform_version` (optional, default: `1.12.2`)
- `terraform_directory` (required)
- `gcp_project_id` (required)
- `gcp_workload_identity_provider` (required)
- `gcp_service_account` (required)

**Example:**
```yaml
jobs:
  auth-smoke-test:
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/reusable-gcp-auth-smoke.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      terraform_directory: 3-networking
      gcp_project_id: mtopps-iac
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### reusable-terraform-ci.yml

Runs Terraform CI checks: fmt → validate → plan with optional Google Cloud auth.

**Inputs:**
- `runner` (optional, default: `arc-runner-set`)
- `terraform_version` (optional, default: `1.12.2`)
- `directory` (required): Terraform stack directory
- `environment` (optional): Environment key for backend init
- `tfvars` (optional): tfvars file path for plan runs
- `gcp_project_id` (optional): GCP project ID
- `gcp_workload_identity_provider` (optional): For plan auth
- `gcp_service_account` (optional): For plan auth

**Example:**
```yaml
jobs:
  ci:
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/reusable-terraform-ci.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      directory: 0-bootstrap
      environment: prod
      tfvars: environments/prod.tfvars
      gcp_project_id: mtopps-iac
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```