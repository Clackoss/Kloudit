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


#Define the Audit output
$AuditOutput = [PSCustomObject]@{}

#Get all Azure subscriptions
$SubscriptionList = Get-azSubscription

#Skip IAM section for the moment


##Audit the Ms Defender For cloud section##
    
$MsDefenderForCloudResult = Start-AuditMsDefenderForCloud -SubscriptionList $SubscriptionList
$AuditOutput | Add-Member -MemberType NoteProperty -Name "Microsoft Defender For Cloud" -Value $MsDefenderForCloudResult

##Audit the Storage Accounts section##
$StorageAccountResult = Start-AuditStorageAccount -SubscriptionList $SubscriptionList
$AuditOutput | Add-Member -MemberType NoteProperty -Name "Storage Accounts" -Value $StorageAccountResult

##Audit de Database Section##
$DataBaseResult = Start-AuditDataBase -SubscriptionList $SubscriptionList
$AuditOutput | Add-Member -MemberType NoteProperty -Name "Data Bases" -Value $DataBaseResult

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
Format-HtmlTable -AuditSectionToPrint "AuditResult"
$CurrentPath = (Get-Location).Path
Write-Host "`nAudit completed Successfully`nYou can consult the Audit result on a web page at $CurrentPath\Web\index.html" -ForegroundColor Green
