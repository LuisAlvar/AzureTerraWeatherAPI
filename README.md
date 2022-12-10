# Azure 
  Azure Container Apps supports: 
  * Any Linux-based x86-64 (linux/amd64) container image
  * Containers from any public or private container registryx

# Docker File
You can generated this image painfully using the following method, but first remove any EntryPoint commands - otherwise it will not work. 
```bash
docker build--tag weatherapi . 

docker run -it weatherapi              ## to inspect the file system of the image 
```

Once you have created the docker image you can run the following commands
```bash
docker run -p 8080:80 weatherapi  ## to create a container and provide the port mapping
docker push ##Pushing the image to Docker Hub
```

Since we are going to utilize the docker image to deploy to Azure. 
We need to push the final image as an amd64 only [Mainly for Apple ARM systems]
```bash
 docker build --platform linux/amd64 --tag weatherapi . 
```

The name of the docker image must match the following regaular expression: 
```bash
a-z0-9]([-a-z0-9]*[a-z0-9])?
```

# Azure CLI
On you have installed the Azure CLi run the following command to confirm
```bash 
az --version
```
You should be a display of information but the most important information is that it says. "Your CLI is up-to-date"

Next, you will need to login into azure via the command line interface. 
```bash 
az login
```

If you have more than one tenant per subscription 
```bash 
az account set --subscription "35akss-subscription-id"
```

```bash
az upgrade
az config set auto-upgrade.enable=yes
```

# Terraform 
Once sign-in to the Azure CLI, we can start creating the main terraform file.
```tf
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
```

You can run the following comamnd to intialize terraform 
```tf
terraform init
```

Next objective is to create a Resource Group via Terraform

```tf
resource "azurerm_resource_group" "tf_api_test" {
  name = "tfmainapirg"
  location = "West US 2"
}
```

where 
* **azurerm_resource_group** - is a keyword within the terraform library 
* **tf_test** - is the naming of this resource or object within the file.

You can use object-oriented sytax to access properties outside of the declaration block. 
You can do the following: 
```tf
azurerm_resource_group.tf_api_test.location
azurerm_resource_group.tf_api_test.name
```

Next objective is to create an Azure Container Instances via Terraform 
```tf
resource "azurerm_container_group" "tfcg_api_test" {
  name                = "weatherapi" 
  location            = azurerm_resource_group.tf_api_test.location
  resource_group_name = azurerm_resource_group.tf_api_test.name

  ip_address_type     = "Public"
  dns_name_label      = "archtechorgwa" 
  os_type             = "Linux"

  container {
    name        = "weatherapi"
    image       = "luisenalvar/azureterraform-weatherapi"
    cpu         = "1.0"
    memory      = "1.0"
    ports {
      port      = 80
      protocol  = "TCP"
    }
  } 
}
```

At this point, we can tell terraform to provide a report on what its going to process. 
By running **terraform plan**

```bash 
Terraform will perform the following actions:

  # azurerm_container_group.tfcg_api_test will be created
  + resource "azurerm_container_group" "tfcg_api_test" {
      + dns_name_label      = "luisenalvar_azureterraform_weatherapi"
      + exposed_port        = (known after apply)
      + fqdn                = (known after apply)
      + id                  = (known after apply)
      + ip_address          = (known after apply)
      + ip_address_type     = "public"
      + location            = "westus"
      + name                = "azure"
      + os_type             = "Linux"
      + resource_group_name = "tfmainapirg"
      + restart_policy      = "Always"

      + container {
          + commands = (known after apply)
          + cpu      = 1
          + image    = "luisenalvar/azureterraform_weatherapi"
          + memory   = 1
          + name     = "azureterraform_weatherapi"

          + ports {
              + port     = 80
              + protocol = "TCP"
            }
        }
    }

  # azurerm_resource_group.tf_api_test will be created
  + resource "azurerm_resource_group" "tf_api_test" {
      + id       = (known after apply)
      + location = "westus"
      + name     = "tfmainapirg"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

```