variable "vms" {
  type = map(any)

}

data "azurerm_subnet" "dubnet-data" {
  for_each             = var.vms
  name                 = "frontend-data"
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

resource "azurerm_public_ip" "pip" {
  for_each = var.vms
  name                = each.value.azure_pip_name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "vm-nic" {
  for_each            = var.vms
  name                = each.value.nic_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.dubnet-data[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "front-vm" {
  for_each            = var.vms
  name                = each.value.vm_name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@ssword1234"
  network_interface_ids = [
    azurerm_network_interface.vm-nic[each.key].id,
  ]
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${each.value.vm_name}-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
