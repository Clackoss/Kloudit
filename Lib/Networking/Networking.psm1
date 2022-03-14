<#
.SYNOPSIS
Call and print the audit actions for Networking Section
.OUTPUTS
[Pscustomobject] : An object containing the result of the audit for Networking section
.EXAMPLE
Start-AuditNetworking
#>
function Start-AuditNetworking {
    param(
        [Parameter(Mandatory = $true)][Object]$SubscriptionList
    )

    $StorageAccounts = [PSCustomObject]@{}
    Write-Host "`n**Checking Networking configurations**`n" -ForegroundColor DarkMagenta

    foreach ($Subscription in $SubscriptionList) {
        $SubscriptionName = $Subscription.Name
        $SubscriptionId = $Subscription.Id
        Set-AzContext -Subscription $Subscription.Id | Out-null
        $Authheader = Get-ApiAuthHeader
        $uri = "GET https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Network/networkSecurityGroups?api-version=2021-05-01"
        $NsgList = Invoke-RestMethod -Uri $Uri -Method Get -Headers $authHeader

        if ($NsgList.value.count -gt 0) {

            Write-Host "Check compliance for [Networking] on subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor Cyan 

            #CIS : 6.1
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