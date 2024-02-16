rg_location = "eastus"
region      = "use"
project     = "test"
createdBy   = "vishnu"


resource_group_name = "vishnu_ACR"
location = "East US"



aks_workspace_details = {
  "aksomsagent-laws" = {"sku": "PerGB2018", "retention_days":"30" }
}

aks_name = "mycluster"


systempool = {
  "size":"standard_d2s_v5",
   "min":"1", 
   "max":"5"  
}

nodepool = {
  "devnodepool" = {"vm_size":"standard_d2s_v5", "min":"1", "max":"5"}
}

acr_name = "useACR"

cluster_admins = ["devops"] 

cluster_writers =["Dev"] 

cluster_readers =["DevOps1"] 

acr_pull_groups = [ "test1","test3","test3" ]

acr_push_groups = [ "test1","test3","test3"  ]

acr_delete_groups = ["test2" ]

acr_pull_applications = [ "aspwebapp-aks" ]





