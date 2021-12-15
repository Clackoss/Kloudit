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

#Get all subscriptions
$AllSubscriptions = Get-azSubscription

foreach ($Subscription in $AllSubscriptions) {
    #Define the Audit output for json format
    $UncompliantOutput = [PSCustomObject]@{
        IAM               = [PSCustomObject]@{}
        SecurityCenter    = [PSCustomObject]@{}
        StorageAccounts   = [PSCustomObject]@{}
        Database          = [PSCustomObject]@{}
        LoggingMonitoring = [PSCustomObject]@{}
        Network           = [PSCustomObject]@{}
        VirtualMachines   = [PSCustomObject]@{}
        Other             = [PSCustomObject]@{}
        AppService        = [PSCustomObject]@{}
    }
    Write-Output "Check compliance for subscription [$($Subscription.Name)] : [$Subscription]"
    Write-Output "Checking Security Center Recomandations"
    ##Check for Security Center Recomandations##
    #2.1 - 2.2 - 2.3 - 2.4 - 2.5 - 2.6 - 2.7 - 2.8 - 2.9 - 2.10 : Check for Security Center enablement
    $cpt = 0
    $AllResourcesToCheck = @('VirtualMachines', 'AppServices', 'SqlServers', 'StorageAccounts', 'KubernetesService', 'ContainerRegistry', 'KeyVault')
    foreach ($ResourceToCheck in $AllResourcesToCheck) {
        $cpt++
        $AzureDefenderPricing = Get-AzDefenderPricing -ResourceToCheck $ResourceToCheck
        $ControlName = "2.$cpt Ensure that Azure Defender is set to On for $ResourceToCheck" 
        $UncompliantOutput.SecurityCenter | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderPricing -Force
        Write-Output "$ControlName is : $AzureDefenderPricing"
        
    }
    Write-Output "`nWriting the Audit output"
    $UncompliantOutput | ConvertTo-Json | Set-Content "./Reports/$($Subscription.Name).json" -Force
    Write-Output "Audit completed on subscription : [$($Subscription.Name)] : [$Subscription]`n"
}