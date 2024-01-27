// TODO:
// - this will only work with Linux or MacOS (?) environments, but it's good enough for now
// - we don't use docker provider because build logs are not displayed, so instead we use a local-exec provisioner

resource "null_resource" "check_container_images_build_prerequisites" {
  count = length(local.container_images) > 0 ? 1 : 0

  provisioner "local-exec" {
    environment = {
      PUSH_SECRET_KEY = var.container_push_secret_key
    }

    command = <<EOT
      type docker > /dev/null 2>&1 || { echo "docker is not available, please install it"; exit 1; }
      [ -z "$PUSH_SECRET_KEY" ] && { echo "variable container_push_secret_key must be set. Otherwise, how can I push images built?"; exit 1; }

      echo "Docker is available and container_push_secret_key is not empty"
    EOT
  }
}

// be careful, secret key requires ContainerRegistryFullAccess to push to registry
// we use this resource to generate meaningful tags like "YYYYMMDDHHmmss" (changes every time a file changes in the build context)
resource "time_static" "container_built_images" {
  for_each = local.container_images

  provisioner "local-exec" {
    environment = {
      REGISTRY_ENDPOINT = scaleway_container_namespace.namespaces[format("%s/%s/%s", each.value.namespace.region, each.value.namespace.project_id, each.value.namespace.name)].registry_endpoint
      CONTAINER_NAME    = each.value.container.name
      TAG               = replace(self.id, "/[^0-9]/", "") // remove all special characters in RFC3339 string
      PUSH_SECRET_KEY   = var.container_push_secret_key
    }

    command = <<EOT
      IMAGE_FULL_NAME="$REGISTRY_ENDPOINT/$CONTAINER_NAME:$TAG"

      echo "Building $IMAGE_FULL_NAME"

      docker build \
        --file "${each.value.build.dockerfile}" \
        --tag $IMAGE_FULL_NAME \
        "${each.value.build.context}"

      echo "Pushing $IMAGE_FULL_NAME"

      echo $PUSH_SECRET_KEY | docker login $REGISTRY_ENDPOINT --username nologin --password-stdin
      docker push $IMAGE_FULL_NAME
      docker logout $REGISTRY_ENDPOINT
    EOT
  }

  depends_on = [null_resource.check_container_images_build_prerequisites]

  triggers = {
    file_in_build_context_has_changed = sha256(
      join("",
        [for f in tolist(fileset(each.value.build.context, "*")) : filesha256("${each.value.build.context}/${f}")]
      )
    )
  }
}
