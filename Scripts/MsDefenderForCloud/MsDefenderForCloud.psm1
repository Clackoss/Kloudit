<#
.SYNOPSIS
Call and print the audit actions for MsDefenderForcloud section
.DESCRIPTION
Call and print the audit actions for MsDefenderForcloud section
.OUTPUTS
[Pscustomobject] : An object containing the result of the audit for Msdefenderforcloud section
.EXAMPLE
Start-MsDefenderForCloudAudit
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Start-AuditMsDefenderForCloud {
    param(
        [Parameter(Mandatory = $true)][Object]$SubscriptionList
    )

    $MsDefenderForCloud = [PSCustomObject]@{}
    Write-Host "`n**Checking Microsoft Defender for cloud configurations**`n" -ForegroundColor DarkMagenta

    foreach ($Subscription in $SubscriptionList) {
        $SubscriptionName = $Subscription.Name
        $SubscriptionId = $Subscription.Id
        Set-AzContext -Subscription $SubscriptionId | Out-null

        Write-Host "`nCheck compliance for MsDefenderForCloud on subscription [$SubscriptionName] : [$SubscriptionId]" -ForegroundColor Cyan
        
    
        ##Check for Security Center Recomandations##
        
        #2.1 - 2.2 - 2.3 - 2.4 - 2.5 - 2.6 - 2.7 - 2.8 : Check for Security Center enablement
        $cpt = 0
        $AllResourcesToCheck = @('VirtualMachines', 'AppServices', 'SqlServers', 'SqlServerVirtualMachines', 'StorageAccounts', 'KubernetesService', 'ContainerRegistry', 'KeyVaults')
        foreach ($ResourceToCheck in $AllResourcesToCheck) {
            $cpt++
            $AzureDefenderPricing = Get-AzDefenderPricing -ResourceToCheck $ResourceToCheck
            $ControlName = "2.0$cpt Ensure that Azure Defender is set to On for $ResourceToCheck" 
            $MsDefenderForCloud | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderPricing -Force
            Write-Host "$ControlName is : $($MsDefenderForCloud.$ControlName.$SubscriptionId.Compliance)" 
        }

        #2.9 - 2.10 Ensure that Microsoft Defender for Endpoint/cloud (WDATP & MCAS) integration with Microsoft Defender for Cloud is selected
        $AllResourcesToCheck = @("WDATP", "MCAS")
        foreach ($ResourceToCheck in $AllResourcesToCheck) {
            $cpt++
            $AzureDefenderIntegration = Get-MsDefenderIntegration -IntegrationItem $ResourceToCheck
            $ControlName = "2.$cpt Ensure that Microsoft Defender for Endpoint ($ResourceToCheck) integraiton is selected" 
            $MsDefenderForCloud | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AzureDefenderIntegration -Force
            Write-Host "$ControlName is : $($MsDefenderForCloud.$ControlName.$SubscriptionId.Compliance)" 
        }


        #2.11 Ensure That Auto provisioning of 'Log Analytics agent for Azure VMs is Set to On
        $ControlName = "2.11 Ensure That Auto provisioning of Log Analytics agent for Azure VMs is Set to On"
        $AutoProvisioning = Get-AutoProvisioning
        $MsDefenderForCloud | Add-Member -MemberType NoteProperty -Name $ControlName -Value $AutoProvisioning -Force
        Write-Host "$ControlName is : $($MsDefenderForCloud.$ControlName.$SubscriptionId.Compliance)" 

        #2.12 Ensure Any of the ASC Default Policy Setting is Not Set to 'Disabled'
        $ControlName = "2.12 Ensure Any of the ASC Default Policy Setting is Not Set to Disabled"
        $ASCPolicyState = Get-ASCPolicyState
        $MsDefenderForCloud | Add-Member -MemberType NoteProperty -Name $ControlName -Value $ASCPolicyState -Force
        Write-Host "$ControlName is : $($MsDefenderForCloud.$ControlName.$SubscriptionId.Compliance)" 

        #2.13 Ensure 'Additional email addresses' is Configured with a Security Contact Email
        $ControlName = "2.13 Ensure 'Additional email addresses' is Configured with a Security Contact Email"
        $SecurityEmail = Get-SecurityContact
        $MsDefenderForCloud | Add-Member -MemberType NoteProperty -Name $ControlName -Value $SecurityEmail -Force
        Write-Host "$ControlName is : $($MsDefenderForCloud.$ControlName.$SubscriptionId.Compliance)" 

        #2.14
        #2.15
    }
    Return $MsDefenderForCloud
}

