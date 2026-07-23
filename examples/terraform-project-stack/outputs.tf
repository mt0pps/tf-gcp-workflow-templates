output "workforce_identity_federation" {
  description = "Workforce Identity Federation details keyed by config name"
  value = {
    for k, v in module.workforce_identity_federation : k => {
      workforce           = v.workforce
      console_signin_url  = v.console_signin_url
      signin_redirect_uri = v.signin_redirect_uri
    }
  }
}

output "workload_identity_federation" {
  description = "Workload Identity Federation pool and provider details keyed by config name"
  value = {
    for k, v in module.workload_identity_federation : k => {
      pool_name     = v.pool_name[k]
      provider_name = v.provider_name[k]
    }
  }
}
