variable "billing_account_id" {
  description = "The billing account ID to use for this project."
  type        = string
  nullable    = false
}

variable "organization_id" {
  description = "The organization ID to use for this project."
  type        = string
  nullable    = false
}

variable "entra_tenant_id" {
  description = "Azure AD tenant ID shared across all Workforce Identity Federation setups."
  type        = string
}

variable "workforce_identity_configs" {
  description = "Map of Workforce Identity Federation configurations keyed by a logical name. Each entry produces one workforce pool, provider, and optional set of IAM bindings."
  type = map(object({
    entra_app_display_name     = optional(string, "GCP Workforce OIDC")
    secret_expiration_duration = optional(string, "8760h")
    optional_claims = optional(object({
      id_token = optional(list(object({
        name                  = string
        additional_properties = optional(list(string), [])
        essential             = optional(bool, false)
        source                = optional(string)
      })), [])
    }), null)
    workforce = object({
      pool_id               = string
      pool_display_name     = optional(string, "Entra ID OIDC Workforce Pool")
      pool_description      = optional(string, "")
      provider_id           = string
      provider_display_name = optional(string, "Entra ID OIDC Provider")
      provider_description  = optional(string, "")
      session_duration      = optional(string, "3600s")
    })
    entra_group_assignments = optional(map(object({
      group_object_id    = string
      group_display_name = string
      description        = optional(string, "")
    })), {})
  }))
  default = {}
}

variable "workload_identity_configs" {
  description = "Map of Workload Identity Federation configurations keyed by a logical name. Each entry must set exactly one of 'github_actions' or 'custom'. Pool and provider details are flattened at the entry level."
  type = map(object({
    project_id             = optional(string)
    iac_service_account_id = optional(string, "tf-iac-service-account")

    # Pool configuration
    pool_id           = string
    pool_display_name = optional(string)
    pool_description  = optional(string)
    pool_disabled     = optional(bool, false)

    # Provider configuration
    provider_id                  = string
    provider_display_name        = optional(string)
    provider_description         = optional(string)
    provider_attribute_condition = optional(string)
    provider_attribute_mapping   = optional(map(string), {})
    provider_oidc = optional(object({
      allowed_audiences = optional(list(string), [])
      issuer_uri        = optional(string)
    }), {})

    # OIDC provider type (choose one)
    github_actions = optional(object({
      repository_owner    = string
      repositories        = optional(list(string), [])
      allowed_audiences   = optional(list(string), [])
      attribute_condition = optional(string)
    }), null)

    custom = optional(object({
      attribute_condition = string
      attribute_mapping   = map(string)
      oidc = object({
        allowed_audiences = list(string)
        issuer_uri        = string
      })
    }), null)

    additional_attribute_mapping = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.workload_identity_configs) : ((try(v.github_actions, null) != null && try(v.custom, null) == null) || (try(v.github_actions, null) == null && try(v.custom, null) != null))])
    error_message = "Each workload_identity_configs entry must set exactly one of 'github_actions' or 'custom'."
  }
}
