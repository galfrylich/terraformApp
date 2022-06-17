resource "azurerm_managed_disk" "dbDisk" {
   name                 = "datadiskDb"
   location             = azurerm_resource_group.weightTrackerApp.location
   resource_group_name  = azurerm_resource_group.weightTrackerApp.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = "1023"
 }


 resource "azurerm_availability_set" "avset" {
   name                         = "avset"
   location                     = azurerm_resource_group.weightTrackerApp.location
   resource_group_name          = azurerm_resource_group.weightTrackerApp.name
 }

 resource "azurerm_virtual_machine" "dbVM" {
   count                 = 1
   name                  = "db_server"
   location              = azurerm_resource_group.weightTrackerApp.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.weightTrackerApp.name
   network_interface_ids = [azurerm_network_interface.vmNicDb.id]
   vm_size               = "Standard_DS1_v2"

   

   storage_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts"
    version   = "latest"
   }

   storage_os_disk {
     name              = "dbOsDisk"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   

   storage_data_disk {
     name            = azurerm_managed_disk.dbDisk.name
     managed_disk_id = azurerm_managed_disk.dbDisk.id
     create_option   = "Attach"
     lun             = 1
     disk_size_gb    = azurerm_managed_disk.dbDisk.disk_size_gb
   }

   os_profile {
     computer_name  = "hostname"
     admin_username = var.admin_usernameDb
     admin_password = var.admin_password
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }

 }


resource "azurerm_virtual_machine" "webVms" {
  count                 =  3             
  name                  = "webVm${count.index}"
  location              = azurerm_resource_group.weightTrackerApp.location
  resource_group_name   = azurerm_resource_group.weightTrackerApp.name
  network_interface_ids = [azurerm_network_interface.vmNicWeb[count.index].id]
  vm_size               = "Standard_F2"

  storage_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "webOsDisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  
}


 

