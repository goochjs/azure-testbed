# This script creates a Service Fabric cluster in Azure
# The cluster is secured by a self-signed X.509 certificate

# Run Login-AzureRmAccount to create a connection before executing the script

## Variables -----------------------------------

. ..\variables-dev.ps1

$azureResourceGroup = $system + "-sf-cluster-" + $environment
$azureClusterName = $system + "-sf-cluster"      
$azureVault = $system + "-sf-keyvault"
$certificateSubject = "$azureClusterName.$azureLocation.cloudapp.azure.com"
$tagScript = $PSScriptRoot + "\resourcegroup_tag.ps1"


## Main -----------------------------------
trap
{
    Write-Output $_
    exit 1
}

If (
	!$azureSubscription `
	-or !$azureClusterName `
	-or !$azureResourceGroup `
	-or !$azureLocation `
	-or !$azureClusterSize `
	-or !$adminUser `
	-or !$adminPassword `
	-or !$certificateSubject `
	-or !$certificatePassword `
	-or !$certificateFolder `
	-or !$operatingSystem `
	-or !$azureClusterInstanceType `
	-or !$azureVault `
	-or !$tags
) {
	Write-Output `
		"  azureSubscription = $azureSubscription" `
		"  azureClusterName = $azureClusterName" `
		"  azureResourceGroup = $azureResourceGroup" `
		"  azureLocation = $azureLocation" `
		"  azureClusterSize = $azureClusterSize" `
		"  adminUser = $adminUser" `
		"  adminPassword = $adminPassword" `
		"  certificateSubject = $certificateSubject" `
		"  certificatePassword = $certificatePassword" `
		"  certificateFolder = $certificateFolder" `
		"  operatingSystem = $operatingSystem" `
		"  azureClusterInstanceType = $azureClusterInstanceType" `
		"  azureVault = $azureVault" `
		"  tags = $tags"
	throw "Mandatory variable missing"
}

If (-not (Test-Path $certificateFolder -PathType Container)) {
	throw [System.IO.FileNotFoundException] "certificateFolder $certificateFolder does not exist"
}


# Choose the subscription where the cluster will be created
Select-AzureRmSubscription -SubscriptionId $azureSubscription -ErrorAction Stop


# Create the Service Fabric cluster and associated resources (including a resource group for it all)
New-AzureRmServiceFabricCluster `
	-Name $azureClusterName `
	-ResourceGroupName $azureResourceGroup `
	-Location $azureLocation `
	-ClusterSize $azureClusterSize `
	-VmUserName $adminUser `
	-VmPassword $adminPassword `
	-CertificateSubjectName $certificateSubject `
	-CertificatePassword $certificatePassword `
	-CertificateOutputFolder $certificateFolder `
	-OS $operatingSystem `
	-VmSku $azureClusterInstanceType `
	-KeyVaultName $azureVault `
	-ErrorAction Stop


# Tag everything (the `New-AzureRmServiceFabricCluster` command doesn't support tagging)
& $tagScript $azureResourceGroup all $tags

exit 0