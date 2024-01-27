terraform {
  required_providers {
    // required to create Scaleway resources, obviously!
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.35.0"
    }
    // required to create archives for functions
    archive = {
      source = "hashicorp/archive"
    }
    // required for null_resource (things we can't manage easily with Terraform)
    null = {
      source = "hashicorp/null"
    }
    // required to generate static times for built containers tags
    time = {
      source = "hashicorp/time"
    }
  }
}
