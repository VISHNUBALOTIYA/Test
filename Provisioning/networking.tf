resource "azurerm_virtual_network" "AKS_Cluster_VNet" {
  count               = contains(["AzureCni", "AzureCniDIp", "AzureCNIOverlay"], var.aks_networking) ? 1 : 0
  name                = "${var.environment}-${var.region}-aks-VNet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [lookup(var.aks_network_details, "vnetSnet")]

  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


resource "azurerm_subnet" "AKS_Cluster_SNet" {
  count                = contains(["AzureCni", "AzureCniDIp", "AzureCNIOverlay"], var.aks_networking) ? 1 : 0
  name                 = "AKSCluster_SNet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.AKS_Cluster_VNet[0].name
  address_prefixes     = [lookup(var.aks_network_details, "clusterSnet")]

}

resource "azurerm_subnet" "AKS_Cluster_PodSNet" {
  count                = var.aks_networking == "AzureCniDIp" ? 1 : 0
  name                 = "AKSCluster_PodSNet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.AKS_Cluster_VNet[0].name
  address_prefixes     = [lookup(var.aks_network_details, "podSnet")]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

##hard coded values 
resource "azurerm_private_link_service" "example" {
  name                = "example-privatelink"
  location            = var.location
  resource_group_name  = var.resource_group_name

  nat_ip_configuration {
    name      = azurerm_public_ip.example.name
    primary   = true
    subnet_id = azurerm_subnet.service.id
  }

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.example.frontend_ip_configuration.0.id,
  ]
}

resource "azurerm_private_endpoint" "example" {
  name                = "example-endpoint"
  location            = var.location
  resource_group_name  = var.resource_group_name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "example-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.example.id
    is_manual_connection           = false
  }
}