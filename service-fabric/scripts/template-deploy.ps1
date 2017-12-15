# This script deploys an Azure JSON resource template file

# Run Login-AzureRmAccount to create a connection before executing the script

param (
	[Parameter(Mandatory=$true)][string]$azureSubscription,
	[Parameter(Mandatory=$true)][string]$systemPrefix,
	[Parameter(Mandatory=$true)][string]$resourceGroup,
	[Parameter(Mandatory=$true)][string]$azureLocation,
	[Parameter(Mandatory=$true)][string]$templateFile,
	[Parameter(Mandatory=$false)][string]$environment = "dev"
)

## Variables -----------------------------------

$deploymentName = (Get-Date -Format FileDateTimeUniversal)
$overrideParameters = @"
    {
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            "azure_location" : {
                "value" : "$azureLocation",
                "type" : "String"
            },
						"system_prefix" : {
                "value" : "$systemPrefix",
                "type" : "String"
            },
						"environment" : {
                "value" : "$environment",
                "type" : "String"
            }
        }
    }
"@

## Main -----------------------------------
trap
{
    Write-Output $_
    exit 1
}

# Create the temporary parameter file
$tempParamFile = New-TemporaryFile
Out-File -FilePath $tempParamFile -InputObject $overrideParameters
Write-Output "Temporary parameter override file created - $tempParamFile"

# Check that the template exists
If (-not (Test-Path $templateFile -PathType Leaf)) {
	throw [System.IO.FileNotFoundException] "templateFile $templateFile does not exist"
}

# Choose the subscription where the cluster will be created
Select-AzureRmSubscription `
	-SubscriptionId $azureSubscription `
	-ErrorAction Stop

# Create/update the resource group
New-AzureRmResourceGroup `
	-Name $resourceGroup `
	-Location $azureLocation `
	-Force `
	-ErrorAction Stop

# Test the template
Test-AzureRmResourceGroupDeployment `
	-Mode Complete `
	-ResourceGroupName $resourceGroup `
	-TemplateFile $templateFile `
	-TemplateParameterFile $tempParamFile `
	-ErrorAction Stop

# Apply the template
New-AzureRmResourceGroupDeployment `
	-Name $deploymentName `
	-Mode Complete `
	-ResourceGroupName $resourceGroup `
	-TemplateFile $templateFile `
	-TemplateParameterFile $tempParamFile `
	-Force `
	-ErrorAction Stop

# Delete the temporary parameter file
Remove-Item $tempParamFile -Force
Write-Output "Temporary parameter override file deleted - $tempParamFile"

exit 0
