module "scaleway_serverless" {
  source = "git::https://github.com/norbjd/scaleway-serverless-module.git?ref=main"

  container_push_secret_key = var.container_push_secret_key
  env = {
    "var2": "env_var_var2_value",
  }

  // to be able to create triggers, we just need to wait until the queues are created
  depends_on = [
    scaleway_mnq_sqs_queue.queue1,
    scaleway_mnq_sqs_queue.queue2,
  ]
}