<#
.SYNOPSIS
Get the azure defender princing type for a ressource Type given
.DESCRIPTION
Used for CIS control point 2.1 to 2.8
.OUTPUTS
[Pscustomobject] : An object containing the value and the compliance of the control point
.EXAMPLE
Get-AzDefenderPricing -ResourceToCheck "VirtualMachines"
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-AzDefenderPricing {
    param (
        # Resource To check the Azure defender pricing
        [Parameter(Mandatory = $true)][string]$ResourceToCheck
    )
    $ControlResult = [PSCustomObject]@{}
    #the the pricing tier for the given resource type
    $PricingTier = Get-AzSecurityPricing | Where-Object { $_.Name -eq $ResourceToCheck } | Select-Object Id, Name, PricingTier
    $Subscription = ($PricingTier.id -split ("/"))[2] 
    $ControlResult = Set-ControlResultObject -CurrentValue $PricingTier.PricingTier -ResourceName $Subscription -ControlResult $ControlResult -PropertieToCheck "Pricing Tier" -CompliantValue "Standard" -Subscription $Subscription
    return $ControlResult
}

<#
.SYNOPSIS
Get the azure defender Integration status
.DESCRIPTION
Used for CIS control point 2.9 and 2.10
.OUTPUTS
[Pscustomobject] : An object containing the value and the compliance of the control point
.EXAMPLE
Get-MsDefenderIntegration -IntegrationItem "WDATP"
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-MsDefenderIntegration {
    param (
        [Parameter(Mandatory = $true)][string]$IntegrationItem
    )
    $res = Get-AzSecuritySetting | Where-Object { ($_.Id -like "*$IntegrationItem") }
    $ControlResult = [PSCustomObject]@{}
    $Subscription = ($res.id -split ("/"))[2] 
    $ControlResult = Set-ControlResultObject -CurrentValue $res.Enabled -ResourceName $Subscription -ControlResult $ControlResult -PropertieToCheck $IntegrationItem -CompliantValue "True" -Subscription $Subscription
    return $ControlResult
}


<#
.SYNOPSIS
Get the azure defender log analystics automatic provisionning state
.DESCRIPTION
Used for CIS control point 2.11
.OUTPUTS
[Pscustomobject] : An object containing the value and the compliance of the control point
.EXAMPLE
Get-AutoProvisioning
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-AutoProvisioning {
    $Res = Get-AzSecurityAutoProvisioningSetting
    $ControlResult = [PSCustomObject]@{}
    $Subscription = ($Res.id -split ("/"))[2] 
    $ControlResult = Set-ControlResultObject -CurrentValue $Res.AutoProvision -ResourceName $Subscription -ControlResult $ControlResult -PropertieToCheck "AutoProvision" -CompliantValue "On" -Subscription $Subscription
    return $ControlResult
}

<#
.SYNOPSIS
Get the default policy initiative ASC
.DESCRIPTION
Used for CIS control point 2.12
.OUTPUTS
[Pscustomobject] : An object containing the value and the compliance of the control point
.EXAMPLE
Get-ASCPolicyState
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-ASCPolicyState {
    $WarningPreference = "SilentlyContinue"
    try {
        $Res = Get-AzPolicyAssignment | Where-Object { $_.Name -eq "SecurityCenterBuiltIn" }
    }
    catch {
        Write-Host "Enable to Get ASCPolicyState"
    }
    $ControlResult = [PSCustomObject]@{}
    $Subscription = $Res.SubscriptionId
    $ControlResult = Set-ControlResultObject -CurrentValue $Res.Properties.EnforcementMode -ResourceName $Subscription -ControlResult $ControlResult -PropertieToCheck "EnforcementMode" -CompliantValue "Default" -Subscription $Subscription
    return $ControlResult
}


<#
.SYNOPSIS
Get the azure defender princing security contact ($null if no contact)
.DESCRIPTION
Used for CIS control point 2.13
.OUTPUTS
[Pscustomobject] : An object containing the value and the compliance of the control point
.EXAMPLE
Get-SecurityContact
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-SecurityContact {
    $Res = Get-AzSecurityContact
    $ControlResult = [PSCustomObject]@{}
    $Subscription = ($Res.id -split ("/"))[2]
    if ($Res.Email -eq "") {
        $SecurityContact = "Null"
    }
    $ControlResult = Set-ControlResultObject -CurrentValue $SecurityContact -ResourceName $Subscription -ControlResult $ControlResult -PropertieToCheck "Email" -CompliantValue "/WNull" -Subscription $Subscription
    return $ControlResult
}