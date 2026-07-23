# tf-gcp-workflow-templates

Reusable GitHub Actions workflows for Terraform-based GCP repositories.

## Project Structure

```
.github/
├── actions/                        # Composite actions
│   ├── azure-auth/                # Azure AD OIDC authentication
│   ├── configure-git-for-modules/  # GitHub App token for private modules
│   ├── gcp-auth/                  # Google Cloud OIDC authentication
│   ├── terraform-apply/           # Run terraform apply with backend init
│   ├── terraform-plan/            # Run terraform plan with backend init
│   ├── terraform-setup/           # Setup Terraform and TFLint
│   └── terraform-validate/        # Run terraform validate and tflint
├── scripts/
│   └── tf_init                    # Backend initialization helper
├── workflows/
│   ├── terraform-ci.yml           # Single-env CI: validate, lint, plan
│   ├── terraform-ci-matrix.yml    # Multi-env CI with matrix
│   ├── terraform-cd.yml           # Single-env CD: apply on main
│   ├── terraform-cd-matrix.yml    # Multi-env CD with matrix
│   ├── terraform-cicd.yml         # Unified single-env CI/CD
│   ├── terraform-cicd-matrix.yml  # Unified multi-env CI/CD
│   └── dependabot.yml             # Dependabot configuration
└── ISSUE_TEMPLATE/

bin/
└── tf_init                        # Backward compatibility symlink/copy

examples/
├── gcp-auth.yml
├── terraform-cicd.yml
└── terraform-project-stack/      # Example Terraform stack layout
    ├── .tinitgcp
    ├── backend.tf
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    ├── variables.tf
    └── environments/
        └── prod.tfvars
```

## Architecture

The workflows are organized as follows:

- **Workflows** (6 reusable workflows) define orchestration logic. Each workflow exists in two variants:
  - Single-environment: `terraform-ci.yml`, `terraform-cd.yml`, `terraform-cicd.yml`
  - Multi-environment matrix: `terraform-ci-matrix.yml`, `terraform-cd-matrix.yml`, `terraform-cicd-matrix.yml`
- **Composite Actions** (7 reusable actions) encapsulate common tasks: authentication, setup, validation, planning, applying, and private module configuration
- **Helper Scripts** (`.github/scripts/tf_init`) provide backend initialization utilities

This separation keeps workflows clean and maintainable while maximizing code reuse.

## Terraform Project Layout

The workflows and composite actions expect each Terraform stack to follow a conventional layout so that `tf_init`, `terraform plan`, and `terraform apply` can locate the correct backend configuration and variable values for each environment.

```
<stack-directory>/
├── backend.tf                      # Terraform backend block (partial config)
├── providers.tf                    # Provider configuration
├── variables.tf                    # Variable declarations
├── outputs.tf                      # Output declarations
├── main.tf                         # Stack resources
├── .tinitgcp                       # Environment-to-state-path mapping (required for tf_init)
└── environments/
    ├── dev.tfvars                  # Variables for the dev environment
    ├── nprd.tfvars                 # Variables for the non-production environment
    ├── prod.tfvars                 # Variables for the production environment
    └── sand.tfvars                 # Variables for the sandbox environment
```

See [`examples/terraform-project-stack/`](examples/terraform-project-stack/) for a complete example.

### `.tinitgcp`

Required when calling `tf_init` with a single environment argument. Maps environment names to GCS backend paths. Supports variable substitution using `${folder_name}` and `${env}`.

```bash
declare -A state_location
state_location[prod]="terraform-state-storage-58hmzf/tfstate/${folder_name}/${env}"
state_location[nprd]="terraform-state-storage-58hmzf/tfstate/${folder_name}/${env}"
state_location[dev]="terraform-state-storage-58hmzf/tfstate/${folder_name}/${env}"
state_location[sand]="terraform-state-storage-58hmzf/tfstate/${folder_name}/${env}"
```

### `environments/*.tfvars`

Workflows pass these files to `terraform plan` and `terraform apply` via the `tfvars` input. Use the canonical short names (`dev.tfvars`, `nprd.tfvars`, `prod.tfvars`, `sand.tfvars`) and invoke workflows with matching environment keys.

### `backend.tf`

Use a partial backend configuration so `tf_init` can supply the bucket and prefix dynamically:

```hcl
terraform {
  backend "gcs" {}
}
```

## Workflows

### terraform-ci.yml

Runs Terraform CI checks on pull requests: validate, lint, and plan for a single environment.

**Inputs:**
- `runner` (optional, default: `mt0pps-runners`): GitHub Actions runner label
- `terraform_version` (optional, default: `1.12.2`): Terraform version to install
- `directory` (required): Terraform stack directory relative to repository root
- `environment` (optional): Environment name for plan runs
- `tfvars` (optional, deprecated): Path to tfvars file
- `gcp_workload_identity_provider` (optional): Google workload identity provider resource name
- `gcp_service_account` (optional): Google service account email

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
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### terraform-ci-matrix.yml

