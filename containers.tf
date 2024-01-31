resource "scaleway_container_namespace" "namespaces" {
  for_each = local.container_namespaces

  // mandatory
  region     = each.value.region
  project_id = each.value.project_id
  name       = each.value.name

  // optional
  description                  = each.value.description
  environment_variables        = each.value.environment_variables
  secret_environment_variables = each.value.secret_environment_variables
}

resource "scaleway_container" "containers" {
  for_each = local.containers

  region = each.value.namespace.region

  // mandatory
  name         = each.value.container.name
  namespace_id = scaleway_container_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].id
  cpu_limit    = each.value.container.cpu_limit
  memory_limit = each.value.container.memory_limit
  privacy      = each.value.container.privacy

  // if registry_image is not set, use the built image
  // TODO: maybe we can do better and avoid generating the image name here (e.g. using a local, but good enough for now...)
  registry_image = each.value.container.registry_image != null ? each.value.container.registry_image : format("%s/%s:%s",
    scaleway_container_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].registry_endpoint,
    each.value.container.name,
    replace(
      time_static.container_built_images[each.key].id,
      "/[^0-9]/", // remove all special characters in RFC3339 string
      ""
    )
  )

  // optional
  port                         = each.value.container.port
  description                  = each.value.container.description
  environment_variables        = each.value.container.environment_variables
  secret_environment_variables = each.value.container.secret_environment_variables
  min_scale                    = each.value.container.min_scale
  max_scale                    = each.value.container.max_scale
  timeout                      = each.value.container.timeout
  http_option                  = each.value.container.http_option
  max_concurrency              = each.value.container.max_concurrency

  deploy = true
}

resource "scaleway_container_cron" "container_crons" {
  for_each = local.container_crons

  region = each.value.namespace.region

  name         = each.value.cron.name
  container_id = scaleway_container.containers[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.container.name)].id
  schedule     = each.value.cron.schedule
  args         = each.value.cron.args
}

// be careful, SQS must be activated, but it's probably the case if we define triggers, as we need the queue to exist
// and secret key used must have MessagingAndQueuingReadOnly permissions (to avoid 403)
resource "scaleway_container_trigger" "container_sqs_triggers" {
  for_each = local.container_sqs_triggers

  region = each.value.namespace.region

  name         = each.value.sqs.name
  container_id = scaleway_container.containers[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.container.name)].id

  sqs {
    // mandatory
    queue = each.value.sqs.queue

    // optional
    project_id = each.value.sqs.project_id
    region     = each.value.sqs.region
  }
}

// be careful, NATS must be activated, but it's probably the case if we define triggers, as we need the account + subject to exist
// and secret key used must have MessagingAndQueuingReadOnly permissions (to avoid 403)
resource "scaleway_container_trigger" "container_nats_triggers" {
  for_each = local.container_nats_triggers

  region = each.value.namespace.region

  name         = each.value.nats.name
  container_id = scaleway_container.containers[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.container.name)].id

  nats {
    // mandatory
    account_id = each.value.nats.account_id
    subject    = each.value.nats.subject

    // optional
    project_id = each.value.nats.project_id
    region     = each.value.nats.region
  }
}

resource "scaleway_container_domain" "container_domains" {
  for_each = local.container_domains

  region = each.value.namespace.region

  container_id = scaleway_container.containers[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.container.name)].id
  hostname     = each.value.domain
}

resource "scaleway_container_token" "namespace_tokens" {
  for_each = local.container_namespace_tokens

  region       = scaleway_container_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].region
  namespace_id = scaleway_container_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].id

  description = each.value.token.description
  expires_at  = each.value.token.expires_at
}

resource "scaleway_container_token" "container_tokens" {
  for_each = local.container_tokens

  region       = scaleway_container.containers[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.container.name)].region
  container_id = scaleway_container.containers[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.container.name)].id

  description = each.value.token.description
  expires_at  = each.value.token.expires_at
}
