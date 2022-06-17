# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.2.0"
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "weightTrackerApp" {
  name     = var.rescorceGroupName
  location = var.loction
}

resource "azurerm_virtual_network" "vnet" {
  name                = "weightTrackerNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.weightTrackerApp.location
  resource_group_name = azurerm_resource_group.weightTrackerApp.name

}

resource "azurerm_subnet" "webSubnet" {
   name                 = "webSubnet"
   resource_group_name  = azurerm_resource_group.weightTrackerApp.name
   virtual_network_name = azurerm_virtual_network.vnet.name
   address_prefixes     = ["10.0.3.0/24"]
 }

 resource "azurerm_subnet" "dbSubnet" {
   name                 = "dbSubnet"
   resource_group_name  = azurerm_resource_group.weightTrackerApp.name
   virtual_network_name = azurerm_virtual_network.vnet.name
   address_prefixes     = ["10.0.4.0/24"]
 }

resource "azurerm_network_security_group" "nsg_db" {
  name                = "securityGroupDB"
  location            = azurerm_resource_group.weightTrackerApp.location
  resource_group_name = azurerm_resource_group.weightTrackerApp.name

  security_rule {
    name                       = "port_5432"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "5432"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny_all"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "nsg_web" {
  name                = "securityGroupWeb"
  location            = azurerm_resource_group.weightTrackerApp.location
  resource_group_name = azurerm_resource_group.weightTrackerApp.name

  security_rule {
    name                       = "SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "port_8080"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "8080"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}


resource "azurerm_public_ip" "lbIp" {
   name                         = "publicIPForLB"
   location                     = azurerm_resource_group.weightTrackerApp.location
   resource_group_name          = azurerm_resource_group.weightTrackerApp.name
   allocation_method            = "Static"
   sku                          = "Standard"
 }

 resource "azurerm_lb" "loadBalncer" {
   name                = "loadBalancer"
   location            = azurerm_resource_group.weightTrackerApp.location
   resource_group_name = azurerm_resource_group.weightTrackerApp.name
   sku                 = "Standard"
   frontend_ip_configuration {
     name                 = "publicIPAddress"
     public_ip_address_id = azurerm_public_ip.lbIp.id
   }

   
 }

resource "azurerm_lb_rule" "lbRule8080" {
  loadbalancer_id                = azurerm_lb.loadBalncer.id
  name                           = "LBRule8080"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "publicIPAddress"
  probe_id                       = azurerm_lb_probe.lbProbe.id
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.load_Balancer_Back.id ]
  disable_outbound_snat          = true
}



resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = 3
  backend_address_pool_id = azurerm_lb_backend_address_pool.load_Balancer_Back.id
  ip_configuration_name   = azurerm_network_interface.vmNicWeb[count.index].ip_configuration[0].name
  network_interface_id    = element(azurerm_network_interface.vmNicWeb.*.id, count.index)
}

resource "azurerm_lb_probe" "lbProbe" {
  name = "tcpProbe"
  loadbalancer_id     = azurerm_lb.loadBalncer.id
  protocol            = "Http"
  port                = 8080
  interval_in_seconds = 5
  number_of_probes    = 2
  request_path        = "/"

}

 resource "azurerm_lb_backend_address_pool" "load_Balancer_Back" {
   loadbalancer_id     = azurerm_lb.loadBalncer.id
   name                = "BackEndAddressPool"
 }

 resource "azurerm_network_interface" "vmNicWeb" {
   count               = 3
   name                = "vmAppNic${count.index}"
   location            = azurerm_resource_group.weightTrackerApp.location
   resource_group_name = azurerm_resource_group.weightTrackerApp.name

   ip_configuration {
     name                          = "vmNicApp"
     subnet_id                     = azurerm_subnet.webSubnet.id
     private_ip_address_allocation = "Dynamic"
   }
 }

  resource "azurerm_network_interface" "vmNicDb" {
   name                = "vmNicDb"
   location            = azurerm_resource_group.weightTrackerApp.location
   resource_group_name = azurerm_resource_group.weightTrackerApp.name

   ip_configuration {
     name                          = "vmDbSub"
     subnet_id                     = azurerm_subnet.dbSubnet.id
     private_ip_address_allocation = "Dynamic"
   }
 }




 




