function Start-AuditLoggingAndMonitoring {
    param (
        # The subscription List audited
        [Parameter(Mandatory = $true)][Object]$SubscriptionList
    )

    #Object containing The section audit, returned to main script
    $LoggingAndMonitoring = [PSCustomObject]@{}

    Write-Host "`n**Checking Logging & Monitoring configurations**`n" -ForegroundColor DarkMagenta

    foreach ($Subscription in $SubscriptionList) {
        $SubscriptionName = $Subscription.Name
        $SubscriptionId = $Subscription.Id

        Write-Host "Check compliance for [Monitoring using Activity Log Alerts] on subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor Cyan 

        #CIS : 5.2.1 to 5.2.9
        $OperationNameToCheck = @("microsoft.authorization/policyassignments/write", "microsoft.authorization/policyassignments/delete", "microsoft.network/networksecuritygroups/write", "microsoft.Network/networkSecurityGroups/delete", "microsoft.network/networksecuritygroups/securityrules/write",
            "microsoft.network/networksecuritygroups/securityrules/delete", "microsoft.security/securitysolutions/write", "microsoft.security/securitysolutions/delete", "microsoft.sql/servers/firewallrules/write")
        $ControlName = @("5.2.1 Ensure that Activity Log Alert exists for Create Policy Assignment", "5.2.2 Ensure that Activity Log Alert exists for Delete Policy Assignment", "5.2.3 Ensure that Activity Log Alert exists for Create or Update Network
        Security Group", "5.2.4 Ensure that Activity Log Alert exists for Delete Network Security
        Group", "5.2.5 Ensure that Activity Log Alert exists for Create or Update Network
        Security Group", "5.2.6 Ensure that activity log alert exists for the Delete Network Security
        Group Rule", "5.2.7 Ensure that Activity Log Alert exists for Create or Update Security
        Solution", "5.2.8 Ensure that Activity Log Alert exists for Delete Security Solution", "5.2.9 Ensure that Activity Log Alert exists for Create or Update or Delete
        SQL Server Firewall Rule")
        
        for ($i = 0; $i -lt 9; $i++) {
            $ControlPointValue = Get-ActivityLogAlertsByService -operationName $OperationNameToCheck[$i] -SubscriptionId $SubscriptionId -CompliantValue "True"
            $LoggingAndMonitoring | Add-Member -MemberType NoteProperty -Name $ControlName[$i] -Value $ControlPointValue
            Write-Host "$($ControlName[$i]) is $($ControlPointValue.$SubscriptionId.compliance)"
        }
    }
    return $LoggingAndMonitoring
}



function Get-ActivityLogAlertsByService {
    param (
        # The service you want to get the Activity Log alert
        [Parameter(Mandatory = $true)][string]$OperationName,
        # The SubscriptionId to Audit
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        # The expected value
        [Parameter(Mandatory = $true)][string]$CompliantValue,
        # Propertie Checked
        [Parameter(Mandatory = $false)][string]$PropertieToCheck
    )

    $ControlResult = [PSCustomObject]@{}
    $ApiUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Insights/activityLogAlerts?api-version=2020-10-01"
    $AuthHeader = Get-ApiAuthHeader
    #Get all the activityLogAlerts
    $ActivityLogAlertsList = Invoke-RestMethod -Uri $ApiUri -Method Get -Headers $authHeader
    
    if ($null -eq $ActivityLogAlertsList) {
        Write-Host "No activity Log Alerts Set on subscription $SubscriptionId"
        $ControlResult = Set-ControlResultObject -CurrentValue "False" -ResourceName $SubscriptionId -ControlResult $ControlResult -PropertieToCheck "IsActivityLogAlertEnabled" -CompliantValue $CompliantValue -Subscription $SubscriptionId
    }
    foreach ($ActivityLogAlert in $ActivityLogAlertsList) {
        $ActivityLogAlertOperationName = ($ActivityLogAlert.value.properties.condition.allOf | Where-Object { $_.field -eq "operationName" })
        if ($ActivityLogAlertOperationName -match $OperationName) {
            $CurrentValue = $ActivityLogAlert.value.properties.enabled
            if ($CurrentValue) {
                $CurrentValue = "True"
            }
            else {
                $CurrentValue = "False"
            }
        }
        $ControlResult = Set-ControlResultObject -CurrentValue $CurrentValue -ResourceName $SubscriptionId -ControlResult $ControlResult -PropertieToCheck "IsActivityLogAlertEnabled" -CompliantValue $CompliantValue -Subscription $SubscriptionId
    }
    return $ControlResult
}