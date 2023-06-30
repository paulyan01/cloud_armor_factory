locals {
  cloud_armor_policies = [for f in fileset("../cloudarmorconfigs", "[^_]*.yaml") : yamldecode(file("../cloudarmorconfigs/${f}"))]

  cloud_armor_list = flatten([
    for cloud_armor_policy in local.cloud_armor_policies : [
      for policy in try(sa.central_policy, []) : {
        name               = account.name
        source_project     = account.source_project
        users              = try(account.sa_users, [])
        assign_sauser      = try(account.assign_sauser, [])
        org_role           = try(account.org_role, [])
        folder_roles       = try(account.folder_roles, [])
        project_roles      = try(account.project_roles, [])
        custom_role        = try(account.custom_role, [])
        display_name       = try(account.dispay_name, "SA-Factory managed")
      }
    ]
  ])

  custom_role_list = flatten([
    for account in local.sa_list : [
      for custom in account.custom_role : {
          name           = account.name
          source_project = account.source_project
          target_id      = try(custom.target_id, [])
          target_level   = try(custom.target_level, [])
          permissions    = try(custom.permissions, [])
        }
      ]
    ])

  sauser_list = flatten([
    for account in local.sa_list : [
      for sauser in account.assign_sauser : {
        name = account.name
        member         = "${account.name}@${account.source_project}.iam.gserviceaccount.com"
        sa             = try(sauser, "")
      }
    ]
  ])
}


module "cloud_armor" {
  source = "./modules/cloud-armor"
  for_each     = { for policy in local.cloud_armor_list : "${sa.name}-${sa.source_project}" => sa }
  project_id = var.project_id
  name = var.policy_name
  description = var.policy_description

  json_parsing = "STANDARD"
  #Enable Adaptive Protection
  layer_7_ddos_defense_enable = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"

  default_rule_action          = "deny(404)"
  #Add pre-configured rules
  #Set target to lb backend
  pre_configured_rules = {

    "sqli_level4" = {
      action          = "deny(502)"
      priority        = 1
      description  = "SQL injection sensitivity level 4"
      target_rule_set = "sqli-v33-stable"
      sensitivity_level  = 4
    }

    "xss_level2" = {
      action                  = "deny(502)"
      priority                = 2
      description             = "Cross-site scripting sensitivity level 2"
      target_rule_set         = "xss-v33-stable"
      sensitivity_level       = 2
    }

    "lfi_level1" = {
      action                  = "deny(502)"
      priority                = 3
      description             = "Local file inclusion sensitivity level 1"
      target_rule_set         = "lfi-v33-stable"
      sensitivity_level       = 1
    }

    "rce_level3" = {
      action                  = "deny(502)"
      priority                = 4
      description             = "Remote code execution sensitivity level 3"
      target_rule_set         = "rce-v33-stable"
      sensitivity_level       = 3
    }

    "rfi_level2" = {
      action          = "deny(502)"
      priority        = 5
      description     = "Remote file inclusion sensitivity level 2"
      redirect_type   = "GOOGLE_RECAPTCHA"
      target_rule_set = "rfi-v33-stable"
      sensitivity_level = 2
    }

    "method-enforcement_level1" = {
      action = "deny(502)"
      priority = 6
      description  = "Method enforcement sensitivity level 1"
      target_rule_set = "methodenforcement-v33-stable"
      sensitivity_level = 1
    }

    "scanner-detection_level2" = {
      action = "deny(502)"
      priority = 7
      description  = "Scanner detection sensitivity level 2"
      target_rule_set = "scannerdetection-v33-stable"
      sensitivity_level = 2
    }

    "protocol-attack_level3" = {
      action = "deny(502)"
      priority = 8
      description  = "Scanner detection sensitivity level 3"
      target_rule_set = "protocolattack-v33-stable"
      sensitivity_level = 3
    }

    "php_level1" = {
      action                  = "deny(502)"
      priority                = 9
      description             = "PHP sensitivity level 1"
      target_rule_set         = "php-v33-stable"
      sensitivity_level       = 1
    }

    "sesion-fixation-level1" = {
      action                  = "deny(502)"
      priority                = 10
      description             = "Session fixation sensitivity level 1"
      target_rule_set         = "sessionfixation-v33-stable"
      sensitivity_level       = 1
    }

    "java-attack-level3" = {
      action                  = "deny(502)"
      priority                = 11
      description             = "Java attack sensitivity level 3"
      target_rule_set         = "java-v33-stable"
      sensitivity_level       = 3
    }

    "nodejs-attack-level1" = {
      action                  = "deny(502)"
      priority                = 12
      description             = "NodeJS attack sensitivity level 1"
      target_rule_set         = "nodejs-v33-stable"
      sensitivity_level       = 1
    }

    "cve-level3" = {
      action                  = "deny(502)"
      priority                = 13
      description             = "CVEs sensitivity level 3"
      target_rule_set         = "cve-canary"
      sensitivity_level       = 3
    }

  }
}