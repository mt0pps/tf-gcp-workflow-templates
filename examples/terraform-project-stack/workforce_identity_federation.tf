module "workforce_identity_federation" {
  for_each = var.workforce_identity_configs

  source = "../modules/workforce-identity-federation"

  gcp_organization_id = var.organization_id
  workforce           = each.value.workforce

  entra_tenant_id            = var.entra_tenant_id
  entra_app_display_name     = each.value.entra_app_display_name
  secret_expiration_duration = each.value.secret_expiration_duration
  optional_claims            = each.value.optional_claims

  entra_group_assignments = each.value.entra_group_assignments
}
