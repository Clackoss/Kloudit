
function AzDefenderPricing {
    $Compliance = $true
    $res = Get-AzSecurityPricing | Where-Object { $_.Name -eq 'VirtualMachines' } | 
    Select-Object Name, PricingTier
    if ($res.PricingTier -ne "Standard") {
        $Compliance = $false
    }
    return $Compliance
}

