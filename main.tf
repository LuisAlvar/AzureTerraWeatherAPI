terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name = "tf_api_blobstorage"
    storage_account_name = "aztfweatherblobstorage"
    container_name = "tfstatefile"
    key = "terraform.tfstate"
  }
}

variable "imagebuild" {
  type=string
  description="Latest Image Build"
}

resource "azurerm_resource_group" "tf_api_test" {
  name = "tfmainapirg"
  location = "West US 2"
}

resource "azurerm_container_group" "tfcg_api_test" {
  name                = "weatherapi" 
  location            = azurerm_resource_group.tf_api_test.location
  resource_group_name = azurerm_resource_group.tf_api_test.name

  ip_address_type     = "Public"
  dns_name_label      = "archtechorgwa" 
  os_type             = "Linux"

  container {
    name        = "weatherapi"
    image       = "luisenalvar/aztfweatherapi:${var.imagebuild}"
    cpu         = "1.0"
    memory      = "1.0"
    ports {
      port      = 80
      protocol  = "TCP"
    }
  } 
}