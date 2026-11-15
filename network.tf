
# --------------------------------------------------
# Resource Group
# --------------------------------------------------

resource "azurerm_resource_group" "nova" {
  name     = "nova-retail-rg"
  location = "South Africa North"
}

# --------------------------------------------------
# Virtual Network
# --------------------------------------------------

resource "azurerm_virtual_network" "nova" {
  name                = "nova-retail-vnet"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.nova.location
  resource_group_name = azurerm_resource_group.nova.name
}

# --------------------------------------------------
# Subnets
# --------------------------------------------------

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw-public"
  resource_group_name  = azurerm_resource_group.nova.name
  virtual_network_name = azurerm_virtual_network.nova.name
  address_prefixes     = ["10.30.1.0/24"]

  default_outbound_access_enabled               = false
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app-private"
  resource_group_name  = azurerm_resource_group.nova.name
  virtual_network_name = azurerm_virtual_network.nova.name
  address_prefixes     = ["10.30.11.0/24"]

  default_outbound_access_enabled               = false
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet" "db" {
  name                 = "snet-db-private"
  resource_group_name  = azurerm_resource_group.nova.name
  virtual_network_name = azurerm_virtual_network.nova.name
  address_prefixes     = ["10.30.21.0/24"]

  default_outbound_access_enabled               = false
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

# --------------------------------------------------
# Network Security Groups
# --------------------------------------------------

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-private"
  location            = azurerm_resource_group.nova.location
  resource_group_name = azurerm_resource_group.nova.name
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-db-private"
  location            = azurerm_resource_group.nova.location
  resource_group_name = azurerm_resource_group.nova.name
}

# --------------------------------------------------
# Application HTTP Security Rule
# --------------------------------------------------

resource "azurerm_network_security_rule" "app_http" {
  name                       = "Allow-AppGateway-HTTP"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "10.30.1.0/24"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.nova.name
  network_security_group_name = azurerm_network_security_group.app.name
}

# --------------------------------------------------
# Database MySQL Security Rule
# --------------------------------------------------

resource "azurerm_network_security_rule" "db_mysql" {
  name                       = "Allow-App-MySQL"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3306"
  source_address_prefix      = "10.30.11.0/24"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.nova.name
  network_security_group_name = azurerm_network_security_group.db.name
}

# --------------------------------------------------
# Subnet - NSG Associations
# --------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}
