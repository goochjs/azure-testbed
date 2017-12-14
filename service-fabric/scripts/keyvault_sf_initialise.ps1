# This script takes an existing keyvault and creates a certificate for it
# for use in a Service Fabric cluster

# Run Login-AzureRmAccount to create a connection before executing the script
param(
    [Parameter(Mandatory=$true)][string]$vaultName,
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$password
)


## Variables -----------------------------------


## Functions -----------------------------------
function Create-TestCertificate()
{
    param(
        [string]$subject,
        [string]$friendlyName,
        [string]$password,
        [string]$filePath
    )

    $securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText

    # CHeck that no certificate with the same name already exists
    $testCert = Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $subject }
    If ( $testCert.Subject -eq $subject ) {
      throw "Certificate with subject $subject already exists in local key store"
    }

    # Create a self-signed certificate - NB this uses a TechNet script so that it will work on Windows 7
    . $PSScriptRoot\New-SelfsignedCertificateEx.ps1

    New-SelfsignedCertificateEx `
        -Subject $subject `
        -EKU "Server Authentication", "Client authentication" `
        -KeySpec "Exchange" `
        -KeyUsage "DigitalSignature" `
        -AllowSMIME `
        -FriendlyName $friendlyName `
        -Path $filePath `
        -Password $securePassword `
        -Algorithm "RSA" `
        -KeyLength 2048 `
        -Exportable `
        -NotAfter $([datetime]::now.AddYears(5))

    $testCert = Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $subject }
    Write-Host "cert.Thumbprint: " $testCert.Thumbprint
    Write-Host "cert.Subject: " $testCert.Subject

    return $testCert
}


function Add-CertificateToVault()
{
    param(
        [string]$secretName,
        [string]$certLocation,
        [string]$password,
        [string]$vaultName,
        [string]$json
    )

    $cert = Get-Content $certLocation -Encoding Byte
    $cert = [System.Convert]::ToBase64String($cert)

    $json = @"
        {
            "data" : "$cert",
            "dataType": "pfx",
            "password": "$password"
        }
"@

    $package = [System.Text.Encoding]::UTF8.GetBytes($json)
    $package = [System.Convert]::ToBase64String($package)
    $secret = ConvertTo-SecureString -String $package -AsPlainText -Force
    return Set-AzureKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue $secret -ErrorAction Stop
}


## Main -----------------------------------
trap
{
    Write-Output $_
    exit 1
}

$clusterCert = Create-TestCertificate `
                -subject "CN=Cluster Cert" `
                -friendlyName "ClusterServerCert" `
                -password $password `
                -filePath "ClusterServerCert.pfx"

$clusterSecret = Add-CertificateToVault `
                -secretName "clusterCert" `
                -certLocation "ClusterServerCert.pfx" `
                -password $password `
                -vaultName $vaultName `
                -json $json

Write-Host "Vault.ResourceId: " (Get-AzureRmResource -ResourceName $vaultName -ResourceGroupName $resourceGroup).ResourceId
Write-Host "Secret.URL: " $clusterSecret.Id
