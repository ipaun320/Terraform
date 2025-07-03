variable "training-rg-north" {
  type = string
  default = "rg"
  description = "Name of the rg"
}

variable "vnet_address_space"{
    type = string
    default = "north europe"
    description = "Address space for vnet"
}