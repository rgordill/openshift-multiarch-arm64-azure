variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
  sensitive = true
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_resourcegroup" {
  description = "Azure Resource Group where OCP cluster is deployed"
  type = string
}

variable "azure_region" {
  description = "Azure Region where OCP cluster is deployed"
  type = string
}

variable "azure_resource_prefix" {
  description = "OpenShift Cluster Prefix (ex: demo-7t8xn)"
  type = string
}

variable "machineset_instance_type" {
  description = "ARM MachineSet Instance Type (ex. Standard_D4ps_v5)"
  type = string
}

variable "availability_zones" {
  description = "List of the availability zones in which to create the machinesets"
  type = list(string)
}