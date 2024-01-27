# scaleway-serverless-module

A Terraform module to easily create Scaleway serverless functions and containers.

> [!WARNING]
> - this module is a work in progress, so **use with caution**
> - this module is **NOT** endorsed - nor supported - by Scaleway

Creates serverless functions and containers resources from a YAML config file.

## Example

`scaleway_serverless_config.yaml`:

```yaml
function_namespaces:
  - name: my-namespace-1
    region: ${region}
    project_id: ${project_id}
    description: "1st namespace"
    environment_variables:
      - key: var1
        value: value1
    secret_environment_variables:
      - key: secret_var1
        value: ${secret_var1}
    functions:
      - name: func1
        runtime: node20
        memory_limit: 512
        handler: handler.handle
        source: ./func1
        privacy: private
        description: "Just a simple function"
        min_scale: 0
        max_scale: 10
        timeout: 300
        triggers:
          crons:
            - name: cron1
              schedule: 0 0 * * *
              json_args: |
                {
                  "key1": "value1",
                  "key2": "value2"
                }
          sqs:
            - name: trigger-sqs-1
              queue: queue1
          nats:
             - name: trigger-nats-1
               account_id: "AXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
               subject: subject1
        domains:
           - some.domain.example.com
        tokens:
          - description: a function token
            expires_at: "2100-01-01T00:00:00+00:00"
container_namespaces:
  - name: my-namespace-1
    region: ${region}
    project_id: ${project_id}
    containers:
      - name: custom-nginx
        cpu_limit: 240
        memory_limit: 512
        build:
          context: ./custom_nginx
        port: 80
        privacy: public
        min_scale: 0
        max_scale: 10
```

> [!WARNING]
> Paths inside the config file (`function_namespaces.functions.source` or `container_namespaces.namespaces.build.context`) **MUST** be relative to the config file.

The config file also supports templating. You can inject variables by defining a `.scaleway_serverless_config.env.yaml` file:

```yaml
region: "fr-par"
secret_var1: "something"
project_id: "00000000-0000-0000-0000-000000000000"
```

## Motivation

This module is particularly useful for users that don't want to write resources with Terraform as it can be somehow verbose.

Just write a YAML file `scaleway_serverless_config.yaml` describing your resources (everybody loves YAML, see [format](#config-file-format)), your functions/containers code/images, and the following Terraform definition:

```hcl
terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.35.0"
    }
  }
}

// you must pass at least SCW_ACCESS_KEY and SCW_SECRET_KEY environment variables
// or, configure Scaleway provider as you want if you want to manage other Scaleway resources
provider "scaleway" {}

// optional: **only** if you want to build and push custom containers
variable "push_images_secret_key" {
  type    = string
  default = ""
}

module "scaleway_serverless" {
  source = "git::https://github.com/norbjd/scaleway-serverless-module.git?ref=main"

  container_push_secret_key = var.push_images_secret_key // optional
}
```

And voilà!

## Requirements

If you're using this module to build custom container images, `docker` **MUST** be installed, because it's used to build and push the images. If so, provide a valid value for the `container_push_secret_key` variable: this secret key will be used to push images to SCW container registry.

## Config file format

Config file must be in YAML format, and must match the JSON schema located [here](validator/config_json_schema.json).

> [!WARNING]
> JSON schema is far from being perfect, but it helps to catch obvious errors. I'll refine this schema with the time.

### Validate the config file

To validate the config file, you can use the validator provided [here](validator/):

```shell
go install github.com/norbjd/scaleway-serverless-module-validator@main

scaleway-serverless-module-validator -context-dir /path/to/dir
```

I highly encourage users to run the validator before running any `terraform` operation to catch common mistakes (e.g. invalid function name) before getting rejected by `terraform`, or worse, getting a cryptic error from the module (e.g. if `function_namespaces` contains a `string` instead of an `object`).

When developing locally, it's useful to add the JSON schema when editing config files, to have a quicker feedback:

- with JetBrains based IDEs: https://www.jetbrains.com/help/idea/json.html#ws_json_schema_add_custom
- with code: add `# yaml-language-server: $schema=https://raw.githubusercontent.com/norbjd/scaleway-serverless-module/main/validator/config_json_schema.json` at the top of the YAML file, assuming you have installed [this extension](https://github.com/redhat-developer/yaml-language-server)

See also [validator's README.md](validator/README.md) for more details.

## Examples

See [examples/full_example/scaleway_serverless_config.yaml](examples/full_example/scaleway_serverless_config.yaml) for a full example.

This YAML config file supports templating: define values in a `.scaleway_serverless_config.env.yaml` file (see [examples/full_example/.scaleway_serverless_config.env.yaml](examples/full_example/.scaleway_serverless_config.env.yaml)).

## Functions

When building the archive containing the function code, some files or folders could be ignored. This is useful to avoid putting not needed files in the archive.

To ignore files, just put a `.scaleway-serverless.ignore` alongside the function directory. Each line of the file is a file or folder that will be ignored when packaging:

```ignore
a_file_to_ignore
a_folder_to_ignore
```

> [!WARNING]
> This doesn't support wildcards.
> When ignoring folders, **DON'T** put `/` at the end.

## Terraform module details

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | >= 2.35.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | >= 2.35.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [null_resource.check_container_images_build_prerequisites](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [scaleway_container.containers](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container) | resource |
| [scaleway_container_cron.container_crons](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_cron) | resource |
| [scaleway_container_domain.container_domains](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_domain) | resource |
| [scaleway_container_namespace.namespaces](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_namespace) | resource |
| [scaleway_container_token.container_tokens](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_token) | resource |
| [scaleway_container_token.namespace_tokens](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_token) | resource |
| [scaleway_container_trigger.container_nats_triggers](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_trigger) | resource |
| [scaleway_container_trigger.container_sqs_triggers](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/container_trigger) | resource |
| [scaleway_function.functions](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function) | resource |
| [scaleway_function_cron.function_crons](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_cron) | resource |
| [scaleway_function_domain.function_domains](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_domain) | resource |
| [scaleway_function_namespace.namespaces](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_namespace) | resource |
| [scaleway_function_token.function_tokens](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_token) | resource |
| [scaleway_function_token.namespace_tokens](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_token) | resource |
| [scaleway_function_trigger.function_nats_triggers](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_trigger) | resource |
| [scaleway_function_trigger.function_sqs_triggers](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/function_trigger) | resource |
| [time_static.container_built_images](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [archive_file.functions](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_filename"></a> [config\_filename](#input\_config\_filename) | Name of the config file. This file must be located in context\_dir | `string` | `"scaleway_serverless_config.yaml"` | no |
| <a name="input_container_push_secret_key"></a> [container\_push\_secret\_key](#input\_container\_push\_secret\_key) | If you're using containers with custom images, this is the SCW secret key used to push images in the SCW container registry after building them. | `string` | `""` | no |
| <a name="input_context_dir"></a> [context\_dir](#input\_context\_dir) | The base directory where config is located, and from which relative paths (e.g. functions codes, containers build context) are resolved | `string` | `"."` | no |
| <a name="input_env_filename"></a> [env\_filename](#input\_env\_filename) | Name of the file used to store variables used to template the config file. This file must be located in context\_dir | `string` | `".scaleway_serverless_config.env.yaml"` | no |

### Outputs

No outputs.
<!-- END_TF_DOCS -->
