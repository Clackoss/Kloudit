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
    #Get all the storage accounts in the resource groups
    $StorageAccounts = Get-AzStorageAccount

    foreach ($Storage in $StorageAccounts) {
        $StorageDiagSetting = Get-AzStorageServiceLoggingProperty -ServiceType $PropertieToCheck -Context $Storage.Context 
        $Resource = [PSCustomObject]@{
            ResourceName   = $Storage.StorageAccountName
            Subscription   = ($Storage.Id -split ("/"))[2]
            PropertieChecked = $PropertieToCheck + " LoggingOperations"
            CompliantValue = $CompliantValue
            CurrentValue   = $StorageDiagSetting.LoggingOperations
            Compliance     = "Compliant"
        }
        if ($StorageDiagSetting.LoggingOperations -notmatch $CompliantValue) {
            $Resource.Compliance = "Uncompliant"
        }
        $ControlResult | Add-Member -MemberType NoteProperty -Name $Storage.StorageAccountName -Value $Resource
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
        $Resource = [PSCustomObject]@{
            ResourceName     = $Storage.StorageAccountName
            Subscription     = $StorageAccount.SubscriptionId
            PropertieChecked = $PropertieToCheck
            CompliantValue   = $CompliantValue
            CurrentValue     = $BlobStorageProperty.DeleteRetentionPolicy.Enabled
            Compliance       = "Compliant"
        }
        if ($Resource.CurrentValue -notmatch $CompliantValue) {
            $Resource.Compliance = "Uncompliant"
        }
        $ControlResult | Add-Member -MemberType NoteProperty -Name $Resource.ResourceName -Value $Resource
    }   
    return $ControlResult
}