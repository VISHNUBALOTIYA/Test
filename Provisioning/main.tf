locals {
  custom_private_dns_required = !contains(["System", "None"], var.private_dns_zone_id)
  identity_ids                = var.identity_type == "UserAssigned" ? [azurerm_user_assigned_identity.aks_identity[0].id] : []
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.environment}-${var.region}-${var.aks_name}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.custom_private_dns_required ? null : "xio"
  # dns_prefix_private_cluster to be set only when using Custom Private DNS Zone
  dns_prefix_private_cluster = local.custom_private_dns_required ? "xio" : null
  node_resource_group        = "node-${var.resource_group_name}"
  private_cluster_enabled    = var.private_cluster_enabled
  private_dns_zone_id        = var.private_cluster_enabled ? var.private_dns_zone_id : null
  sku_tier                   = lookup(var.cluster_settings, "sku_tier", "Free")
  image_cleaner_enabled      = lookup(var.cluster_settings, "image_cleaner_enabled", true)
  monitor_metrics {
    annotations_allowed = var.metric_allowed_annotations
    labels_allowed      = var.metric_allowed_labels
  }

  workload_autoscaler_profile {
    # Not recommended to use both KEDA and VPA at same time.
    keda_enabled                    = lookup(var.cluster_settings, "keda_enabled", false)
    vertical_pod_autoscaler_enabled = lookup(var.cluster_settings, "vertical_pod_autoscaler_enabled", false)
  }



  dynamic "network_profile" {
    for_each = try(var.aks_networking, "Kubenet") != "Kubenet" ? { network_profile = true } : {}
    content {
      network_plugin      = "azure"
      load_balancer_sku   = "standard"
      network_policy      = var.network_policy
      network_plugin_mode = var.aks_networking == "AzureCNIOverlay" ? "overlay" : null
      pod_cidr            = var.aks_networking == "AzureCNIOverlay" ? lookup(var.aks_network_details, "pod_cidr") : null
      service_cidr        = lookup(var.aks_network_details, "serviceCidr")
      dns_service_ip      = lookup(var.aks_network_details, "dns_service_ip")
    }
  }


  default_node_pool {
    name                         = "systempool"
    vm_size                      = lookup(var.systempool, "size")
    enable_auto_scaling          = true
    min_count                    = lookup(var.systempool, "min")
    max_count                    = lookup(var.systempool, "max")
    only_critical_addons_enabled = true
    temporary_name_for_rotation  = "tmpnodepool1"
    os_sku                       = "AzureLinux"
    vnet_subnet_id               = contains(["AzureCni", "AzureCniDIp", "AzureCNIOverlay"], var.aks_networking) ? azurerm_subnet.AKS_Cluster_SNet[0].id : null
    pod_subnet_id                = var.aks_networking == "AzureCniDIp" ? azurerm_subnet.AKS_Cluster_PodSNet[0].id : null
    type                         = lookup(var.systempool, "type", "VirtualMachineScaleSets")
    # Zones not supported for Free Tier
    zones = lookup(var.systempool, "zones", null) == null ? null : range(1, tonumber(lookup(var.systempool, "zones", "")) + 1)
  }

  #public_network_access_enabled = false
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  oms_agent {
    msi_auth_for_monitoring_enabled = true
    log_analytics_workspace_id      = var.log_analytics_workspace_id
  }

  identity {
    # For AKS to manage Custom Private DNS zone, it is mandatory to use UserAssigned identity
    type         = var.identity_type
    identity_ids = local.identity_ids
  }

  local_account_disabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = ["1d2e375c-6310-4d18-9d2d-58a29ca063af"]
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = var.KV_secret_provider
    secret_rotation_interval = var.KV_secret_rotation
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count, tags
    ]
  }
  depends_on = [
    # In case of UserAssigned Identity below dependencies apply
    azurerm_role_assignment.userid_clusterRg_network_contributor,
    azurerm_role_assignment.dns_contributor
  ]
}

