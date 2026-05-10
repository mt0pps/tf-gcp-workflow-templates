# tf-gcp-workflow-templates

Reusable GitHub Actions workflows for Terraform-based GCP repositories.

## Project Structure

```
.github/
├── actions/                    # Composite actions
│   ├── gcp-auth/
│   ├── terraform-setup/
│   ├── terraform-validate/
│   ├── terraform-plan/
│   └── terraform-apply/
├── workflows/
│   ├── terraform-ci.yml       # Validate, lint, and plan
│   ├── terraform-cd.yml       # Apply on main
│   └── terraform-cicd.yml     # Unified CI/CD orchestration
└── dependabot.yml

bin/
└── tinitgcp                   # Backend initialization helper

examples/
├── gcp-auth.yml
└── terraform-cicd.yml
```

## Architecture

The workflows are organized as follows:

- **Workflows** (`terraform-ci.yml`, `terraform-cd.yml`, `terraform-cicd.yml`) are reusable and define the orchestration logic
- **Composite Actions** (`.github/actions/`) encapsulate common tasks (setup, validation, planning, applying)
- **Helper Scripts** (`bin/tinitgcp`) provide utility functions used by the workflows

This separation keeps workflows clean and maintainable while maximizing code reuse.

## Workflows

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

### terraform-cd.yml

Runs Terraform apply for a single environment or a matrix of environments on `main`.

**Inputs:**
- `runner` (optional, default: `arc-runner-set`)
- `terraform_version` (optional, default: `1.12.2`)
- `directory` (required): Terraform stack directory
- `environment` (optional): Environment key for a single apply run
- `tfvars` (optional): tfvars file path for a single apply run
- `apply_matrix` (optional): JSON array for matrix apply runs
- `gcp_workload_identity_provider` (optional): For apply auth
- `gcp_service_account` (optional): For apply auth

**Example:**
```yaml
jobs:
  cd:
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/terraform-cd.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      directory: 0-bootstrap
      environment: prod
      tfvars: environments/prod.tfvars
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### terraform-cicd.yml

Unified CI/CD workflow that orchestrates both CI and CD stages. Runs CI on PRs and pushes, then runs CD on pushes to `main`.

**Inputs:**
- `runner` (optional, default: `arc-runner-set`)
- `terraform_version` (optional, default: `1.12.2`)
- `directory` (required): Terraform stack directory
- `environment` (optional): Environment key for single runs
- `tfvars` (optional): tfvars file path for single runs
- `plan_matrix` (optional): JSON array for matrix CI runs
- `apply_matrix` (optional): JSON array for matrix CD runs
- `max_parallel` (optional): Maximum parallelism for matrix plan runs
- `gcp_workload_identity_provider` (optional): For auth
- `gcp_service_account` (optional): For auth

**Example:**
```yaml
jobs:
  cicd:
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/terraform-cicd.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      directory: 0-bootstrap
      environment: prod
      tfvars: environments/prod.tfvars
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

## Composite Actions

Reusable composite actions that abstract common Terraform and GCP authentication patterns. These are used internally by the workflows but can also be used directly in your own workflows.

### `gcp-auth`

Authenticates to Google Cloud using OpenID Connect.

**Inputs:**
- `gcp_workload_identity_provider` (required): Workload identity provider resource name
- `gcp_service_account` (required): Service account email

**Example:**
```yaml
jobs:
  gcp-auth-example:
    runs-on: arc-runner-set
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: mt0pps/tf-gcp-workflow-templates/.github/actions/gcp-auth@main
        with:
          gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}

      # Now use gcloud or Terraform with authenticated credentials
      - name: Verify Access
        run: gcloud projects describe ${{ vars.GCP_PROJECT_ID }}
```

### `terraform-setup`

Sets up Terraform, TFLint, and configures plugin caching for faster runs.

**Inputs:**
- `terraform_version` (required): Terraform version to install
- `directory` (required): Terraform stack directory

### `terraform-validate`

Runs `terraform validate` and `tflint` checks.

**Inputs:**
- `directory` (required): Terraform stack directory

### `terraform-plan`

Initializes Terraform backend using `tinitgcp` and runs `terraform plan`.

**Inputs:**
- `directory` (required): Terraform stack directory
- `environment` (required): Environment name
- `tfvars` (required): Path to tfvars file

### `terraform-apply`

Initializes Terraform backend using `tinitgcp` and runs `terraform apply`.

**Inputs:**
- `directory` (required): Terraform stack directory
- `environment` (required): Environment name
- `tfvars` (required): Path to tfvars file

## Helper Scripts

### `bin/tinitgcp`

Backend initialization helper for Terraform on GCP. Simplifies GCS backend configuration by reading environment-specific state paths from a `.tinitgcp` config file.

**Usage:**
```bash
# Single environment mode (requires .tinitgcp config in project)
tinitgcp <ENVIRONMENT>

# Direct backend configuration
tinitgcp <BUCKET/PREFIX> <ENVIRONMENT>

# Debug mode
tinitgcp -d <ENVIRONMENT>
```

**Config File Example (.tinitgcp):**
```bash
declare -A state_location
state_location[prod]="my-terraform-bucket/prod"
state_location[staging]="my-terraform-bucket/staging"
```

This script is automatically available to all workflows under `$GITHUB_WORKSPACE/bin/tinitgcp`.
