variable "context_dir" {
  type        = string
  default     = "."
  description = "The base directory where config is located, and from which relative paths (e.g. functions codes, containers build context) are resolved"
}

variable "config_filename" {
  type        = string
  default     = "scaleway_serverless_config.yaml"
  description = "Name of the config file. This file must be located in context_dir"
}

variable "env_filename" {
  type        = string
  default     = ".scaleway_serverless_config.env.yaml"
  description = "Name of the file used to store variables used to template the config file. This file must be located in context_dir"
}

variable "container_push_secret_key" {
  type        = string
  default     = ""
  description = "If you're using containers with custom images, this is the SCW secret key used to push images in the SCW container registry after building them"
}
