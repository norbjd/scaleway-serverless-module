# Full example

A full example using `scaleway-serverless-module`. Resources created are listed in `scaleway_serverless_config.yaml`. Other "non-serverless" resources are also created by this example, like SQS queues (to be able to create SQS triggers).

## Configure your environment

```shell
# configure Scaleway provider
export SCW_DEFAULT_PROJECT_ID=00000000-0000-0000-0000-000000000000 # project id where you want to create resources
export SCW_DEFAULT_REGION=fr-par # or nl-ams, pl-waw, as you wish!
export SCW_ACCESS_KEY=SCW00000000000000000 # access key to create resources
export SCW_SECRET_KEY=00000000-0000-0000-0000-000000000000 # secret key linked to SCW_ACCESS_KEY

# configure Terraform variable container_push_secret_key (usually this is the same as SCW_SECRET_KEY)
export TF_VAR_container_push_secret_key=$SCW_SECRET_KEY

# replace region and project_id in .scaleway_serverless_config.env.yaml with the ones defined above
sed -i "s/region: \"fr-par\"/region: \"$SCW_DEFAULT_REGION\"/" .scaleway_serverless_config.env.yaml
sed -i "s/project_id: \"00000000-0000-0000-0000-000000000000\"/project_id: \"$SCW_DEFAULT_PROJECT_ID\"/" .scaleway_serverless_config.env.yaml
```

## Create resources

```shell
terraform init
terraform apply
```

## Clean resources

```shell
terraform destroy
```

Don't forget this once you're done testing, I'm not responsible if you keep resources in your project and get billed!
