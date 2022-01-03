<#
.SYNOPSIS
Get some resource configuration properties for a given resource type
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
        #The compliant configuration Value
        [Parameter(Mandatory = $true)][string]$CompliantValue,
        #The resourceType audited
        [Parameter(Mandatory = $true)][string]$ResourceType,
        #The configuration audited
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        #If a sub function have to be used to access the ressource information
        [Parameter(Mandatory = $false)][string]$SubFunction
    )
    #Get all the resources of the type given
    $AllResourceByType = Get-AzResource -ResourceType $ResourceType -ExpandProperties
    $ControlResult = [PSCustomObject]@{
    }
    foreach ($ResourceByType in $AllResourceByType) {


        #TODO Check for subfunction
        #Check for subpropertie existence like "NetworkAcl.bypass"
        $CurrentValue = Check-SubPropertie -PropertieToCheck $PropertieToCheck -ResourceByType $ResourceByType


        $Resource = [PSCustomObject]@{
            ResourceName     = $ResourceByType.Name
            Subscription     = $ResourceByType.SubscriptionId
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


<#
.SYNOPSIS
Check if the propertie that must be check is composed of mutiple properties 
.DESCRIPTION
Check if the propertie that must be check is composed of mutiple properties (ex : NetworkAcls.Bypass)
.OUTPUTS
[String] : A string containing the current value checked of the resource
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Check-SubPropertie {
    param (
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        [Parameter(Mandatory = $true)][Object]$ResourceByType
    )
    $splitPropertie = $PropertieToCheck.Split(".")
        if ($null -ne $splitPropertie[1]) {
            $CurrentValue = $ResourceByType.Properties.($splitPropertie[0]).($splitPropertie[1])
        }
        else {
            $CurrentValue = $ResourceByType.Properties.$PropertieToCheck
        }
    return $CurrentValue
}