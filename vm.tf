# Generate an SSH key for secure VM access
resource "tls_private_key" "nova_vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Network interface for the Nova Retail VM
resource "azurerm_network_interface" "nova_vm" {
  name                = "nova-retail-vm-nic"
  location            = azurerm_resource_group.nova.location
  resource_group_name = azurerm_resource_group.nova.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nova_vm_test.id
  }
}


# Temporary public IP for VM outbound connectivity and testing
resource "azurerm_public_ip" "nova_vm_test" {
  name                = "nova-retail-vm-test-pip"
  resource_group_name = azurerm_resource_group.nova.name
  location            = azurerm_resource_group.nova.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project     = "Nova-Retail"
    Environment = "Development"
    Purpose     = "Temporary VM testing"
    ManagedBy   = "Terraform"
  }
}


# Ubuntu Linux virtual machine for the Nova Retail application
resource "azurerm_linux_virtual_machine" "nova_vm" {
  name                = "nova-retail-vm"
  resource_group_name = azurerm_resource_group.nova.name
  location            = azurerm_resource_group.nova.location
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nova_vm.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.nova_vm.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: false
    package_upgrade: false
    runcmd:
      - [ bash, -c, "mkdir -p /opt/nova-retail" ]
  CLOUDINIT
  )

  tags = {
    Project     = "Nova-Retail"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
