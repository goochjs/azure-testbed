# This script deletes a resource group and all underlying resources from Azure

# Run Login-AzureRmAccount to create a connection before executing the script

param (
	[Parameter(Mandatory=$true)][string]$resourceGroup,
	[Parameter(Mandatory=$false)][switch]$force
)

## Variables -----------------------------------


## Main -----------------------------------

trap
{
    Write-Output $_
    exit 1
}

If ( $force ) {
	Remove-AzureRmResourceGroup -Name $resourceGroup -Force -ErrorAction Stop
}
else {
	Remove-AzureRmResourceGroup -Name $resourceGroup -ErrorAction Stop
}

exit 0
