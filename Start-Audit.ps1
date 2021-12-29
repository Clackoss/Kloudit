$logo = Get-Content -Path "banner.txt"
Write-Output "`n`n"
$logo
Write-Output "`nStarting the Configuration Audit of your Azure infrastructure"

#Import Modules
$Modules = (Get-ChildItem -Path "./Scripts").Name
foreach ($Module in $Modules) {
    Import-Module "./Scripts/$Module" -Force
}
Write-Output "Modules successfully imported"

#Login to azure
Login

#Define the Audit output for json format
$AuditOutput = [PSCustomObject]@{}
#Define the Audit output
$ControlPointsPerSub = [PSCustomObject]@{
    IAM                = [PSCustomObject]@{}
    MsDefenderForCloud = [PSCustomObject]@{}
    StorageAccounts    = [PSCustomObject]@{}
    Database           = [PSCustomObject]@{}
    LoggingMonitoring  = [PSCustomObject]@{}
    Network            = [PSCustomObject]@{}
    VirtualMachines    = [PSCustomObject]@{}
    Other              = [PSCustomObject]@{}
    AppService         = [PSCustomObject]@{}
}

#Get all Azure subscriptions
$AllSubscriptions = Get-azSubscription

foreach ($Subscription in $AllSubscriptions) {
    $SubscriptionName = $Subscription.Name
    $SubscriptionId = $Subscription.Id
    Set-AzContext -Subscription $SubscriptionId

    Write-Host "Check compliance for subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor DarkCyan
    $AuditOutput | Add-Member -MemberType NoteProperty -Name $SubscriptionName -Value $ControlPointsPerSub
    
    #Skip IAM section for the moment

    ##Check for Security Center Recomandations##
    Write-Host "`n**Checking Microsoft Defender for cloud configurations**`n" -ForegroundColor DarkMagenta
    $ControlPoint = "MsDefenderForCloud"
    #2.1 - 2.2 - 2.3 - 2.4 - 2.5 - 2.6 - 2.7 - 2.8 : Check for Security Center enablement
    $cpt = 0
    $AllResourcesToCheck = @('VirtualMachines', 'AppServices', 'SqlServers', 'SqlServerVirtualMachines', 'StorageAccounts', 'KubernetesService', 'ContainerRegistry', 'KeyVaults')
    foreach ($ResourceToCheck in $AllResourcesToCheck) {
        $cpt++
        $AzureDefenderPricing = Get-AzDefenderPricing -ResourceToCheck $ResourceToCheck
        $ControlName = "2.0$cpt Ensure that Azure Defender is set to On for $ResourceToCheck" 
        $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderPricing -Force
        Write-Output "$ControlName is : $($AzureDefenderPricing.Compliance)" 
    }

    #2.9 - 2.10 Ensure that Microsoft Defender for Endpoint/cloud (WDATP & MCAS) integration with Microsoft Defender for Cloud is selected
    $AllResourcesToCheck = @("WDATP", "MCAS")
    foreach ($ResourceToCheck in $AllResourcesToCheck) {
        $cpt++
        $AzureDefenderIntegration = Get-MsDefenderIntegration -IntegrationItem $ResourceToCheck
        $ControlName = "2.$cpt Ensure that Microsoft Defender for Endpoint ($ResourceToCheck) integraiton is selected" 
        $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderIntegration -Force
        Write-Output "$ControlName is : $($AzureDefenderIntegration.Compliance)"
    }


    #2.11 Ensure That Auto provisioning of 'Log Analytics agent for Azure VMs is Set to On
    $ControlName = "2.11 Ensure That Auto provisioning of Log Analytics agent for Azure VMs is Set to On"
    $AutoProvisioning = Get-AutoProvisioning
    $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AutoProvisioning -Force
    Write-Output "$ControlName is : $($AutoProvisioning.Compliance)"

    #2.12 Ensure Any of the ASC Default Policy Setting is Not Set to 'Disabled'
    $ControlName = "2.12 Ensure Any of the ASC Default Policy Setting is Not Set to Disabled"
    $ASCPolicyState = Get-ASCPolicyState
    $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $ASCPolicyState -Force
    Write-Output "$ControlName is : $($ASCPolicyState.Compliance)"

    #2.13 Ensure 'Additional email addresses' is Configured with a Security Contact Email
    $ControlName = "2.13 Ensure 'Additional email addresses' is Configured with a Security Contact Email"
    $SecurityEmail = Get-SecurityContact
    $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $SecurityEmail -Force
    Write-Output "$ControlName is : $($SecurityEmail.Compliance)"

    #2.14
    #2.15

    #Check The Storage Accounts Section
    Write-Host "`n**Checking Storage Accounts configurations**`n" -ForegroundColor DarkMagenta
    $ControlPoint = "StorageAccounts"

    if ((Get-AzResource -ResourceType "Microsoft.Storage/storageAccounts").count -gt 0) {
        #3.1 - 3.2 - 3.5 - 3.6 - 3.7 - 3.12
        $CISPoint = @("3.01", "3.02", "3.05", "3.06", "3.07", "3.12")
        $PropertiesToCheck = @("supportsHttpsTrafficOnly", "KeyPolicy.keyExpirationPeriodInDays", "allowBlobPublicAccess", "networkAcls.defaultAction", "networkAcls.bypass", "minimumTlsVersion")
        $CompliantValues = @("True", "[0-365]", "False", "Deny", "AzureServices", "TLS1_2")
        for ($i = 0; $i -lt $PropertiesToCheck.Count; $i++) {
            $ControlName = "$($CISPoint[$i]) Ensure that [$($PropertiesToCheck[$i])] is set to [$($CompliantValues[$i])]"
            $StorageAccountProperties = Get-ResourceProperties -ResourceType "Microsoft.Storage/storageAccounts" -PropertieToCheck $($PropertiesToCheck[$i]) -CompliantValue $($CompliantValues[$i])
            $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $StorageAccountProperties -Force
            Write-Host "$ControlName" -ForegroundColor Blue
            foreach ($StorageAccount in $AuditOutput.$SubscriptionName.$ControlPoint.$ControlName.Psobject.Properties) {
                Write-Output "Storage Account : $($StorageAccount.Name) is : $($StorageAccount.Value.Compliance)"
            }
        }

        #3.3, 3.10, 3.11
        $CISPoint = @("3.03", "3.10", "3.11")
        $PropertiesToCheck = @("Queue", "Blob", "Table")
        $CompliantValues = @("All", "All", "All")
        for ($i = 0; $i -lt $PropertiesToCheck.Count; $i++) {
            $ControlName = "$($CISPoint[$i]) Ensure Storage logging is enabled for [$($PropertiesToCheck[$i])]"
            $DiagSettingPropertie = Get-StorageClassicDiagSettings -PropertieToCheck $PropertiesToCheck[$i] -CompliantValue $CompliantValues[$i]
            $AuditOutput.$SubscriptionName.$ControlPoint | Add-Member -MemberType NoteProperty -Name $ControlName -Value $DiagSettingPropertie -Force
            Write-Host "$ControlName" -ForegroundColor Blue
            foreach ($StorageAccount in $AuditOutput.$SubscriptionName.$ControlPoint.$ControlName.Psobject.Properties) {
                Write-Output "Storage Account : $($StorageAccount.Name) is : $($StorageAccount.Value.Compliance)"
            }
        }
    }
    else {
        Write-Output "No storage account in the subscription : $SubscriptionName"
    }
    

    Write-Host "`nAudit completed on subscription : [$($Subscription.Name)] : [$Subscription]`n" -ForegroundColor DarkGreen
    
}

foreach ($Subscription in ($AuditOutput | Get-Member -MemberType NoteProperty).Name) {
    foreach ($ControlPoint in ($AuditOutput.$Subscription | Get-Member -MemberType NoteProperty).Name) {
        $AuditOutput.$Subscription.$ControlPoint = $AuditOutput.$Subscription.$ControlPoint | Sort-Object
    }
}

#Writing the Audit Output in the report section
Write-Output "`nWriting the Audit output"
$AuditOutput | ConvertTo-Json -Depth 20 | Set-Content "./Reports/AuditResult.json" -Force

Format-HtmlTable
 
<# $v = get-content -raw -Path Reports/AuditResult.json | ConvertFrom-Json

$sortedProps = [ordered] @{}
Get-Member -Type  NoteProperty -InputObject $bar.'Efrei - certification Az 104 - 500'.StorageAccounts | Sort-Object -Stable Name | % { $sortedProps[$_.Name] = $bar.'Efrei - certification Az 104 - 500'.StorageAccounts.$($_.Name) }

$barWithSortedProperties = New-Object PSCustomObject
Add-Member -InputObject $barWithSortedProperties -NotePropertyMembers $sortedProps  #>
