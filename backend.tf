terraform {
  cloud {
    organization = "sami600"

    workspaces {
      name = "cloud_armor_factory"
    }
  }
}
