# scaleway-serverless-module validator

Used to validate a YAML config file used by [`scaleway-serverless-module` Terraform module](https://github.com/norbjd/scaleway-serverless-module). This can be executed before running using the module to ensure the YAML configuration file passed to the module is valid.

Install and test with:

```shell
go install github.com/norbjd/scaleway-serverless-module/scaleway-serverless-module-validator@main

# show usage
scaleway-serverless-module-validator -h
```

Ideally, we'd like the YAML config file to be validated by Terraform itself (when running `terraform validate`, for example), but we can't easily do this. So we use this separate validator.

When validation succeeds, `scaleway-serverless-module-validator` exits with a code 0. Otherwise, it exits with a different code (`1` if config is invalid, or another code for other errors), and logs show the errors found. For example:

```
$ ./scaleway-serverless-module-validator -context-dir /path/to/folder
2024/01/27 17:07:16 checking config validity against: https://raw.githubusercontent.com/norbjd/scaleway-serverless-module/main/scaleway-serverless-module-validator/config_json_schema.json
2024/01/27 17:07:16 config file used is: /path/to/folder/scaleway_serverless_config.yaml
2024/01/27 17:07:16 found some errors:
2024/01/27 17:07:16 - function_namespaces.0.functions.0.memory_limit: function_namespaces.0.functions.0.memory_limit must be one of the following: 128, 256, 512, 1024, 2048, 4096
2024/01/27 17:07:16 - function_namespaces.0.functions.0.privacy: function_namespaces.0.functions.0.privacy must be one of the following: "public", "private"
2024/01/27 17:07:16 invalid config

$ echo $?
1
```

## Examples

In these examples, we assume `/path/to/folder` is the folder where YAML config file (+ optional env file) are located.

### Validate against last module's JSON schema version (with or without env file)

```shell
scaleway-serverless-module-validator \
  -context-dir /path/to/folder
```

### Validate against a local JSON schema (useful for testing)

```shell
scaleway-serverless-module-validator \
  -json-schema /path/to/other_config_json_schema.json \
  -context-dir /path/to/folder
```

## TODO

- refactor code (for now I know it's crappy)
- `cron`'s `json_args` must be a valid JSON (don't know if it's possible to validate with JSON schema)
- `container`'s `image` must be valid (at least syntax)
- `function`'s `source` must point to an existing folder (unlikely to be possible to validate with JSON schema)
- `function`'s `handler` must be valid (unlikely to be possible to validate with JSON schema)
