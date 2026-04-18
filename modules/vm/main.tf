locals {
  vm_name = "vm-${var.project}-${var.environment}"
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-${local.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-${local.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.vm.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

# Upload bootstrap.ps1 to a storage blob and run it via Custom Script Extension
resource "azurerm_storage_blob" "bootstrap" {
  name                   = "bootstrap-${var.environment}.ps1"
  storage_account_name   = var.bootstrap_storage_account
  storage_container_name = var.bootstrap_storage_container
  type                   = "Block"
  source                 = "${path.module}/bootstrap.ps1"
}

data "azurerm_storage_account_sas" "bootstrap" {
  connection_string = var.bootstrap_storage_connection_string
  https_only        = true
  signed_version    = "2020-12-06"

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "2h")

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                 = "bootstrap"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris         = ["${azurerm_storage_blob.bootstrap.url}${data.azurerm_storage_account_sas.bootstrap.sas}"]
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File bootstrap-${var.environment}.ps1"
  })

  tags = var.tags

  depends_on = [azurerm_windows_virtual_machine.vm]
}
