module "workload_identity_federation" {
  for_each = var.workload_identity_configs

  source = "../modules/workload-identity-federation"

  project_id             = each.value.project_id
  iac_service_account_id = each.value.iac_service_account_id
  workload_config = {
    (each.key) = each.value
  }
}
