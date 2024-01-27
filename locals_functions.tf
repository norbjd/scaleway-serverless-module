// all the logic to parse the config YAML file into objects we can use in Terraform
// good luck reading and debugging this

locals {
  function_namespaces = merge(flatten(
    contains(keys(local.config), "function_namespaces") ? [
      for ns in local.config.function_namespaces : {
        format("%s/%s/%s", ns.region, ns.project_id, ns.name) = {
          region                       = ns.region
          project_id                   = ns.project_id
          name                         = ns.name
          description                  = contains(keys(ns), "description") ? ns.description : ""
          environment_variables        = contains(keys(ns), "environment_variables") ? { for v in ns.environment_variables : v.key => v.value } : {}
          secret_environment_variables = contains(keys(ns), "secret_environment_variables") ? { for v in ns.secret_environment_variables : v.key => v.value } : {}
        }
      }
    ] : []
  )...)

  functions = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "functions") ? (
        [
          for f in(ns.functions) : {
            format("%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name) = {
              namespace = {
                region     = ns.region
                project_id = ns.project_id
                name       = ns.name
              }
              function = {
                name                         = f.name
                runtime                      = f.runtime
                memory_limit                 = f.memory_limit
                handler                      = f.handler
                source                       = f.source
                privacy                      = f.privacy
                description                  = contains(keys(f), "description") ? f.description : ""
                environment_variables        = contains(keys(f), "environment_variables") ? { for v in f.environment_variables : v.key => v.value } : {}
                secret_environment_variables = contains(keys(f), "secret_environment_variables") ? { for v in f.secret_environment_variables : v.key => v.value } : {}
                min_scale                    = contains(keys(f), "min_scale") ? f.min_scale : 0
                max_scale                    = contains(keys(f), "max_scale") ? f.max_scale : 1
                timeout                      = contains(keys(f), "timeout") ? f.timeout : 300
                http_option                  = contains(keys(f), "http_option") ? f.http_option : "redirected"
              }
            }
          }
        ]
      ) : []
    ]
  ])...)

  function_crons = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "functions") ? (
        [
          for f in(ns.functions) : [
            contains(keys(f), "triggers") ? (
              contains(keys(f.triggers), "crons") ? (
                [
                  for c in(f.triggers.crons) :
                  {
                    format("%s/%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name, c.name) = {
                      namespace = {
                        region     = ns.region
                        name       = ns.name
                        project_id = ns.project_id
                      }
                      function = {
                        name = f.name
                      }
                      cron = {
                        name     = c.name
                        schedule = c.schedule
                        args     = jsonencode(jsondecode(c.json_args))
                      }
                    }
                  }
                ]
              ) : []
            ) : []
          ]
        ]
      ) : []
    ]
  ])...)

  function_sqs_triggers = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "functions") ? (
        [
          for f in(ns.functions) : [
            contains(keys(f), "triggers") ? (
              contains(keys(f.triggers), "sqs") ? (
                [
                  for t in(f.triggers.sqs) :
                  {
                    format("%s/%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name, t.name) = {
                      namespace = {
                        region     = ns.region
                        name       = ns.name
                        project_id = ns.project_id
                      }
                      function = {
                        name = f.name
                      }
                      sqs = {
                        name        = t.name
                        description = contains(keys(t), "description") ? t.description : ""
                        queue       = t.queue
                        project_id  = contains(keys(t), "project_id") ? t.project_id : ns.project_id
                        region      = contains(keys(t), "region") ? t.region : ns.region
                      }
                    }
                  }
                ]
              ) : []
            ) : []
          ]
        ]
      ) : []
    ]
  ])...)

  function_nats_triggers = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "functions") ? (
        [
          for f in(ns.functions) : [
            contains(keys(f), "triggers") ? (
              contains(keys(f.triggers), "nats") ? (
                [
                  for t in(f.triggers.nats) :
                  {
                    format("%s/%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name, t.name) = {
                      namespace = {
                        region     = ns.region
                        name       = ns.name
                        project_id = ns.project_id
                      }
                      function = {
                        name = f.name
                      }
                      nats = {
                        name        = t.name
                        description = contains(keys(t), "description") ? t.description : ""
                        account_id  = t.account_id
                        subject     = t.subject
                        project_id  = contains(keys(t), "project_id") ? t.project_id : ns.project_id
                        region      = contains(keys(t), "region") ? t.region : ns.region
                      }
                    }
                  }
                ]
              ) : []
            ) : []
          ]
        ]
      ) : []
    ]
  ])...)

  function_domains = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "functions") ? (
        [
          for f in(ns.functions) : [
            contains(keys(f), "domains") ? (
              [
                for d in(toset(f.domains)) :
                {
                  format("%s/%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name, d) = {
                    namespace = {
                      region     = ns.region
                      name       = ns.name
                      project_id = ns.project_id
                    }
                    function = {
                      name = f.name
                    }
                    domain = d
                  }
                }
              ]
            ) : []
          ]
        ]
      ) : []
    ]
  ])...)

  function_namespace_tokens = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "tokens") ? (
        [
          for t in ns.tokens : {
            // we can't pass a unique name to a token, so we use the description as the unique discriminator of tokens
            format("%s/%s/%s/%s", ns.region, ns.project_id, ns.name, t.description) = {
              namespace = {
                region     = ns.region
                project_id = ns.project_id
                name       = ns.name
              }
              token = {
                description = contains(keys(t), "description") ? t.description : ""
                expires_at  = contains(keys(t), "expires_at") ? t.expires_at : null
              }
            }
          }
        ]
      ) : []
    ]
  ])...)

  function_tokens = merge(flatten([
    for ns in local.config.function_namespaces : [
      contains(keys(ns), "functions") ? (
        [
          for f in(ns.functions) : [
            contains(keys(f), "tokens") ? (
              [
                for t in f.tokens :
                {
                  // we can't pass a unique name to a token, so we use the description as the unique discriminator of tokens
                  format("%s/%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name, t.description) = {
                    namespace = {
                      region     = ns.region
                      name       = ns.name
                      project_id = ns.project_id
                    }
                    function = {
                      name = f.name
                    }
                    token = {
                      description = contains(keys(t), "description") ? t.description : ""
                      expires_at  = contains(keys(t), "expires_at") ? t.expires_at : null
                    }
                  }
                }
              ]
            ) : []
          ]
        ]
      ) : []
    ]
  ])...)
}
