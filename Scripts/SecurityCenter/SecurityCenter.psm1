
function Get-AzDefenderPricing {
    param (
        # Resource To check the Azure defender pricing
        [Parameter(Mandatory = $true)][string]$ResourceToCheck
    )
    $Compliance = "Compliant"
    try {
        $res = Get-AzSecurityPricing | Where-Object { $_.Name -eq $ResourceToCheck } | 
        Select-Object Name, PricingTier
        if ($res.PricingTier -ne "Standard") {
            $Compliance = "Uncompliant"
        }
    }
    catch {
        $Compliance = "Impossible to access the information"
        return $Compliance
    }
    return $Compliance
}

