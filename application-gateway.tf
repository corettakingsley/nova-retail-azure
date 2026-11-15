resource "azurerm_public_ip" "appgw" {
  name                = "nova-retail-appgw-pip"
  resource_group_name = azurerm_resource_group.nova.name
  location            = azurerm_resource_group.nova.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project     = "Nova-Retail"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_application_gateway" "nova" {
  name                = "nova-retail-appgw"
  resource_group_name = azurerm_resource_group.nova.name
  location            = azurerm_resource_group.nova.location

  sku {
    name     = "Basic"
    tier     = "Basic"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "nova-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "nova-http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "nova-public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name         = "nova-retail-backend-pool"
    ip_addresses = ["10.30.11.4"]
  }

  backend_http_settings {
    name                  = "nova-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "nova-http-listener"
    frontend_ip_configuration_name = "nova-public-frontend"
    frontend_port_name             = "nova-http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "nova-retail-routing-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "nova-http-listener"
    backend_address_pool_name  = "nova-retail-backend-pool"
    backend_http_settings_name = "nova-http-settings"
  }

  tags = {
    Project     = "Nova-Retail"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}