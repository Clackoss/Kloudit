$logo = Get-Content -Path "banner.txt"
Write-Output "`n`n"
$logo
Write-Output "`nStarting the Configuration Audit of your Azure infrastructure"

#Import Modules
$Modules = (Get-ChildItem -Path "./Lib").Name
foreach ($Module in $Modules) {
    Import-Module "./Lib/$Module" -Force
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
if ($null -ne $MsDefenderForCloudResult) {
    $AuditOutput | Add-Member -MemberType NoteProperty -Name "2 - Microsoft Defender For Cloud" -Value $MsDefenderForCloudResult
}
Write-Host "`nAudit for MsDefenderForCloud Finished`n"

##Audit the Storage Accounts section##
$StorageAccountResult = Start-AuditStorageAccount -SubscriptionList $SubscriptionList
if ($null -ne $StorageAccountResult) {
    $AuditOutput | Add-Member -MemberType NoteProperty -Name "3 - Storage Accounts" -Value $StorageAccountResult   
}
Write-Host "`nAudit for StorageAccount Finished`n"

##Audit de Database Section##
$DataBaseResult = Start-AuditDataBase -SubscriptionList $SubscriptionList
if ($null -ne $DataBaseResult) {
    $AuditOutput | Add-Member -MemberType NoteProperty -Name "4 - Data Bases" -Value $DataBaseResult   
}
Write-Host "`nAudit for DataBases Finished`n"

foreach ($AuditSection in ($AuditOutput | Get-Member -MemberType NoteProperty).Name) {
    $AuditOutput.$AuditSection = $AuditOutput.$AuditSection | Sort-Object
}

#Writing the Audit Output in the report section
Write-Output "`nWriting the Audit output"
$AuditOutput | ConvertTo-Json -Depth 20 | Set-Content "./Reports/AuditResult.json" -Force
foreach ($AuditSection in ($AuditOutput | Get-Member -MemberType NoteProperty).Name) {
    $AuditOutput.$AuditSection | ConvertTo-Json -Depth 20 | Set-Content "./Reports/$AuditSection.json" -Force
}

#filter for compliant and uncompliant resources
Get-DataFilteredByCompliance -ComplianceState "Compliant"
Get-DataFilteredByCompliance -ComplianceState "Uncompliant"

#Generate the Html output
$HtmlToGenerateList = @("AuditResult", "Compliant", "Uncompliant")
foreach ($HtmlToGenerate in $HtmlToGenerateList) {
    Format-HtmlTable -AuditSectionToPrint $HtmlToGenerate  
}
$CurrentPath = (Get-Location).Path

Write-Host "`nAudit completed Successfully`nYou can consult the Audit result on a web page at $CurrentPath\Web\AuditResult.html" -ForegroundColor Green
.\Web\AuditResult.html