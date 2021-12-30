<#
.SYNOPSIS
Get some resource configuration properties
.DESCRIPTION
Used for CIS 3.1 - 3.2 - 3.5 - 3.6 - 3.7 - 3.12
.OUTPUTS
[Pscustomobject] : An object containing the value, the name and the compliance of the control point
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-ResourceProperties {
    param(
        [Parameter(Mandatory = $true)][string]$CompliantValue,
        [Parameter(Mandatory = $true)][string]$ResourceType,
        [Parameter(Mandatory = $true)][string]$PropertieToCheck
    )
    #Get all the resources of the type given
    $AllResourceByType = Get-AzResource -ResourceType $ResourceType -ExpandProperties
    $ControlResult = [PSCustomObject]@{
    }
    foreach ($ResourceByType in $AllResourceByType) {
        #Check for subpropertie existence like "NetworkAcl.bypass"
        $splitPropertie = $PropertieToCheck.Split(".")
        if ($null -ne $splitPropertie[1]) {
            $CurrentValue = $ResourceByType.Properties.($splitPropertie[0]).($splitPropertie[1])
        }
        else {
            $CurrentValue = $ResourceByType.Properties.$PropertieToCheck
        }
        $Resource = [PSCustomObject]@{
            ResourceName     = $ResourceByType.Name
            PropertieChecked = $PropertieToCheck
            CompliantValue   = $CompliantValue
            CurrentValue     = $CurrentValue
            Compliance       = "Compliant"
        }
        #Check for the compliance
        if ($CurrentValue -notmatch $CompliantValue) {
            $Resource.Compliance = "Uncompliant"
        }
        $ControlResult | Add-Member -MemberType NoteProperty -Name $ResourceByType.Name -Value $Resource
    }
    return $ControlResult   
}