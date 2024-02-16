variable "rg_location" {
  type        = string
  description = "Resource Group Location"
}

variable "region" {
  type        = string
  description = "Location"
  default     = "use"
}


variable "project" {
  type        = string
  description = "ProjectName"
}

variable "cosmos_db_account_name" {
  type        = string
  description = "Cosmos DB account Name"
}

variable "client_secret" {
    type        = string
  description = "ProjectName"
}

