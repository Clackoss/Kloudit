<#
.SYNOPSIS
Get the azure defender princing type for a ressource Type given
.DESCRIPTION
Used for CIS control point 2.1 to 2.8
.OUTPUTS
[Pscustomobject] : An object containing the value and the compliance of the control point
.EXAMPLE
Get-AzDefenderPricing -ResourceToCheck "VirtualMachines"
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
#>
function Get-MsDefenderIntegration {
    param (
        [Parameter(Mandatory = $true)][string]$IntegrationItem
    )
    $res = Get-AzSecuritySetting | Where-Object {($_.Id -like "*$IntegrationItem")}
    $ControlResult = [PSCustomObject]@{
        Value      = $res.Enabled
        Compliance = "Compliant"
    }
    if ($res.Enabled -ne "True") {
        $ControlResult = "Uncompliant"
    }
    return $ControlResult
}



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

