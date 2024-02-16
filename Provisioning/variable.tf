variable "aks_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "location" {
  type        = string
  description = "which region AKS cluster has to be created"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "resource_group_id" {
  description = "Resource group id"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
}

variable "systempool" {
  type        = map(any)
  description = "this map contains default pool created during AKS creation"
}

variable "nodepool" {
  type        = map(any)
  description = "this map contains worker node pool created during AKS creation"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The log analytics workspace for oms agent "
}

variable "tags" {
  type = map(any)
}

variable "cluster_admins" {
  type        = list(string)
  description = "This is name of groups from azure AD"
}

variable "cluster_writers" {
  type        = list(string)
  description = "This is name of groups from azure AD"
}

variable "cluster_readers" {
  type        = list(string)
  description = "This is name of groups from azure AD"
}

variable "KV_secret_provider" {
  type        = bool
  description = "This will enable CSI secret driver in AKS , to fetch secret from Key vaults"
  default     = false
}

variable "KV_secret_rotation" {
  type        = string
  description = "The interval to poll for secret rotation"
  default     = "2m"
}

variable "acr_id" {
  type        = string
  description = "ACR id where docker images are stored"
}

variable "region" {
  type        = string
  description = "Region for the resources. use or usw"
}

variable "install_kured" {
  type    = bool
  default = false
}

variable "kured_config" {
  type        = map(any)
  description = "the configuartion values supplied for kured chart"
  default = {
  }
}

variable "aks_networking" {
  type        = string
  description = "AKS Network Type KubeNet or AzureCni or AzureCniDIp or AzureCNIOverlay"
  default     = "KubeNet"
}

variable "cluster_settings" {
  type        = map(any)
  description = "Cluster settings"
  default     = {}
}

variable "network_policy" {
  type        = string
  description = "AKS Network Policy"
  default     = "calico"
}

variable "aks_network_details" {
  type        = map(any)
  description = "AKS Subnet Ranges"
  default = {
    vnetSnet       = "10.240.0.0/12" #Cluster VNET Address Space
    clusterSnet    = "10.241.0.0/19" #Cluster Subnet Address space
    podSnet        = "10.245.0.0/16" #POD  Subnet Address space
    serviceCidr    = "10.0.0.0/16"   #Cervice CIDR
    dns_service_ip = "10.0.0.10"     #DNS Service IP
    pod_cidr       = "10.16.0.0/16"

  }
}

variable "private_cluster_enabled" {
  type        = bool
  default     = false
  description = "Flag to Enable Private Cluster"
}

variable "private_dns_zone_id" {
  default     = "System"
  description = "Custom Private DNS Zone ID (Other valid values : System, None)"
}

variable "identity_type" {
  type        = string
  default     = "SystemAssigned"
  description = "Type of Identity (Valid values : SystemAssigned, UserAssigned)"
}

variable "metric_allowed_labels" {
  default     = null
  description = "List of Allowed Metric Labels"
}

variable "metric_allowed_annotations" {
  default     = null
  description = "List of Allowed Metric Annotations"
}
