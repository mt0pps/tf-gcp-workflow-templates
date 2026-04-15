# tf-gcp-workflow-templates

Reusable GitHub Actions workflows for Terraform-based GCP repositories.

Current workflows:

- `.github/workflows/reusable-gcp-auth-smoke.yml`: validates GitHub OIDC auth to Google Cloud, confirms project access, and runs `terraform fmt -check` against a target directory.

Example caller:

```yaml
name: GCP Auth Smoke Test

on:
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

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