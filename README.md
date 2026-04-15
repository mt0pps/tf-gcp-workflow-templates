# tf-gcp-workflow-templates

Reusable GitHub Actions workflows for Terraform-based GCP repositories.

## Workflows

### gcp-auth-smoke.yml

Validates GitHub OIDC auth to Google Cloud, confirms project access, then runs `terraform validate` and `tflint` against a target directory.

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
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/gcp-auth-smoke.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      terraform_directory: 3-networking
      gcp_project_id: mtopps-iac
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### terraform-ci.yml

Runs Terraform CI checks: validate, lint, and PR plan comments.

**Inputs:**
- `runner` (optional, default: `arc-runner-set`)
- `terraform_version` (optional, default: `1.12.2`)
- `directory` (required): Terraform stack directory
- `environment` (optional): Environment key for a single plan run
- `tfvars` (optional): tfvars file path for a single plan run
- `plan_matrix` (optional): JSON array for matrix plan runs
- `max_parallel` (optional): Maximum matrix parallelism
- `tfplan2md_version` (optional): `tfplan2md` release version
- `post_plan_comment` (optional): Toggle sticky PR plan comments
- `gcp_workload_identity_provider` (optional): For plan auth
- `gcp_service_account` (optional): For plan auth

**Example:**
```yaml
jobs:
  ci:
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/terraform-ci.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      directory: 0-bootstrap
      environment: prod
      tfvars: environments/prod.tfvars
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### terraform-plan-comment.yml

Generates a Terraform plan, renders it with `tfplan2md`, and creates or updates a sticky PR comment for the matching stack and environment.

### terraform-cd.yml

Runs Terraform apply for a single environment or a matrix of environments on `main`.