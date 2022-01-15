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
        ##4.1.1 & 4.1.3
        
            if ($AllSqlDb.Count -gt 0) {
                #CIS : 4.1.2
                $CISPoint = @("4.01.2")
                $PropertiesToCheck = @("DataEncryption")
                $CompliantValues = @("Enabled")
                $ControlName = "Ensure [Propertie] is enabled on SQL DataBases"
                $DataBase = Add-CisControlSetp -DataObject $DataBase -CISPoint $CISPoint -PropertiesToCheck $PropertiesToCheck -CompliantValues $CompliantValues -ResourceType "SQL DataBases" -ControlName $ControlName -FunctionToCall "Get-SqlDbTransparentDataEncryption"            }
            else {
                Write-Host "No Sql Database"
            }
        }
        else {
            Write-Host "No Sql Server"
        }
        
    }
    return $DataBase
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
        [Parameter(Mandatory = $true)][Object]$AllSqlServer
    )
    $ControlResult = [PSCustomObject]@{}
    #Get all the storage accounts in the resource groups

    $AllSqlServer = Get-AzResource -ResourceType "Microsoft.Sql/servers"
    foreach ($SqlServer in $AllSqlServer) {
        $SqlServerAuditConf = (Get-AzSqlServerAudit -ResourceGroupName $SqlServer.ResourceGroupName -ServerName $SqlServer.Name).$PropertieToCheck
        $Subscription =  ($SqlServer.id -split ("/"))[2]
        $ControlResult = Set-ControlResultObject -CurrentValue $SqlServerAuditConf -ControlResult $ControlResult -PropertieToCheck $PropertieToCheck -CompliantValue $CompliantValue -ResourceName $SqlServer.Name -Subscription $Subscription
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
        [Parameter(Mandatory = $true)][string]$CompliantValue
    )
    $ControlResult = [PSCustomObject]@{}
    #Get all the storage accounts in the resource groups
    $AllSqlDb = Get-AzResource -ResourceType "Microsoft.Sql/servers/databases" -ExpandProperties
    foreach ($SqlDb in $AllSqlDb) {
        $SqlDbRG = $SqlDb.ResourceGroupName
        $SqlDbName = $SqlDb.Name
        $SqlDbServerName = ($SqlDb.ResourceId -split ("/"))[8]
        $Subscription = ($SqlDb.id -split ("/"))[2]
        $SqldbDataEncryption = [String](Get-AzSqlDatabaseTransparentDataEncryption -ResourceGroupName $SqlDbRG -ServerName $SqlDbServerName -DatabaseName $SqlDbName).State
        $ControlResult = Set-ControlResultObject -CurrentValue $SqldbDataEncryption -ControlResult $ControlResult -PropertieToCheck $PropertieToCheck -CompliantValue $CompliantValue -ResourceName $SqlDb.Name -Subscription $Subscription
    }
    return $ControlResult  
}