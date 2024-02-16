output "object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}


output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}