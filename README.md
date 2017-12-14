# azure-testbed

Investigations into Azure

## Service Fabric cluster

In the `service-fabric` folder are a set of scripts and JSON templates for creating a Service Fabric cluster.

### Prerequisites

- Powershell 5
- Azure Resource Manager module (`Install-Module AzureRM`)

### Log in

Log into your Azure account

    Login-AzureRmAccount

### Create the key vault

`cd` into the scripts directory

#### Update the Key Vault cluster JSON template file

- Open the Azure portal
- Do a search for *Active Directory*
- Find the details for your user and copy the `ObjectId` into the clipboard
- Open `az-keyvault.json` in a text editor
- Find the `admin_user_id` parameter and update its default value with the contents of the clipboard

#### Deploy the key vault

    .\template-deploy.ps1 <subscriptionId> <keyVaultResourceGroupName> westeurope ..\az-keyvault.json dev

- `<keyVaultResourceGroupName>` is a name for the resource group within which the key vault will be created (it is kept separately from the service fabric cluster, so they can be independently managed)
- `dev` is an environment signifier (i.e. dev, test, prod, etc)

#### Initialise the key vault

This will create a self-signed certificate, a copy of which will be inserted into your machine's local certificate manager (`certmgr.msc`).

    .\keyvault_sf_initialise.ps1 <keyVaultName> <password>

Take a note of the information that is output by the script.

#### Update the Service Fabric cluster JSON template file

- Open `az-servicefabric.json` in a text editor
- Find the `certificate_url` parameter and update its default value with the URL that was provided by the `keyvault_sf_initialise.ps1` script above
- Find the `certificate_thumbprint` parameter and update its default value with the thumbprint that was provided by the `keyvault_sf_initialise.ps1` script above

#### Deploy the Service Fabric cluster

    .\template-deploy.ps1 <subscriptionId> <ServiceFabricResourceGroupName> westeurope ..\az-servicefabric.json dev

- `<ServiceFabricResourceGroupName>` is a name for the resource group within which the service fabric cluster will be created (it is kept separately from the key vault, so they can be independently managed)
- `dev` is an environment signifier (i.e. dev, test, prod, etc
