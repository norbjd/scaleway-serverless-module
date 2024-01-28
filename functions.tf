resource "scaleway_function_namespace" "namespaces" {
  for_each = local.function_namespaces

  // mandatory
  region     = each.value.region
  project_id = each.value.project_id
  name       = each.value.name

  // optional
  description                  = each.value.description
  environment_variables        = each.value.environment_variables
  secret_environment_variables = each.value.secret_environment_variables
}

locals {
  ignore_filename = ".scaleway-serverless.ignore"
}

data "archive_file" "functions" {
  for_each = local.functions

  type       = "zip"
  source_dir = "${var.context_dir}/${each.value.function.source}"
  // if ignore file exists, exclude all files defined in that file + the file itself
  // be careful, it's not possible to use wildcards in this ignore file
  // to exclude a folder, write "my_folder" in it, not "my_folder/"
  // it sucks, but it's a restriction of archive_file: https://github.com/hashicorp/terraform-provider-archive/issues/62
  // maybe we can take another approach and define a ".include" file, and use fileset to retrieve the list of files to include
  // or use a null_resource with a local provisioner to do what we want...
  excludes = fileexists("${var.context_dir}/${each.value.function.source}/${local.ignore_filename}") ? (
    concat(split("\n", file("${var.context_dir}/${each.value.function.source}/${local.ignore_filename}")), [local.ignore_filename])
  ) : []
  output_path = "${replace(each.key, "/", "+")}.zip"
}

resource "scaleway_function" "functions" {
  for_each = local.functions

  region = each.value.namespace.region

  // mandatory
  name         = each.value.function.name
  handler      = each.value.function.handler
  namespace_id = scaleway_function_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].id
  runtime      = each.value.function.runtime
  memory_limit = each.value.function.memory_limit
  privacy      = each.value.function.privacy
  zip_file     = data.archive_file.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].output_path
  zip_hash     = data.archive_file.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].output_sha512

  // optional
  description                  = each.value.function.description
  environment_variables        = each.value.function.environment_variables
  secret_environment_variables = each.value.function.secret_environment_variables
  min_scale                    = each.value.function.min_scale
  max_scale                    = each.value.function.max_scale
  timeout                      = each.value.function.timeout
  http_option                  = each.value.function.http_option

  deploy = true
}

resource "scaleway_function_cron" "function_crons" {
  for_each = local.function_crons

  region = each.value.namespace.region

  name        = each.value.cron.name
  function_id = scaleway_function.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].id
  schedule    = each.value.cron.schedule
  args        = each.value.cron.args
}

// be careful, SQS must be activated, but it's probably the case if we define triggers, as we need the queue to exist
// and secret key used must have MessagingAndQueuingReadOnly permissions (to avoid 403)
resource "scaleway_function_trigger" "function_sqs_triggers" {
  for_each = local.function_sqs_triggers

  region = each.value.namespace.region

  name        = each.value.sqs.name
  function_id = scaleway_function.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].id

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
resource "scaleway_function_trigger" "function_nats_triggers" {
  for_each = local.function_nats_triggers

  region = each.value.namespace.region

  name        = each.value.nats.name
  function_id = scaleway_function.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].id

  nats {
    // mandatory
    account_id = each.value.nats.account_id
    subject    = each.value.nats.subject

    // optional
    project_id = each.value.nats.project_id
    region     = each.value.nats.region
  }
}

resource "scaleway_function_domain" "function_domains" {
  for_each = local.function_domains

  region = each.value.namespace.region

  function_id = scaleway_function.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].id
  hostname    = each.value.domain
}

resource "scaleway_function_token" "namespace_tokens" {
  for_each = local.function_namespace_tokens

  region       = scaleway_function_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].region
  namespace_id = scaleway_function_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].id

  description = each.value.token.description
  expires_at  = each.value.token.expires_at
}

resource "scaleway_function_token" "function_tokens" {
  for_each = local.function_tokens

  region      = scaleway_function.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].region
  function_id = scaleway_function.functions[format("%s/%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name, each.value.function.name)].id

  description = each.value.token.description
  expires_at  = each.value.token.expires_at
}
