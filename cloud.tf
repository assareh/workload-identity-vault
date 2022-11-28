terraform {
  cloud {
    organization = "hashidemos"

    workspaces {
      name = "demo-workload-identity-infra"
    }
  }
}