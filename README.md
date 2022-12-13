# Azure 
  Azure Container Apps supports: 
  * Any Linux-based x86-64 (linux/amd64) container image
  * Containers from any public or private container registryx

# Docker File
You can generated this image painfully using the following method, but first remove any EntryPoint commands - otherwise it will not work. 
```bash
docker build --tag weatherapi . 

docker run -it weatherapi              ## to inspect the file system of the image 
```

Once you have created the docker image you can run the following commands
```bash
docker run -p 8080:80 weatherapi  ## to create a container and provide the port mapping
docker push ##Pushing the image to Docker Hub
```

Since we are manually going to utilize the docker image to deploy to Azure. 
We need to push the final image as an amd64 only [Mainly for Apple ARM systems]
```bash
 docker build --platform linux/amd64 --tag weatherapi . 
```

The name of the docker image must match the following regaular expression: 
```bash
a-z0-9]([-a-z0-9]*[a-z0-9])?
```

# Azure CLI
Once you have installed the Azure CLI run the following command to confirm
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
Different types of file 
- Main.tf 
  -  holds terraform configuration code
- Terraform.tfvars 
  - use to hold variables
- Terraform.tfstate
  - used to map plan resources to running resources
  

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

## Azure CLI and Terraform 
As of right now we are manually loging into Azure via the CLI, then applying terraform to build our plan. [To automate this part, we will allow Terraform to login to our Azure subscription via a Service Principal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret). 

A Service Principal is a registered application on Azure Active Directory. 
At the registered applicaiton level, we will generate a client secret. At the subscription level, we will grant this application Contributor level access. 

Need to set these Envrionment Variables
ARM_SUBSCRIPTION_ID 
ARM_CLIENT_SECRET
ARM_CLIENT_ID 
ARM_TENANT_ID

Terraform will utilize these environment variables information to communticated with Azure Active Directory and use the Service Principal for authenticate and authorizated the Terraform plan. 

[For Mac]

You need to edit or create ~/.bash_profile 
Add to file 
  export environmentvariable=environmentvalue
Save the file 
Then you reload the file via **source ~/.bash_profile**


[For Windows]



Now you can run **terraform plan** only and you simply get the plan outline. 


# Azure DevOps Pipeline 
Create a [new project](https://dev.azure.com/) under project settings. 

First go to Project Settings > click on Service connections
Create a **Docker Registry** service connection
* provider you username and password and verify 
Create a **Azure Resoruce Manager** service connection
* follow the same process 

Next, go to Pipeline and create a new pipeline. 
Select where your remote repo provider for example Github
and then if you are already signed in then you will the repo for this project. Under the configure select Docker and add a task selct docker to build and push. 


Tagging Docker images 
<DockerUserId> / <ImageName>:Version 

```docker 
# Docker

# Build a Docker image
# https://docs.microsoft.com/azure/devops/pipelines/languages/docker

trigger:
- main

resources:
- repo: self

variables:
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: Build image
  jobs:
  - job: Build
    displayName: Build
    pool:
      vmImage: ubuntu-latest
    steps:
    - task: Docker@2
      inputs:
        containerRegistry: 'Docker Hub (luisenalvar)'
        repository: 'luisenalvar/aztfweatherapi'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: |
          $(tag)
```
Now that we have establish a devops pipeline with a single task to build and push a docker image to docker hub. We are half way there. We need to add the terraform part. 

# Add Terraform to DevOps Pipeline
Next under the pipeline go to > Library and add a 
variable group and add all of the environemnt variable for terraform. 

```bash
ARM_SUBSCRIPTION_ID 
ARM_CLIENT_SECRET
ARM_CLIENT_ID 
ARM_TENANT_ID
```

When we run terraform apply the .tfstate will save our current state of the build. So, we will need to store this file somewhere in Azure. 

First, we will need to manually create a resource group for this particular part. 
Next, the main object we will use is a **Storage Account - blob, file, table, and queue** and add to our new resoruce group. 

Once the storage account is deploy, then we will add a new container. I will call it tfstatefile and have the mode set to private. 
on the main.tf we will make the following additions

```tf
terraform {
  backend "azurerm" {
    resource_group_name = "tf_api_blobstorage"
    storage_account_name = "aztfweatherblobstorage"
    container_name = "tfstatefile"
    key = "terraform.tfstate"
  }
}
```

Now is time to add Terraform to the DevOps pipeline 

```
# - stage: Deploy  
#   displayName: 'Azure Provision of Resources ...'
#   dependsOn: Build
#   jobs:
#   - job: AppDeployment 
#     displayName: 'Create a App Container Instance'
#     pool:
#       vmImage: ubuntu-latest
#     variables:
#     - group: TerraformServicePrincipalEnvVars
#     steps:
#     - script: |
#         set -e
#         terraform init -input=false
#         terraform apply -input=false -auto-approve
#       name: Terraform 
#       displayName: 'Running Terraform  ...'
#       env:
#         ARM_CLIENT_ID: $(ARM_CLIENT_ID)
#         ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
#         ARM_TENANT_ID: $(ARM_TENANT_ID)
#         ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
#         TF_VAR_imagebuild: $(tag)
```

 TF_VAR_imagebuild: $(tag) <--- from Azure pipeline will pass down this value to the main.tf file via variable "imagebuild"

variable "imagebuild" {
  type=string
  description="Latest Image Build"
}

resource "azurerm_container_group" "tfcg_api_test" {
    ...
    image       = "luisenalvar/aztfweatherapi:${var.imagebuild}"
    ...
}

Homework: 
* will running terraform at the command line work now 
* the name of iamge name is hard-coded in 2 places