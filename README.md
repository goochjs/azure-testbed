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

    .\template-deploy.ps1 <subscriptionId> <prefix> <keyVaultResourceGroupName> westeurope ..\az-keyvault.json dev

- `<subscriptionId>` is the identifier of your subscription in Microsoft Azure - it's output by the Login-AzureRmAccount command above
<prefix> is a short set of alphanumeric characters (e.g. `jgstuff`) that will be pre-pended to the names of the various resources, so to be able to identify them
- `<keyVaultResourceGroupName>` is a name for the resource group within which the key vault will be created (it should be kept separately from the service fabric cluster, so they can be independently managed and so you don't keep losing your keys when you have to mess around with the Service Fabric)
- `westeurope` is the Azure region into which the resources will be deployed
- `..\az-keyvault.json` is the location of the JSON template file
- `dev` is an environment signifier (i.e. dev, test, prod, etc)

#### Initialise the key vault

This will create a self-signed certificate, a copy of which will be inserted into your machine's local certificate manager (`certmgr.msc`).

    .\keyvault_sf_initialise.ps1 <keyVaultName> <keyVaultResourceGroupName> <password>

Take a note of the information that is output by the script.

### Create the Service Fabric cluster

`cd` into the scripts directory

#### Update the Service Fabric cluster JSON template file

- Open `az-servicefabric.json` in a text editor
- Find the `certificate_url` parameter and update its default value with the URL that was provided by the `keyvault_sf_initialise.ps1` script above
- Find the `certificate_thumbprint` parameter and update its default value with the thumbprint that was provided by the `keyvault_sf_initialise.ps1` script above
- Find the `keyvault_id` parameter and update its default value with the resource ID that was provided by the `keyvault_sf_initialise.ps1` script above

#### Deploy the Service Fabric cluster

    .\template-deploy.ps1 <subscriptionId> <prefix> <ServiceFabricResourceGroupName> westeurope ..\az-servicefabric.json dev

- <subscriptionId>` is the same as above
- `<prefix>` is the same as above
- `<ServiceFabricResourceGroupName>` is the name for the resource group within which the Service Fabric resources will be created (it should be given a different name to the one used in the Key Vault command above)
- `westeurope` is the same as above
- `..\az-servicefabric.json` is the location of the JSON template file
- `dev` is the same as above

### Clearing up

If you want to remove what you've just created, run the following command:-

    .\resourcegroup-delete.ps1 <ServiceFabricResourceGroupName> [-force]

- `-force` is an optional switch, to prevent the script from asking "Are you sure?"

The above command takes around 5 minutes to complete.  The Key Vault can also be deleted, if you want, by using its Resource Group name in the command above.
