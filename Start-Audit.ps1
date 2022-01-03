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
#$AuditOutput = [PSCustomObject]@{}
#Define the Audit output
$AuditOutput = [PSCustomObject]@{
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

    #Skip IAM section for the moment

    ##Audit the Ms Defender For cloud section##
    $AuditOutput.MsDefenderForCloud = Start-AuditMsDefenderForCloud

    ##Audit the Storage Accounts section##
    $AuditOutput.StorageAccounts = Start-AuditStorageAccount
    
    Write-Host "`nAudit completed on subscription : [$($Subscription.Name)] : [$Subscription]`n" -ForegroundColor DarkGreen 
}

foreach ($AuditSection in ($AuditOutput | Get-Member -MemberType NoteProperty).Name) {
    $AuditOutput.$AuditSection = $AuditOutput.$AuditSection | Sort-Object
}

#Writing the Audit Output in the report section
Write-Output "`nWriting the Audit output"
$AuditOutput | ConvertTo-Json -Depth 20 | Set-Content "./Reports/AuditResult.json" -Force
foreach ($AuditSection in ($AuditOutput | Get-Member -MemberType NoteProperty).Name) {
    $AuditOutput.$AuditSection | ConvertTo-Json -Depth 20 | Set-Content "./Reports/$AuditSection.json" -Force
}

#Generate the Html output
Format-HtmlTable
$CurrentPath = (Get-Location).Path
Write-Host "`nAudit completed Successfully`nYou can consult the Audit result on a web page at $CurrentPath/Web/index.html" -ForegroundColor Green
