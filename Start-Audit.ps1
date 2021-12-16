Write-Output " ************"
Write-Output "* CLOUDITING *"
Write-Output " ************`n"
Write-Output "Starting the Audit"

#Import Modules
$Modules = (Get-ChildItem -Path "./Scripts").Name
foreach ($Module in $Modules) {
    Import-Module "./Scripts/$Module" -Force
}
Write-Output "Modules successfully imported"

#Login
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

#Get all subscriptions
$AllSubscriptions = Get-azSubscription

foreach ($Subscription in $AllSubscriptions) {
    $SubscriptionName = $Subscription.Name
    $SubscriptionId = $Subscription.Id
    Write-Output "Check compliance for subscription [$SubscriptionName] : [$SubscriptionId]"
    $AuditOutput | Add-Member -MemberType NoteProperty -Name $Subscription.Name -Value $ControlPointsPerSub
    #Skip IAM section for the moment

    ##Check for Security Center Recomandations##
    Write-Output "Checking Security Center Recomandations"
    #2.1 - 2.2 - 2.3 - 2.4 - 2.5 - 2.6 - 2.7 - 2.8 : Check for Security Center enablement
    $cpt = 0
    $AllResourcesToCheck = @('VirtualMachines', 'AppServices', 'SqlServers', 'SqlServerVirtualMachines', 'StorageAccounts', 'KubernetesService', 'ContainerRegistry', 'KeyVaults')
    foreach ($ResourceToCheck in $AllResourcesToCheck) {
        $cpt++
        $AzureDefenderPricing = Get-AzDefenderPricing -ResourceToCheck $ResourceToCheck
        $ControlName = "2.$cpt Ensure that Azure Defender is set to On for $ResourceToCheck" 
        $AuditOutput.$SubscriptionName.'MsDefenderForCloud' | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderPricing -Force
        Write-Output "$ControlName is : $($AzureDefenderPricing.Compliance)"
    }

    #2.9 - 2.10 Ensure that Microsoft Defender for Endpoint/cloud (WDATP & MCAS) integration with Microsoft Defender for Cloud is selected
    $AllResourcesToCheck = @("WDATP", "MCAS")
    foreach ($ResourceToCheck in $AllResourcesToCheck) {
        $cpt++
        $AzureDefenderIntegration = Get-MsDefenderIntegration -IntegrationItem $ResourceToCheck
        $ControlName = "2.$cpt Ensure that Microsoft Defender for Endpoint ($ResourceToCheck) integraiton is selected" 
        $AuditOutput.$SubscriptionName.'MsDefenderForCloud' | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderIntegration -Force
        Write-Output "$ControlName is : $($AzureDefenderIntegration.Compliance)"
    }


    #2.11 Ensure that 'Automatic provisioning of monitoring agent' is set to'On'
    $ControlName = "2.11 Ensure that 'Automatic provisioning of monitoring agent' is set to On"
    $AutoProvisioning = Get-AutoProvisioning
    $AuditOutput.$SubscriptionName.'MsDefenderForCloud' | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AutoProvisioning -Force
    Write-Output "$ControlName is : $($AutoProvisioning.Compliance)"

    Write-Output "`nAudit completed on subscription : [$($Subscription.Name)] : [$Subscription]`n"
}

#Writing the Audit Output in the report section
Write-Output "`nWriting the Audit output"
$AuditOutput | ConvertTo-Json -Depth 20 | Set-Content "./Reports/AuditResult.json" -Force