#-------------------------------------------------------------
# Creating Cluster Node Pool
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool
#-------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "aks_node_pool" {
  for_each = var.nodepool
  # A Windows Node Pool cannot have a name longer than 6 characters.
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = lookup(each.value, "vm_size")
  max_pods              = lookup(each.value, "max_pods", "250")
  enable_auto_scaling   = true
  min_count             = lookup(each.value, "min")
  max_count             = lookup(each.value, "max")
  # Possible values are AzureLinux, CBLMariner, Mariner, Ubuntu, Windows2019 and Windows2022
  os_sku = lookup(each.value, "os", "AzureLinux")
  # Possible values are Linux and Windows. Defaults to Linux
  os_type        = lookup(each.value, "os_type", "Linux")
  tags           = var.tags
  vnet_subnet_id = contains(["AzureCni", "AzureCniDIp", "AzureCNIOverlay"], var.aks_networking) ? azurerm_subnet.AKS_Cluster_SNet[0].id : null
  pod_subnet_id  = var.aks_networking == "AzureCniDIp" ? azurerm_subnet.AKS_Cluster_PodSNet[0].id : null
  # Zones not supported for Free Tier
  zones = lookup(each.value, "zones", null) == null ? null : range(1, tonumber(lookup(each.value, "zones")) + 1)

  lifecycle {
    ignore_changes = [
      node_count, tags
    ]
  }
}

data "azuread_group" "cluster_admin_group" {
  for_each     = toset(var.cluster_admins)
  display_name = each.key
}

data "azuread_group" "cluster_writer_group" {
  for_each     = toset(var.cluster_writers)
  display_name = each.key
}

data "azuread_group" "cluster_reader_group" {
  for_each     = toset(var.cluster_readers)
  display_name = each.key
}

resource "azurerm_role_assignment" "cluster_admins" {
  for_each             = toset(var.cluster_admins)
  principal_id         = data.azuread_group.cluster_admin_group[each.key].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks.id
}

resource "azurerm_role_assignment" "cluster_writers" {
  for_each             = toset(var.cluster_writers)
  principal_id         = data.azuread_group.cluster_writer_group[each.key].id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  scope                = azurerm_kubernetes_cluster.aks.id
}

#-------------------------------------------------------------
# Creating User identity for the case Private AKS managing Custom Private DNS zone
#-------------------------------------------------------------

resource "azurerm_user_assigned_identity" "aks_identity" {
  count               = var.identity_type == "UserAssigned" ? 1 : 0
  name                = "${var.environment}-${var.region}-${var.aks_name}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}
#-------------------------------------------------------------
# Private DNS Zone Contributor ROle required for AKS to manage Custom Private DNS zone
#-------------------------------------------------------------
resource "azurerm_role_assignment" "dns_contributor" {
  count                = var.identity_type == "UserAssigned" ? 1 : 0
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
}
#-------------------------------------------------------------
# Providing Network Contributor role to Cluster
# 1. To deploy Ingress Controller with Private IP. The IP is assigned from AKS Cluster Subnet
# 2. To allow Virtual private link creation between Custom Private DNS zone and Private AKS
# therefore the scope is the rg where Cluster VNET and Subnets are created.
#-------------------------------------------------------------
resource "azurerm_role_assignment" "sysid_clusterRg_network_contributor" {
  count                = var.identity_type == "SystemAssigned" ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = var.resource_group_id
}

#-------------------------------------------------------------
# Handing Network contributor role assignment in case of User managed identity
#-------------------------------------------------------------
resource "azurerm_role_assignment" "userid_clusterRg_network_contributor" {
  count                = var.identity_type == "UserAssigned" ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = var.resource_group_id
}

resource "azurerm_role_assignment" "cluster_readers" {
  for_each             = toset(var.cluster_readers)
  principal_id         = data.azuread_group.cluster_reader_group[each.key].id
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  scope                = azurerm_kubernetes_cluster.aks.id
}

#-------------------------------------------------------------
# ACR Role assignment for Kubelet Identity
#-------------------------------------------------------------

resource "azurerm_role_assignment" "k8s_acr_role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

#-------------------------------------------------------------
# ACR Role assignment for Cluster Service principle
#-------------------------------------------------------------

resource "azurerm_role_assignment" "k8s_service_principle_acr_role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

resource "kubernetes_service_account_v1" "devops_service_accounts" {
  metadata {
    name      = "devops-server"
    namespace = "kube-system"
  }
}

resource "kubernetes_secret_v1" "devops_service_secret" {
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.devops_service_accounts.metadata[0].name
    }
    name      = "devops-server-secret"
    namespace = "kube-system"
  }
  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_binding_v1" "devops_server_role" {
  metadata {
    name = "devops-server-role"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.devops_service_accounts.metadata[0].name
    namespace = kubernetes_service_account_v1.devops_service_accounts.metadata[0].namespace
  }
}

#-----
# End
#-----
