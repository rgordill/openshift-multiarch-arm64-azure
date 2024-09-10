terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

locals {
  azure_client_id       = data.kubernetes_secret.azure_cloud_credentials.data.azure_client_id
  azure_client_secret   = data.kubernetes_secret.azure_cloud_credentials.data.azure_client_secret
  azure_subscription_id = data.kubernetes_secret.azure_cloud_credentials.data.azure_subscription_id
  azure_tenant_id       = data.kubernetes_secret.azure_cloud_credentials.data.azure_tenant_id

  azure_region          = data.kubernetes_secret.azure_cloud_credentials.data.azure_region
  azure_resourcegroup   = data.kubernetes_secret.azure_cloud_credentials.data.azure_resourcegroup
  azure_resource_prefix = data.kubernetes_secret.azure_cloud_credentials.data.azure_resource_prefix
}

provider "azurerm" {
  subscription_id = local.azure_subscription_id
  client_id       = local.azure_client_id
  client_secret   = local.azure_client_secret
  tenant_id       = local.azure_tenant_id
  features {}
}


provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_config_context
  
}

data "kubernetes_secret" "azure_cloud_credentials" {
  metadata {
    name      = "azure-cloud-credentials"
    namespace = "openshift-machine-api"
  }
}



module arm64 {
  source = "./arm64"
  
  azure_client_id          = local.azure_client_id
  azure_client_secret      = local.azure_client_secret
  azure_subscription_id    = local.azure_subscription_id
  azure_tenant_id          = local.azure_tenant_id

  azure_region             = local.azure_region
  azure_resourcegroup      = local.azure_resourcegroup
  azure_resource_prefix    = local.azure_resource_prefix

  machineset_instance_type = var.machineset_instance_type
  availability_zones       = var.availability_zones 
}

