<#
.SYNOPSIS
Call and print the audit actions for Database section
.DESCRIPTION
Call and print the audit actions for DataBase section
.OUTPUTS
[Pscustomobject] : An object containing the result of the audit for Msdefenderforcloud section
.EXAMPLE
Start-MsDefenderForCloudAudit
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Start-AuditDataBase {
    param(
        [Parameter(Mandatory = $true)][Object]$SubscriptionList
    )

    $DataBase = [PSCustomObject]@{}
    Write-Host "`n**Auditing DataBases configurations**`n" -ForegroundColor DarkMagenta
    foreach ($Subscription in $SubscriptionList) {
        $SubscriptionName = $Subscription.Name
        $SubscriptionId = $Subscription.Id
        #Do not give this to functions
        $AllSqlServer = Get-AzResource -ResourceType "Microsoft.Sql/servers" -ExpandProperties
        $AllSqlDb = Get-AzResource -ResourceType "Microsoft.Sql/servers/databases" -ExpandProperties

        Write-Host "Check compliance for [DataBases : SQL Server] on subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor Cyan
        if ($AllSqlServer.count -gt 0) {
        
        
            if ($AllSqlDb.Count -gt 0) {
                #CIS : 4.1.2
                $CISPoint = @("4.01.2")
                $PropertiesToCheck = @("DataEncryption")
                $CompliantValues = @("Enabled")
                $ControlName = "Ensure [Propertie] is enabled on SQL DataBases"
                #TO FIXXXX
                #$DataBase = Add-CisControlSetp -DataObject $DataBase -CISPoint $CISPoint -PropertiesToCheck $PropertiesToCheck -CompliantValues $CompliantValues -ResourceType "SQL DataBases" -ControlName $ControlName -FunctionToCall "Get-SqlDbTransparentDataEncryption -Subscription $Subscription -AllSqlDb $AllSqlDB"
            }
            else {
                Write-Host "No Sql Database"
            }
        }
        else {
            Write-Host "No Sql Server"
        }
        
    }
}

<#
.SYNOPSIS
Get some audit config for Sql server 
.DESCRIPTION
Get some audit config for Sql server 
Used for CIS point : 4.1.1 - 4.1.3 
.OUTPUTS
[Pscustomobject] : 
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-SqlServerAuditConf {
    param(
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        [Parameter(Mandatory = $true)][string]$CompliantValue,
        [Parameter(Mandatory = $true)][Object]$AllSqlServer,
        [Parameter(Mandatory = $true)][Object]$Subscription
    )
    $ControlResult = [PSCustomObject]@{}
    #Get all the storage accounts in the resource groups

    foreach ($SqlServer in $AllSqlServer) {
        $SqlServerAuditConf = Get-AzSqlServerAudit -ResourceGroupName $SqlServer.ResourceGroupName -ServerName $SqlServer.Name
        $Resource = [PSCustomObject]@{
            ResourceName     = $SqlServer.Name
            Subscription     = $Subscription.Id
            PropertieChecked = $PropertieToCheck
            CompliantValue   = $CompliantValue
            CurrentValue     = $SqlServerAuditConf.$PropertieToCheck
            Compliance       = (Check-Compliance -CurrentValue $SqlServerAuditConf.$PropertieToCheck -CompliantValue $CompliantValue)
        }
        $ControlResult | Add-Member -MemberType NoteProperty -Name $Resource.ResourceName -Value $Resource
    }
    return $ControlResult  
}
<#
.SYNOPSIS
Get some audit config for Sql server DB
.DESCRIPTION
Get some audit config for Sql server DB
Used for CIS point : 4.1.2
.OUTPUTS
[Pscustomobject] : 
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-SqlDbTransparentDataEncryption {
    param(
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        [Parameter(Mandatory = $true)][string]$CompliantValue,
        [Parameter(Mandatory = $true)][Object]$AllSqlDb,
        [Parameter(Mandatory = $true)][Object]$Subscription
    )
    $ControlResult = [PSCustomObject]@{}
    #Get all the storage accounts in the resource groups

    foreach ($SqlDb in $AllSqlDb) {
        $SqlDbRG = $SqlDb.ResourceGroupName
        $SqlDbName = $SqlDb.Name
        $SqlDbServerName = ($SqlDb.ResourceId -split ("/"))[8]
        $SqldbDataEncryption = (Get-AzSqlDatabaseTransparentDataEncryption -ResourceGroupName $SqlDbRG -ServerName $SqlDbServerName -DatabaseName $SqlDbName).State
        $Resource = [PSCustomObject]@{
            ResourceName     = $SqlDbName
            Subscription     = $Subscription.Id
            PropertieChecked = $PropertieToCheck
            CompliantValue   = $CompliantValue
            CurrentValue     = $SqldbDataEncryption
            Compliance       = (Check-Compliance -CurrentValue $SqldbDataEncryption -CompliantValue $CompliantValue)
        }
        $ControlResult | Add-Member -MemberType NoteProperty -Name $Resource.ResourceName -Value $Resource
    }
    return $ControlResult  
}