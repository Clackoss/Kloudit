<#
.SYNOPSIS
Call and print the audit actions for MsDefenderForcloud section
.DESCRIPTION
Call and print the audit actions for MsDefenderForcloud section
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
    Write-Host "`n**Checking Storage Accounts configurations on subscription**`n" -ForegroundColor DarkMagenta

    foreach ($Subscription in $SubscriptionList) {
        $SubscriptionName = $Subscription.Name
        $SubscriptionId = $Subscription.Id
        Set-AzContext -Subscription $Subscription.Id

        if ((Get-AzResource -ResourceType "Microsoft.Storage/storageAccounts").count -gt 0) {

            Write-Host "Check compliance for [Storage Accounts] on subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor Cyan 

            #CIS : 3.1 - 3.2 - 3.5 - 3.6 - 3.7 - 3.12
            $CISPoint = @("3.01", "3.02", "3.05", "3.06", "3.07", "3.12")
            $PropertiesToCheck = @("supportsHttpsTrafficOnly", "KeyPolicy.keyExpirationPeriodInDays", "allowBlobPublicAccess", "networkAcls.defaultAction", "networkAcls.bypass", "minimumTlsVersion")
            $CompliantValues = @("True", "[0-365]", "False", "Deny", "AzureServices", "TLS1_2")
            #For all CIS Point to control
            for ($i = 0; $i -lt $PropertiesToCheck.Count; $i++) {
                $ControlName = "$($CISPoint[$i]) Ensure that [$($PropertiesToCheck[$i])] is set to [$($CompliantValues[$i])]"
                $StorageAccountProperties = Get-ResourceProperties -ResourceType "Microsoft.Storage/storageAccounts" -PropertieToCheck $($PropertiesToCheck[$i]) -CompliantValue $($CompliantValues[$i])
                $StorageAccounts | Add-Member -MemberType NoteProperty -Name $ControlName -Value $StorageAccountProperties 
                Write-Host "$ControlName" -ForegroundColor Blue
                foreach ($StorageAccount in $StorageAccounts.$ControlName.Psobject.Properties) {
                    Write-Host "Storage Account : $($StorageAccount.Name) is : $($StorageAccount.Value.Compliance)"
                }
            }

            #CIS : 3.8
            $ControlName = "3.08 Ensure that [Soft Delete] is set to [True]"
            $StorageAccountProperties = Get-ResourceProperties -ResourceType "Microsoft.Storage/storageAccounts" -PropertieToCheck "DeleteRetentionPolicy.Enabled" -CompliantValue "True"
            $StorageAccounts | Add-Member -MemberType NoteProperty -Name $ControlName -Value $StorageAccountProperties 
            Write-Host "$ControlName" -ForegroundColor Blue
            foreach ($StorageAccount in $StorageAccounts.$ControlName.Psobject.Properties) {
                Write-Host "Storage Account : $($StorageAccount.Name) is : $($StorageAccount.Value.Compliance)"
            }

            #CIS : 3.3, 3.10, 3.11
            $CISPoint = @("3.03", "3.10", "3.11")
            $PropertiesToCheck = @("Queue", "Blob", "Table")
            $CompliantValues = @("All", "All", "All")
            for ($i = 0; $i -lt $PropertiesToCheck.Count; $i++) {
                $ControlName = "$($CISPoint[$i]) Ensure Storage logging is enabled for [$($PropertiesToCheck[$i])]"
                $DiagSettingPropertie = Get-StorageClassicDiagSettings -PropertieToCheck $PropertiesToCheck[$i] -CompliantValue $CompliantValues[$i]
                $StorageAccounts | Add-Member -MemberType NoteProperty -Name $ControlName -Value $DiagSettingPropertie -Force
                Write-Host "$ControlName" -ForegroundColor Blue
                foreach ($StorageAccount in $StorageAccounts.$ControlName.Psobject.Properties) {
                    Write-Host "Storage Account : $($StorageAccount.Name) is : $($StorageAccount.Value.Compliance)"
                }
            }
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
    #Get all the storage accounts in the resource groups
    $StorageAccounts = Get-AzStorageAccount

    foreach ($Storage in $StorageAccounts) {
        $StorageDiagSetting = Get-AzStorageServiceLoggingProperty -ServiceType $PropertieToCheck -Context $Storage.Context 
        $Resource = [PSCustomObject]@{
            ResourceName     = $Storage.StorageAccountName
            Subscription     = ($Storage.Id -split ("/"))[2]
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