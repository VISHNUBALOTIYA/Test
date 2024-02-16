
locals {
  tags = {
    env         = terraform.workspace
    project     = "XIO"
    createdBy   = "xtest"
    CreatedDate = timestamp()
  }
}

environment = terraform.workspace