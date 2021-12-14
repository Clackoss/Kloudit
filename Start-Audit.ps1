Write-Output " ************"
Write-Output "* CLOUDITING *"
Write-Output " ************"
Write-Output "Starting the Audit"


$Modules = (Get-ChildItem -Path "./Scripts").Name
foreach ($Module in $Modules) {
    $Modudle
    Import-Module "./Scripts/$Module"
}

#Login
Login

$AllSubscriptions = Get-azSubscription
foreach ($Subscription in $AllSubscriptions) {
    #Define the Audit output for json format
    $AuditOutput = [PSCustomObject]@{
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
    Write-Output "Working for subscription $Subscription"
    ##Check for Security Center Recomandations##

    #2.1 Ensure that Azure Defender is set to On for Servers
    $AzureDefenderPricing = AzDefenderPricing
    $AzureDefenderPricing
    if ($AzureDefenderPricing) {
        Write-Output "2.1 ) Security Center Server pricing tier is uncompliant"
        $AuditOutput.SecurityCenter | Add-Member -MemberType NoteProperty -Name AzureDefenderPricing -Value $AzureDefenderPricing -Force
    }

    $AuditOutput | ConvertTo-Json | Set-Content "./Reports/$($Subscription.Name).json" -Force
}