Runs Terraform CI checks with matrix support for multiple environments in parallel.

**Inputs:**
- `runner` (optional, default: `mt0pps-runners`): GitHub Actions runner label
- `terraform_version` (optional, default: `1.12.2`): Terraform version to install
- `directory` (required): Terraform stack directory relative to repository root
- `environments` (optional, default: `"[]"`, JSON array): Environment names for matrix plan runs
- `max_parallel` (optional, default: `1`): Maximum parallelism for matrix jobs
- `gcp_workload_identity_provider` (optional): Google workload identity provider resource name
- `gcp_service_account` (optional): Google service account email

**Example:**
```yaml
jobs:
  ci-matrix:
    uses: mt0pps/tf-gcp-workflow-templates/.github/workflows/terraform-ci-matrix.yml@main
    with:
      runner: arc-runner-set
      terraform_version: 1.12.2
      directory: 0-bootstrap
      environments: '["dev", "staging", "prod"]'
      max_parallel: 2
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### terraform-cd.yml

Runs Terraform apply on pushes to `main` for a single environment.

**Inputs:**
- `runner` (optional, default: `mt0pps-runners`): GitHub Actions runner label
- `terraform_version` (optional, default: `1.12.2`): Terraform version to install
- `directory` (required): Terraform stack directory relative to repository root
- `environment` (optional): Environment name for apply runs
- `tfvars` (optional, deprecated): Path to tfvars file
- `gcp_workload_identity_provider` (optional): Google workload identity provider resource name
- `gcp_service_account` (optional): Google service account email

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
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

### terraform-cd-matrix.yml

Runs Terraform apply with matrix support for multiple environments in parallel on pushes to `main`.

**Inputs:**
- `runner` (optional, default: `mt0pps-runners`): GitHub Actions runner label
- `terraform_version` (optional, default: `1.12.2`): Terraform version to install
- `directory` (required): Terraform stack directory relative to repository root
- `environments` (optional, default: `"[]"`, JSON array): Environment names for matrix apply runs
- `gcp_workload_identity_provider` (optional): Google workload identity provider resource name
- `gcp_service_account` (optional): Google service account email

### terraform-cicd.yml

Unified CI/CD workflow that orchestrates both validation/planning on PRs and apply on pushes to `main`. Supports a single environment.

**Inputs:**
- `runner` (optional, default: `mt0pps-runners`): GitHub Actions runner label
- `terraform_version` (optional, default: `1.12.2`): Terraform version to install
- `directory` (required): Terraform stack directory relative to repository root
- `environment` (optional): Environment name for plan and apply runs
- `tfvars` (optional, deprecated): Path to tfvars file
- `checkout_app_id` (optional): GitHub App ID for cloning private Terraform modules
- `azure_auth_enabled` (optional, default: `false`): Enable Azure AD authentication
- `gcp_workload_identity_provider` (optional): Google workload identity provider resource name
- `gcp_service_account` (optional): Google service account email

**Secrets:**
- `CHECKOUT_APP_PEM_FILE` (optional): GitHub App private key PEM file (required if `checkout_app_id` is set)

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
      gcp_workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      gcp_service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
    secrets:
      CHECKOUT_APP_PEM_FILE: ${{ secrets.CHECKOUT_APP_PEM_FILE }}
```

### terraform-cicd-matrix.yml

Unified CI/CD workflow with matrix support for multiple environments. Runs validation/planning in parallel on PRs and apply in parallel on pushes to `main`.

**Inputs:**
- `runner` (optional, default: `mt0pps-runners`): GitHub Actions runner label
- `terraform_version` (optional, default: `1.12.2`): Terraform version to install
- `directory` (required): Terraform stack directory relative to repository root
- `environments` (optional, default: `"[]"`, JSON array): Environment names for matrix CI/CD runs
- `max_parallel` (optional, default: `1`): Maximum parallelism for matrix jobs
- `checkout_app_id` (optional): GitHub App ID for cloning private Terraform modules
- `azure_auth_enabled` (optional, default: `false`): Enable Azure AD authentication
- `gcp_workload_identity_provider` (optional): Google workload identity provider resource name
- `gcp_service_account` (optional): Google service account email

**Secrets:**
- `CHECKOUT_APP_PEM_FILE` (optional): GitHub App private key PEM file (required if `checkout_app_id` is set)

## Composite Actions

Reusable composite actions that encapsulate common tasks. These are used internally by the workflows but can also be used directly in your own workflows.

### `azure-auth`

Authenticates to Azure AD using OpenID Connect (Workload Identity Federation). Sets Azure Terraform provider environment variables.

**Inputs:**
- `tenant_id` (required): Azure AD tenant ID
- `client_id` (required): Azure AD application (client) ID

**Environment variables set:**
- `ARM_TENANT_ID`: From input `tenant_id`
- `ARM_CLIENT_ID`: From input `client_id`
- `ARM_USE_OIDC`: Set to `true`

