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
    $ControlResult = [PSCustomObject]@{
        Value      = ""
        Compliance = ""
    }
    $res = Get-AzSecurityPricing | Where-Object { $_.Name -eq $ResourceToCheck } | 
    Select-Object Name, PricingTier
    if ($res.PricingTier -ne "Standard") {
        $ControlResult.Value = $res.PricingTier
        $ControlResult.Compliance = "Uncompliant"
    }
    else {
        $ControlResult.Value = $res.PricingTier
        $ControlResult.Compliance = "Compliant"
    }
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
    $ControlResult = [PSCustomObject]@{
        Value      = $res.Enabled
        Compliance = "Compliant"
    }
    if ($res.Enabled -ne "True") {
        $ControlResult = "Uncompliant"
    }
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
    $ControlResult = [PSCustomObject]@{
        Value      = $Res.AutoProvision
        Compliance = "Compliant"
    }
    if ($Res.AutoProvision -ne "On") {
        $ControlResult.Compliance = "UnCompliant"
    }
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
    $Res = Get-AzPolicyAssignment | Where-Object { $_.Name -eq "SecurityCenterBuiltIn"}
    $ControlResult = [PSCustomObject]@{
        Value      = $Res.Properties.EnforcementMode
        Compliance = "Compliant"
    }
    if ($Res.Properties.EnforcementMode -ne "Default") {
        $ControlResult.Compliance = "Uncompliant"
    }
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
    $ControlResult = [PSCustomObject]@{
        Value      = $Res.Email
        Compliance = "Compliant"
    }
    if (($null -eq $Res.Email) -or ("" -eq $Res.Email)) {
        $ControlResult.Compliance = "Uncompliant"
    }
    return $ControlResult
}