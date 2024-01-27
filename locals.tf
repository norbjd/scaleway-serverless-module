locals {
  // decode the YAML file containing variables to inject into config file (using templating)
  env = fileexists(
    "${var.context_dir}/${var.env_filename}"
  ) ? yamldecode(file("${var.context_dir}/${var.env_filename}")) : {}

  // the config file, templated with env defined above
  config = yamldecode(
    templatefile(
      "${var.context_dir}/${var.config_filename}",
      local.env
    )
  )
}
