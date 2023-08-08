terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_group="app-grp"
  location="North Europe"
}

resource "azurerm_resource_group" "app_grp"{
  name= var.name_env
  location=local.location
}

resource "azurerm_virtual_network" "app_network" {
  name                = "${var.app_network_var}${var.name_env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]  
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "${var.SubnetA_var}${var.name_env}"
  resource_group_name  = azurerm_resource_group.app_grp.name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

resource "azurerm_network_interface" "app_interface1" {
  name                = "${var.app_interface1_var}${var.name_env}"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_subnet.SubnetA
  ]
}

resource "azurerm_network_interface" "app_interface2" {
  name                = "${var.app_interface2_var}${var.name_env}"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_subnet.SubnetA
  ]
}

resource "azurerm_windows_virtual_machine" "app_vm1" {
  name                = "appvm1${var.name_env}"
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  size                = "Standard_D2s_v3"
  admin_username      = "demousr"
  admin_password      = "Azure@123"
  availability_set_id = azurerm_availability_set.app_set.id
  network_interface_ids = [
    azurerm_network_interface.app_interface1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface1,
    azurerm_availability_set.app_set
  ]
}

resource "azurerm_windows_virtual_machine" "app_vm2" {
  name                = "appvm2${var.name_env}"
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  size                = "Standard_D2s_v3"
  admin_username      = "demousr"
  admin_password      = "Azure@123"
  availability_set_id = azurerm_availability_set.app_set.id
  network_interface_ids = [
    azurerm_network_interface.app_interface2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface2,
    azurerm_availability_set.app_set
  ]
}

resource "azurerm_availability_set" "app_set" {
  name                = "${var.app_set_var}${var.name_env}"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  platform_fault_domain_count = 3
  platform_update_domain_count = 3  
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_storage_account" "appstore" {
  name                     = "${var.appstore_var}${var.name_env}"
  resource_group_name      = azurerm_resource_group.app_grp.name
  location                 = azurerm_resource_group.app_grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_storage_container" "data" {
  name                  = "${var.data_var}${var.name_env}"
  storage_account_name  = "${var.appstore_var}${var.name_env}"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.appstore
    ]
}

resource "azurerm_storage_blob" "IIS_config" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = "${var.appstore_var}${var.name_env}"
  storage_container_name = "${var.data_var}${var.name_env}"
  type                   = "Block"
  source                 = "IIS_Config.ps1"
   depends_on=[azurerm_storage_container.data]
}

resource "azurerm_virtual_machine_extension" "vm_extension1" {
  name                 = "${var.vm_extension1_var}${var.name_env}"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.IIS_config
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.appstore.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "vm_extension2" {
  name                 = "${var.vm_extension1_var}${var.name_env}"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.IIS_config
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.appstore.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS
}


resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.app_nsg_var}${var.name_env}"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
  depends_on = [
    azurerm_network_security_group.app_nsg
  ]
}

resource "azurerm_public_ip" "load_ip" {
  name                = "${var.load_ip_var}${var.name_env}"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  allocation_method   = "Static"
  sku="Standard"
}

resource "azurerm_lb" "app_balancer" {
  name                = "${var.app_balancer_var}${var.name_env}"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  sku="Standard"
  sku_tier = "Regional"
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.load_ip.id
  }

  depends_on=[
    azurerm_public_ip.load_ip
  ]
}

resource "azurerm_lb_backend_address_pool" "PoolA" {
  loadbalancer_id = azurerm_lb.app_balancer.id
  name            = "${var.PoolA_var}${var.name_env}"
  depends_on=[
    azurerm_lb.app_balancer
  ]
}

resource "azurerm_lb_backend_address_pool_address" "appvm1_address" {
  name                    = "${var.appvm1_address_var}${var.name_env}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.PoolA.id
  virtual_network_id      = azurerm_virtual_network.app_network.id
  ip_address              = azurerm_network_interface.app_interface1.private_ip_address
  depends_on=[
    azurerm_lb_backend_address_pool.PoolA
  ]
}

resource "azurerm_lb_backend_address_pool_address" "appvm2_address" {
  name                    = "${var.appvm2_address_var}${var.name_env}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.PoolA.id
  virtual_network_id      = azurerm_virtual_network.app_network.id
  ip_address              = azurerm_network_interface.app_interface2.private_ip_address
  depends_on=[
    azurerm_lb_backend_address_pool.PoolA
  ]
}

resource "azurerm_lb_probe" "ProbeA" {
  resource_group_name = azurerm_resource_group.app_grp.name
  loadbalancer_id     = azurerm_lb.app_balancer.id
  name                = "${var.ProbeA_var}${var.name_env}"
  port                = 80
  protocol            =  "Tcp"
  depends_on=[
    azurerm_lb.app_balancer
  ]
}

resource "azurerm_lb_rule" "RuleA" {
  resource_group_name            = azurerm_resource_group.app_grp.name
  loadbalancer_id                = azurerm_lb.app_balancer.id
  name                           = "${var.RuleA_var}${var.name_env}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.PoolA.id ]
  depends_on=[
    azurerm_lb.app_balancer
  ]
}
