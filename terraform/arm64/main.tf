terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azapi" {
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

data "azurerm_resource_group" "cluster_rg" {
  name = var.azure_resourcegroup
}

data "azurerm_storage_account" "cluster_sa" {
  name                = local.storage_account_name
  resource_group_name = local.azure_resourcegroup
}

data "azurerm_storage_container" "cluster_sc" {
  name                 = "vhd"
  storage_account_name = data.azurerm_storage_account.cluster_sa.name
}

resource "azurerm_storage_blob" "rhcos_aarch64_vhd" {
  name                   = local.blob_name
  storage_account_name   = data.azurerm_storage_account.cluster_sa.name
  storage_container_name = data.azurerm_storage_container.cluster_sc.name
  type                   = "Page"
  source_uri             = local.coreos_bootimage
}

resource "azurerm_shared_image" "rhcos_aarch64_v1" {
  name                = "${var.azure_resource_prefix}-aarch64"
  gallery_name        = "gallery_${local.azure_resource_prefix_underscore}"
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  location            = data.azurerm_resource_group.cluster_rg.location
  os_type             = "Linux"
  architecture        = "Arm64"
  hyper_v_generation  = "V1"

  identifier {
    publisher = "RedHat"
    offer     = "rhcos-aarch64"
    sku       = "basic"
  }

  tags = local.tags

  # See https://github.com/hashicorp/terraform-provider-azurerm/issues/13776
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_shared_image_version" "rhcos_aarch64_v1_latest" {
  name                = local.image_version
  gallery_name        = azurerm_shared_image.rhcos_aarch64_v1.gallery_name
  image_name          = azurerm_shared_image.rhcos_aarch64_v1.name
  resource_group_name = azurerm_shared_image.rhcos_aarch64_v1.resource_group_name
  location            = azurerm_shared_image.rhcos_aarch64_v1.location
  blob_uri            = azurerm_storage_blob.rhcos_aarch64_vhd.url
  storage_account_id  = data.azurerm_storage_account.cluster_sa.id

  target_region {
    name                   = azurerm_shared_image.rhcos_aarch64_v1.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

resource "azurerm_shared_image" "rhcos_aarch64_v2" {
  name                = "${var.azure_resource_prefix}-aarch64-gen2"
  gallery_name        = "gallery_${local.azure_resource_prefix_underscore}"
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  location            = data.azurerm_resource_group.cluster_rg.location
  os_type             = "Linux"
  architecture        = "Arm64"
  hyper_v_generation  = "V2"

  identifier {
    publisher = "RedHat-gen2"
    offer     = "rhcos-aarch64-gen2"
    sku       = "gen2"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_shared_image_version" "rhcos_aarch64_v2_latest" {
  name                = local.image_version
  gallery_name        = azurerm_shared_image.rhcos_aarch64_v2.gallery_name
  image_name          = azurerm_shared_image.rhcos_aarch64_v2.name
  resource_group_name = azurerm_shared_image.rhcos_aarch64_v2.resource_group_name
  location            = azurerm_shared_image.rhcos_aarch64_v2.location
  blob_uri            = azurerm_storage_blob.rhcos_aarch64_vhd.url
  storage_account_id  = data.azurerm_storage_account.cluster_sa.id

  target_region {
    name                   = azurerm_shared_image.rhcos_aarch64_v2.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


data "kubernetes_resource" "machineset_x86" {
  api_version = "machine.openshift.io/v1beta1"
  kind        = "MachineSet"

  metadata {
    name      = "${var.azure_resource_prefix}-worker-aarch64-${var.azure_region}1"
    namespace = "openshift-machine-api"
  }
}

resource "kubernetes_manifest" "machineset_aarch64" {
  count = local.instance_count

  manifest = {
    "apiVersion" : "machine.openshift.io/v1beta1"
    "kind" : "MachineSet"
    "metadata" : {
      "labels" : {
        "machine.openshift.io/cluster-api-cluster" : "${var.azure_resource_prefix}"
        "machine.openshift.io/cluster-api-machine-role" : "worker"
        "machine.openshift.io/cluster-api-machine-type" : "worker"
      }
      "name" : "${var.azure_resource_prefix}-worker-aarch64-${var.azure_region}${count.index + 1}"
      "namespace" : "openshift-machine-api"
    }
    "spec" : {
      "replicas" : 0
      "selector" : {
        "matchLabels" : {
          "machine.openshift.io/cluster-api-cluster" : "${var.azure_resource_prefix}",
          "machine.openshift.io/cluster-api-machineset" : "${var.azure_resource_prefix}-worker-aarch64-${var.azure_region}${count.index + 1}"
        }
      }
      "template" : {
        "metadata" : {
          "labels" : {
            "machine.openshift.io/cluster-api-cluster" : "${var.azure_resource_prefix}"
            "machine.openshift.io/cluster-api-machine-role" : "worker"
            "machine.openshift.io/cluster-api-machine-type" : "worker"
            "machine.openshift.io/cluster-api-machineset" : "${var.azure_resource_prefix}-worker-aarch64-${var.azure_region}${count.index + 1}"
          }
        }
        "spec" : {
          "providerSpec" : {
            "value" : {
              "acceleratedNetworking" : true
              "apiVersion" : "machine.openshift.io/v1beta1"
              "credentialsSecret" : {
                "name" : "azure-cloud-credentials"
                "namespace" : "openshift-machine-api"
              }
              "diagnostics" : {}
              "image" : {
                "offer" : ""
                "publisher" : ""
                "resourceID" : "${local.image_resource_id}/versions/latest",
                "sku" : ""
                "version" : ""
              }
              "kind" : "AzureMachineProviderSpec"
              "location" : "${var.azure_region}"
              "managedIdentity" : "${var.azure_resource_prefix}-identity"
              "metadata" : {
                "creationTimestamp" : null
              },
              "networkResourceGroup" : "${data.kubernetes_resource.machineset_x86.object.spec.template.spec.providerSpec.value.networkResourceGroup}"
              "osDisk" : {
                "diskSettings" : {}
                "diskSizeGB" : 128
                "managedDisk" : {
                  "securityProfile" : {
                    "diskEncryptionSet" : {}
                  }
                  "storageAccountType" : "Premium_LRS"
                }
                "osType" : "Linux"
              }
              "publicIP" : false,
              "publicLoadBalancer" : "${var.azure_resource_prefix}"
              "resourceGroup" : "${var.azure_resource_prefix}-rg"
              "securityProfile" : {
                "settings" : {}
              }
              "subnet" : "${data.kubernetes_resource.machineset_x86.object.spec.template.spec.providerSpec.value.subnet}"
              "userDataSecret" : {
                "name" : "worker-user-data"
              },
              "vmSize" : "Standard_D4ps_v5"
              "vnet" : "${data.kubernetes_resource.machineset_x86.object.spec.template.spec.providerSpec.value.vnet}"
              # "vnet" : "${var.azure_resource_prefix}-vnet "
              "zone" : "${var.availability_zones[count.index]}"
            }
          }
        }
      }
    }
  }
}

# Searching data for locals
data "kubernetes_config_map" "coreos_bootimages" {
  metadata {
    name      = "coreos-bootimages"
    namespace = "openshift-machine-config-operator"
  }
}

data "azapi_resource_list" "storage_account_list" {
  type                   = "Microsoft.Storage/storageAccounts@2024-01-01"
  parent_id              = "/subscriptions/${var.azure_subscription_id}"
  response_export_values = ["*"]
}

locals {
  azure_resourcegroup              = var.azure_resourcegroup
  azure_resource_prefix_underscore = replace(var.azure_resource_prefix, "-", "_")

  tags = { "kubernetes.io_cluster.${var.azure_resource_prefix}" : "owned" }

  coreos_bootimage = jsondecode(data.kubernetes_config_map.coreos_bootimages.data.stream).architectures.aarch64.rhel-coreos-extensions.azure-disk.url

  image_version = substr(jsondecode(data.kubernetes_config_map.coreos_bootimages.data.stream).architectures.aarch64.rhel-coreos-extensions.azure-disk.release, 0, 14)
  blob_name     = "rhcos${local.random_prefix}.aarch64.vhd"

  storage_account_list = jsondecode(data.azapi_resource_list.storage_account_list.output).value
  filtered_storage_accounts = [
    for obj in local.storage_account_list : obj
    if lookup(obj.tags, "kubernetes.io_cluster.${var.azure_resource_prefix}", "") == "owned" && startswith(obj.name, "cluster")
  ]

  random_prefix        = substr(element(local.filtered_storage_accounts, 0).name, 7, -1)
  storage_account_name = "cluster${local.random_prefix}"

  image_resource_id = "/${join("/", slice(split("/", azurerm_shared_image.rhcos_aarch64_v2.id), 3, length(split("/", azurerm_shared_image.rhcos_aarch64_v2.id))))}"

  instance_count = length(var.availability_zones)
}

