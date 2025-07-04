# Create a resource group
resource "azurerm_resource_group" "training" {
  name     = var.training-rg-north
  location = "North Europe"
  tags = local.tags
}

resource "azurerm_network_security_group" "vm1" {
  name                = "vm1-security-group"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
    security_rule {
    name                       = "inbound1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "128.77.15.12"
    destination_address_prefix = "*"
  }
  security_rule {
  name                       = "Allow-SSH-Probe-From-LB"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "AzureLoadBalancer"
  destination_address_prefix = "*"
}
  tags = local.tags
}

resource "azurerm_network_security_group" "vm2" {
  name                = "vm2-security-group"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
    security_rule {
    name                       = "inbound1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "128.77.15.12"
    destination_address_prefix = "*"
  }
  security_rule {
  name                       = "Allow-SSH-Probe-From-LB"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "AzureLoadBalancer"
  destination_address_prefix = "*"
}
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "sub1" {
  subnet_id                 = azurerm_subnet.sub1.id
  network_security_group_id = azurerm_network_security_group.vm1.id
}

resource "azurerm_subnet_network_security_group_association" "sub2" {
  subnet_id                 = azurerm_subnet.sub2.id
  network_security_group_id = azurerm_network_security_group.vm2.id
}

resource "azurerm_virtual_network" "training" {
  name                = "training-vnet"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  address_space       = [var.vnet_address_space]
  tags = local.tags
}

resource "azurerm_subnet" "sub1" {
  name                 = "app-subnet1"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "sub2" {
  name                 = "app-subnet2"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.0.0/29"]
}

resource "azurerm_subnet" "sub3" {
  name                 = "web-app-subnet"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "training-vm1" {
  name                = "app-nic1"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.sub1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my-vm-public1.id
 
  }
}

resource "azurerm_network_interface" "training-vm2" {
  name                = "app-nic2"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "testconfiguration2"
    subnet_id                     = azurerm_subnet.sub2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my-vm-public2.id
 
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "app-vm1"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training-vm1.id]
  size                  = "Standard_B1s"
  admin_username        = "ipaun"

  admin_ssh_key {
    username   = "ipaun"
    public_key = data.azurerm_key_vault_secret.ssh_key.value
  }

  disable_password_authentication = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "myosdisk1"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "app-vm2"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training-vm2.id]
  size                  = "Standard_B1s"
  admin_username        = "ipaun"

  admin_ssh_key {
    username   = "ipaun"
    public_key = data.azurerm_key_vault_secret.ssh_key.value
  }

  disable_password_authentication = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "myosdisk2"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
}

resource "azurerm_public_ip" "my-vm-public1" {
  name                = "my-vm-public1"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  allocation_method   = "Static" # or "Static" if you want fixed IP
  # sku                 = "Basic"   # use "Standard" for production-grade
}

resource "azurerm_public_ip" "my-vm-public2" {
  name                = "my-vm-public2"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  allocation_method   = "Static" # or "Static" if you want fixed IP
  # sku                 = "Basic"   # use "Standard" for production-grade
}

resource "azurerm_public_ip" "my-lb-public" {
  name                = "my-lb-public"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  allocation_method   = "Static" # or "Static" if you want fixed IP
  # sku                 = "Basic"   # use "Standard" for production-grade
}

resource "azurerm_lb" "main" {
  name                = "my-loadbalancer"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  frontend_ip_configuration {
    name                 = "my-lb-public"
    public_ip_address_id = azurerm_public_ip.my-lb-public.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend" {
  name                = "vm-backend-pool"
  loadbalancer_id     = azurerm_lb.main.id
}

# resource "azurerm_lb_probe" "http" {
#   name                = "http-probe"
#   loadbalancer_id     = azurerm_lb.main.id
#   protocol            = "Tcp"
#   port                = 80
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "http" {
#   name                           = "http-rule"
#   loadbalancer_id                = azurerm_lb.main.id
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = 80
#   frontend_ip_configuration_name = "my-lb-public"
#   probe_id                       = azurerm_lb_probe.http.id
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.azurerm_lb_backend_address_pool.id]
# }

resource "azurerm_lb_rule" "ssh" {
  name                           = "ssh-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "my-lb-public"
  probe_id                       = azurerm_lb_probe.ssh.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
}

resource "azurerm_lb_probe" "ssh" {
  name                = "ssh-probe"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface_backend_address_pool_association" "vm1_assoc" {
  network_interface_id    = azurerm_network_interface.training-vm1.id
  ip_configuration_name   = "testconfiguration1" # match the NIC ip_configuration name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm2_assoc" {
  network_interface_id    = azurerm_network_interface.training-vm2.id
  ip_configuration_name   = "testconfiguration2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
}

resource "azurerm_key_vault" "training" {
  name                        = "my-training-kv"
  location                    = azurerm_resource_group.training.location
  resource_group_name         = azurerm_resource_group.training.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  tags = local.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "training" {
  key_vault_id = azurerm_key_vault.training.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set"]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  value        = file("~/.ssh/id_rsa.pub")
  key_vault_id = azurerm_key_vault.training.id
}

resource "azurerm_service_plan" "app-service-plan" {
  name                = "my-asp"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "linux-web-app" {
  name                = "linux-training-web-app"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_service_plan.app-service-plan.location
  service_plan_id     = azurerm_service_plan.app-service-plan.id

  site_config {
    ip_restriction {
      ip_address = "128.77.15.12/32"
      name       = "AllowMyIP"
      priority   = 100
      action     = "Allow"
    }
  }
}

resource "azurerm_private_endpoint" "my-private-endpoint" {
  name                = "my-training-endpoint"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  subnet_id           = azurerm_subnet.sub3.id

  private_service_connection {
    name                           = "my-training-privateserviceconnection"
    private_connection_resource_id = azurerm_linux_web_app.linux-web-app.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}

# resource "azurerm_container_group" "my-training-container" {
#   name                = "my-training-container"
#   location            = azurerm_resource_group.training.location
#   resource_group_name = azurerm_resource_group.training.name
#   ip_address_type     = "Public"
#   dns_name_label      = "aci-label"
#   os_type             = "Linux"

#   container {
#     name   = "hello-world-training"
#     image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
#     cpu    = "0.5"
#     memory = "1.5"

#     ports {
#       port     = 443
#       protocol = "TCP"
#     }
#   }
# }

resource "azurerm_container_registry" "acr" {
  name                = "trainingContainerRegistry927"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  sku                 = "Premium"
  admin_enabled       = false
}