### `configure-git-for-modules`

Configures Git to use a GitHub App token for cloning private Terraform modules from GitHub.

**Inputs:**
- `checkout_app_id` (optional): GitHub App ID for private module access
- `pem_file` (optional): GitHub App private key PEM file content

**Outputs:**
- `token`: Generated GitHub App token (useful for downstream steps)

**Behavior:**
- If `checkout_app_id` is empty, this action is a no-op
- Otherwise, creates a token and configures git to rewrite GitHub URLs to use the token for authentication

### `gcp-auth`

Authenticates to Google Cloud using OpenID Connect.

**Inputs:**
- `gcp_workload_identity_provider` (required): Google workload identity provider resource name
- `gcp_service_account` (required): Google service account email

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

Sets up Terraform and TFLint for use in workflows.

**Inputs:**
- `terraform_version` (required, default: `1.15.7`): Terraform version to install
- `directory` (required): Terraform stack directory (used for validation context)
- `tflint_version` (required, default: `0.64.0`): TFLint version to install

**Behavior:**
- Installs the specified Terraform and TFLint versions
- Configures Terraform wrapper as disabled for direct CLI access
- Sets up TFLint for use by subsequent steps

### `terraform-validate`

Runs `terraform validate` and `tflint` checks on Terraform configuration.

**Inputs:**
- `directory` (required): Terraform stack directory

**Behavior:**
- Runs `terraform init -backend=false` to initialize without a backend
- Runs `terraform validate` to check configuration syntax
- Runs `tflint` recursively with module support
- Continues on lint warnings (non-blocking)

### `terraform-plan`

Initializes Terraform backend and runs `terraform plan`.

**Inputs:**
- `directory` (required): Terraform stack directory
- `environment` (required): Environment name (used for backend config via `.tinitgcp`)
- `tfvars` (required): Path to tfvars file

**Behavior:**
- Calls `.github/scripts/tf_init` to initialize the backend with environment-specific settings
- Runs `terraform plan` with the specified tfvars
- Outputs plan as JSON to `plan-<environment>.json`

### `terraform-apply`

Initializes Terraform backend and runs `terraform apply`.

**Inputs:**
- `directory` (required): Terraform stack directory
- `environment` (required): Environment name (used for backend config via `.tinitgcp`)
- `tfvars` (required): Path to tfvars file

**Behavior:**
- Calls `.github/scripts/tf_init` to initialize the backend with environment-specific settings
- Runs `terraform apply -auto-approve` with the specified tfvars

## Helper Scripts

### `.github/scripts/tf_init`

Backend initialization helper for Terraform on GCP. Simplifies GCS backend configuration by reading environment-specific state paths from a `.tinitgcp` config file in the project root or parent directories.

**Usage:**
```bash
# Single environment mode (requires .tinitgcp config in project)
tf_init <ENVIRONMENT>

# Direct backend configuration
tf_init <BUCKET/PREFIX> <ENVIRONMENT>

# Debug mode (prints commands)
tf_init -d <ENVIRONMENT>
```

**Config File Example (.tinitgcp):**
```bash
declare -A state_location
state_location[prod]="terraform-state-storage-58hmzf/tfstate/${folder_name}/prod"
state_location[staging]="terraform-state-storage-58hmzf/tfstate/${folder_name}/staging"
state_location[dev]="terraform-state-storage-58hmzf/tfstate/${folder_name}/dev"
```

**Behavior:**
- Searches for `.tinitgcp` file starting from the invocation directory and moving up through parent directories
- If `.tinitgcp` is found, reads the `state_location` array for the specified environment
- Supports variable substitution in paths (e.g., `${folder_name}`, `${env}`)
- Splits the path at the first `/` to separate bucket name from prefix
- Initializes Terraform backend with `terraform init -reconfigure -backend-config="bucket=<BUCKET>" -backend-config="prefix=<PREFIX>"`
- If environment-specific `.tfvars` file exists (e.g., `environments/prod.tfvars`), it is automatically located
- Supports sandbox environment alias mapping (sandbox → sand.tfvars)

## Usage Examples

### Single-Environment Project

See [`examples/terraform-project-stack/`](examples/terraform-project-stack/) for a complete example Terraform stack with:
- `.tinitgcp` configuration for backend state paths
- `environments/prod.tfvars` with example variable values
- `.github/workflows/terraform-example-stack.yml` showing how to invoke `terraform-cicd.yml`

### Multi-Environment Project

See [`examples/workflows/terraform-cicd-matrix.yml`](examples/workflows/terraform-cicd-matrix.yml) for a real-world example with:
- Multiple stacks (`shared-vpc-host-cicd`, `ncc-hub-cicd`)
- Matrix strategy applying to multiple environments in parallel
- Proper use of `environments` (JSON array) instead of single `environment` input
- `max_parallel` tuning for controlled concurrency

This script is automatically available to workflows via `.github/scripts/tf_init` and is called by both the `terraform-plan` and `terraform-apply` composite actions.
