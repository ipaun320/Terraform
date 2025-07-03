locals {
  tags = {
    owner = "ipaun"
  }
}
data "azurerm_key_vault_secret" "ssh_key"{
  name = "ssh-public-key"
  key_vault_id = azurerm_key_vault.training.id
}