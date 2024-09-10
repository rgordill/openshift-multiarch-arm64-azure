variable "kubernetes_config_path" {
  description = "kubeconfig path for OpenShift"
  type = string
}

variable "kubernetes_config_context" {
  description = "Kubernetes config contex in kubeconfig file"
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