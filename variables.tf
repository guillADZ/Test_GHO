variable "name_env" {
  type = string
}

variable "app_network_var" {
  description = "app_network environment is"
  default     = "app_network_"
}

variable "SubnetA_var" {
  description = "SubnetA environment is"
  default     = "SubnetA_"
}

variable "app_interface1_var" {
  description = "app-interface1 environment is"
  default     = "app-interface1_"
}

variable "app_interface2_var" {
  description = "app-interface2 environment is"
  default     = "app-interface2_"
}

variable "app_set_var" {
  description = "app-set environment is"
  default     = "app-set_"
}

variable "vm_extension1_var" {
  description = "appvm-extension environment is"
  default     = "appvm-extension"
}

variable "app_nsg_var" {
  description = "app-nsg environment is"
  default     = "app-nsg_"
}

variable "app_balancer_var" {
  description = "app-balancer environment is"
  default     = "app-balancer_"
}

variable "PoolA_var" {
  description = "PoolA environment is"
  default     = "PoolA_"
}

variable "appvm1_address_var" {
  description = "appvm1 environment is"
  default     = "appvm1_"
}

variable "appvm2_address_var" {
  description = "appvm2 environment is"
  default     = "appvm2_"
}

variable "ProbeA_var" {
  description = "probeA environment is"
  default     = "probeA_"
}

variable "RuleA_var" {
  description = "RuleA environment is"
  default     = "RuleA_"
}
