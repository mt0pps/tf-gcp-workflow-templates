organization_id    = "123456789012"
billing_account_id = "000000-000000-000000"

entra_tenant_id = "00000000-0000-0000-0000-000000000000"

workforce_identity_configs = {
  "entra" = {
    entra_app_display_name     = "Google Cloud OIDC SSO Example"
    secret_expiration_duration = "8760h"
    workforce = {
      pool_id               = "example-wfif-pool"
      pool_display_name     = "Example WFIF Pool"
      pool_description      = "Example workforce identity federation pool"
      provider_id           = "example-wfif-provider"
      provider_display_name = "Example WFIF Provider"
      provider_description  = "Example workforce identity federation provider"
      session_duration      = "7200s"
    }
    entra_group_assignments = {
      gcp_wif_users = {
        group_object_id    = "00000000-0000-0000-0000-000000000000"
        group_display_name = "Example GCP WIF Users"
      }
    }
  }
}

workload_identity_configs = {
  github_actions = {
    project_id             = "example-iac-project"
    iac_service_account_id = "tf-iac-service-account"
    pool_id                = "github-actions"
    provider_id            = "github-actions"
    github_actions = {
      repository_owner = "example-org"
    }
  }
}
