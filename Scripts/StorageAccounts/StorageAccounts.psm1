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
    #Get all the resource groups
    $AllResourcesGroups = Get-AzResourceGroup

    foreach ($ResouceGroup in $AllResourcesGroups) {
        #Get all the storage accounts in the resource groups
        $StorageAccounts = Get-AzStorageAccount -ResourceGroupName $ResouceGroup.ResourceGroupName

        foreach ($Storage in $StorageAccounts) {
            $StorageDiagSetting = Get-AzStorageServiceLoggingProperty -ServiceType $PropertieToCheck -Context $Storage.Context 
            $Resource = [PSCustomObject]@{
                ResourceName     = $Storage.StorageAccountName
                PropertieChecked = $PropertieToCheck + " LoggingOperations"
                CompliantValue   = $CompliantValue
                CurrentValue     = $StorageDiagSetting.LoggingOperations
                Compliance       = "Compliant"
            }
            if ($StorageDiagSetting.LoggingOperations -notmatch $CompliantValue) {
                $Resource.Compliance = "Uncompliant"
            }
            $ControlResult | Add-Member -MemberType NoteProperty -Name $Storage.StorageAccountName -Value $Resource
        }
    }
    return $ControlResult
}
