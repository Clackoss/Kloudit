<#
.SYNOPSIS
Call and print the audit actions for Storage Account section
.OUTPUTS
[Pscustomobject] : An object containing the result of the audit for StorageAccounts section
.EXAMPLE
Start-AuditStorageAccount
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Start-AuditStorageAccount {
    param(
        [Parameter(Mandatory = $true)][Object]$SubscriptionList
    )

    $StorageAccounts = [PSCustomObject]@{}
    Write-Host "`n**Checking Storage Accounts configurations**`n" -ForegroundColor DarkMagenta

    foreach ($Subscription in $SubscriptionList) {
        $SubscriptionName = $Subscription.Name
        $SubscriptionId = $Subscription.Id
        Set-AzContext -Subscription $Subscription.Id | Out-null

        if ((Get-AzResource -ResourceType "Microsoft.Storage/storageAccounts").count -gt 0) {

            Write-Host "Check compliance for [Storage Accounts] on subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor Cyan 

            #CIS : 3.1 - 3.2 - 3.5 - 3.6 - 3.7 - 3.12
            $CISPoint = @("3.01", "3.02", "3.05", "3.06", "3.07", "3.12")
            $PropertiesToCheck = @("supportsHttpsTrafficOnly", "KeyPolicy.keyExpirationPeriodInDays", "allowBlobPublicAccess", "networkAcls.defaultAction", "networkAcls.bypass", "minimumTlsVersion")
            $CompliantValues = @("True", "[0-365]", "False", "Deny", "AzureServices", "TLS1_2")
            $StorageAccounts = Add-CisControlSetp -DataObject $StorageAccounts -CISPoint $CISPoint -PropertiesToCheck $PropertiesToCheck -CompliantValues $CompliantValues -ResourceType "Storage Accounts" -controlName "Ensure that [Propertie] is set to [Compliant]" -FunctionToCall "Get-ResourceProperties -ResourceType 'Microsoft.Storage/storageAccounts'"
 
            #CIS : 3.8
            $CISPoint = @("3.08")
            $PropertiesToCheck = @("DeleteRetentionPolicy.Enabled")
            $CompliantValues = @("True")
            $StorageAccounts = Add-CisControlSetp -DataObject $StorageAccounts -CISPoint $CISPoint -PropertiesToCheck $PropertiesToCheck -CompliantValues $CompliantValues -ResourceType "Storage Accounts" -FunctionToCall "Get-StorageSoftDelete" -controlName "Ensure that [Propertie] is Enabled for Azure Storage"
 

            #CIS : 3.3, 3.10, 3.11
            $CISPoint = @("3.03", "3.10", "3.11")
            $PropertiesToCheck = @("Queue", "Blob", "Table")
            $CompliantValues = @("All", "All", "All")
            $StorageAccounts = Add-CisControlSetp -DataObject $StorageAccounts -CISPoint $CISPoint -PropertiesToCheck $PropertiesToCheck -CompliantValues $CompliantValues -ResourceType "Storage Accounts" -ControlName "Ensure Storage logging is enabled for [Propertie]" -FunctionToCall "Get-StorageClassicDiagSettings"
        }
        else {
            Write-Host "No storage account in the subscription : $SubscriptionName"
        }
    }
    return $StorageAccounts
}


<#
.SYNOPSIS
Get some Azure classic diag setting properties
.DESCRIPTION
Used for CIS control point 3.3, 3.10, 3.11
.OUTPUTS
[Pscustomobject] : An object containing the value of the control point
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-StorageClassicDiagSettings {
    param(
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        [Parameter(Mandatory = $true)][string]$CompliantValue
    )
    $ControlResult = [PSCustomObject]@{}
    #Get all the storage accounts in the resource groups (can not use get-azresource because need of Context)
    $StorageAccounts = Get-AzStorageAccount
    foreach ($Storage in $StorageAccounts) {
        $StorageDiagSetting = [string](Get-AzStorageServiceLoggingProperty -ServiceType $PropertieToCheck -Context $Storage.Context).LoggingOperations 
        $Subscription = ($Storage.Id -split ("/"))[2]
        $ControlResult = Set-ControlResultObject -CurrentValue $StorageDiagSetting -ResourceName $Storage.StorageAccountName -ControlResult $ControlResult -PropertieToCheck $PropertieToCheck -CompliantValue $CompliantValue -Subscription $Subscription
    }
    return $ControlResult
}

<#
.SYNOPSIS
Get Azure Storage informations for Soft Delete
.DESCRIPTION
Used for CIS control point 3.8
.OUTPUTS
[Pscustomobject] : An object containing the value of the control point
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-StorageSoftDelete {
    param (
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        [Parameter(Mandatory = $true)][string]$CompliantValue
    )
    $ControlResult = [PSCustomObject]@{}
    #Get all the storage accounts
    $AllStorageAccounts = Get-AzResource -ResourceType "Microsoft.Storage/storageAccounts"  

    foreach ($StorageAccount in $AllStorageAccounts) {
        $BlobStorageProperty = Get-AzStorageBlobServiceProperty -ResourceGroupName $StorageAccount.ResourceGroupName -StorageAccountName $StorageAccount.Name
        $Subscription = $StorageAccount.SubscriptionId
        $ControlResult = Set-ControlResultObject -CurrentValue $BlobStorageProperty.DeleteRetentionPolicy.Enabled -ResourceName $StorageAccount.Name -ControlResult $ControlResult -PropertieToCheck $PropertieToCheck -CompliantValue $CompliantValue -Subscription $Subscription
    }   
    return $ControlResult
}