resource "scaleway_mnq_sqs" "main" {}

resource "scaleway_mnq_sqs_credentials" "main" {
  name       = "sqs-credentials"
  project_id = scaleway_mnq_sqs.main.project_id

  permissions {
    can_manage = true
  }
}

resource "scaleway_mnq_sqs_queue" "queue1" {
  name         = "queue1"
  sqs_endpoint = scaleway_mnq_sqs.main.endpoint
  access_key   = scaleway_mnq_sqs_credentials.main.access_key
  secret_key   = scaleway_mnq_sqs_credentials.main.secret_key
}

resource "scaleway_mnq_sqs_queue" "queue2" {
  name         = "queue2"
  sqs_endpoint = scaleway_mnq_sqs.main.endpoint
  access_key   = scaleway_mnq_sqs_credentials.main.access_key
  secret_key   = scaleway_mnq_sqs_credentials.main.secret_key
}
