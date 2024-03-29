// all the logic to parse the config YAML file into objects we can use in Terraform
// good luck reading and debugging this

locals {
  container_namespaces = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : {
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

  containers = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for c in(ns.containers) : {
            format("%s/%s/%s/%s", ns.region, ns.project_id, ns.name, c.name) = {
              namespace = {
                region     = ns.region
                project_id = ns.project_id
                name       = ns.name
              }
              container = {
                name                         = c.name
                cpu_limit                    = c.cpu_limit
                memory_limit                 = c.memory_limit
                registry_image               = contains(keys(c), "image") ? c.image : null // null means we will built the image and use it
                port                         = c.port                                      // port is normally optional, but I'd rather put it as mandatory to avoid surprises and common issues
                privacy                      = c.privacy
                description                  = contains(keys(c), "description") ? c.description : ""
                environment_variables        = contains(keys(c), "environment_variables") ? { for v in c.environment_variables : v.key => v.value } : {}
                secret_environment_variables = contains(keys(c), "secret_environment_variables") ? { for v in c.secret_environment_variables : v.key => v.value } : {}
                min_scale                    = contains(keys(c), "min_scale") ? c.min_scale : 0
                max_scale                    = contains(keys(c), "max_scale") ? c.max_scale : 1
                timeout                      = contains(keys(c), "timeout") ? c.timeout : 300
                http_option                  = contains(keys(c), "http_option") ? c.http_option : "redirected"
                max_concurrency              = contains(keys(c), "max_concurrency") ? c.max_concurrency : 50
              }
            }
          }
        ]
        ) : []
      ]
    ] : []
  )...)

  container_crons = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for f in(ns.containers) : [
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
                      container = {
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
    ] : []
  )...)

  container_sqs_triggers = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for f in(ns.containers) : [
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
                      container = {
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
    ] : []
  )...)

  container_nats_triggers = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for f in(ns.containers) : [
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
                      container = {
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
    ] : []
  )...)

  container_domains = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for f in(ns.containers) : [
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
                    container = {
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
    ] : []
  )...)

  container_namespace_tokens = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
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
    ] : []
  )...)

  container_tokens = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for f in(ns.containers) : [
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
                    container = {
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
    ] : []
  )...)
}

locals {
  container_images = merge(flatten(
    contains(keys(local.config), "container_namespaces") ? [
      for ns in local.config.container_namespaces : [
        contains(keys(ns), "containers") ? (
        [
          for f in(ns.containers) : [
            contains(keys(f), "build") ? (
              {
                format("%s/%s/%s/%s", ns.region, ns.project_id, ns.name, f.name) = {
                  namespace = {
                    region     = ns.region
                    name       = ns.name
                    project_id = ns.project_id
                  }
                  container = {
                    name = f.name
                  }
                  build = {
                    dockerfile = format("%s/%s", var.context_dir, contains(keys(f.build), "dockerfile") ? f.build.dockerfile : "${f.build.context}/Dockerfile")
                    context    = format("%s/%s", var.context_dir, f.build.context)
                  }
                }
              }
            ) : {}
          ]
        ]
        ) : []
      ]
    ] : []
  )...)
}
