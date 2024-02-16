#----------------------------------------------------------
# Resource group creation
#----------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "${var.region}-${var.project}-rg"
  location = var.rg_location
  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}


#AKS cluster Calling modules
module "AKS_cluster" {
  source                     = "repo url of AKS_cluster"
  aks_name                   = var.aks_name
  resource_group_name        = azurerm_resource_group.aks_rg.name
  region                     = local.region
  location                   = azurerm_resource_group.aks_rg.location
  systempool                 = var.systempool
  nodepool                   = var.nodepool
  environment                = local.environment
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.workspace["aksomsagent-laws"].id
  aks_networking             = "AzureCNIOverlay"
  cluster_admins             = var.cluster_admins
  cluster_readers            = var.cluster_readers
  cluster_writers            = var.cluster_writers
  KV_secret_provider         = true
  KV_secret_rotation         = "15m"
  acr_id                     = data.azurerm_container_registry.prdacr.id
  resource_group_id          = azurerm_resource_group.aks_rg.id
  tags                       = local.tags
  install_kured              = true
  kured_config               = var.kured_config
  private_cluster_enabled    = true
  aks_network_details        = var.aks_network_details
}
