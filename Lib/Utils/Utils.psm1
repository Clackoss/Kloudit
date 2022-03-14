<#
.SYNOPSIS
Connect to an azure account
.EXAMPLE
./login.ps1
#>
function Login {
    Write-Output "Connection to an Azure account"
    #Force Stop in case of error
    $ErrorActionPreference = "Stop"
    #Connect to Azure
    try {
        Connect-AzAccount
    }
    catch {
        Write-Host "Unable to connect to Azure.`nYou Should check the credentials used."
        throw
    }
    Write-Output "Connection successfully etablished`n"
}

<#
.SYNOPSIS
Get the Authentication Header to allow api call
.OUTPUTS
[Object] : Authentication Header to allow API call
.NOTES
Code get from Ms documentation
#>
function Get-ApiAuthHeader {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.AccessToken
    }
    return $authHeader    
}

<#
.SYNOPSIS
Format a powershell custom object to an html format table
.OUTPUTS
An html file with the html table in
#>
function Format-HtmlTable {
    param (
        [Parameter(Mandatory = $true)][string]$AuditSectionToPrint
    )
    $HtmlPage = Get-content -path "./Web/initializer.html"
    $AllData = Get-content -path "./Reports/$AuditSectionToPrint.json" | Convertfrom-json
    $ElementToAdd = ""

    foreach ($SubjectToControl in ($AllData | Get-Member -memberType NoteProperty).Name) {
        $ElementToAdd += "<br><h2>" + $SubjectToControl + "</h2>`n"
            
        foreach ($ControlPoint in ($AllData.$SubjectToControl | Get-Member -memberType NoteProperty).Name) {
            #Remove the 0 before control point number like "2.03"
            $split = $ControlPoint.Split(".", 2)
            if ($split[1] -match "^0") {
                $split[1] = $split[1].Replace("0", "")
            }
            $PrintedControlPoint = $split[0] + "." + $split[1]
            $ElementToAdd += "<br><h3>" + $PrintedControlPoint + "</h3><br>`n"
            $ElementToAdd += "<table class='rwd-table'>`n<colgroup><col/><col/><col/><col/><col/></colgroup>`n"
            $ElementToAdd += "<tr><th>ResourceName</th><th>SubscriptionId</th><th>PropertieChecked</th><th>CompliantValue</th><th>CurrentValue</th><th>Compliance</th></tr>`n"

            foreach ($Resource in ($AllData.$SubjectToControl.$ControlPoint | Get-Member -memberType NoteProperty).Name) {
                $ElementToAdd += "<tr><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.ResourceName)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.Subscription)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.PropertieChecked)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.CompliantValue)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.CurrentValue)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.Compliance)</td></tr>`n"
            }
            $ElementToAdd += "</table>"
        }
    }
    $HtmlPage = $HtmlPage -replace "DATAHERE", $ElementToAdd
    $HtmlPage | Set-Content -Path "./Web/$($AuditSectionToPrint).html" -Force
}

<#
.SYNOPSIS
Check if a resource config is compliant with the CIS recomandations
.OUTPUTS
[String] : Compliant/Uncompliant according to CIS Recomandations
#>
function Get-Compliance {
    param (
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CurrentValue,
        [Parameter(Mandatory = $true)][string]$CompliantValue
    )
    if (($CurrentValue -notmatch $CompliantValue) -or ($null -eq $CurrentValue)) {
        return "Uncompliant"
    }
    else {
        return "Compliant"
    }
}

<#
TODO : Change to remove Invoke-expression mechanism
.SYNOPSIS
Add a Cis control step and print the current check
.OUTPUTS
[PsCustomObject] : The dataobject that will be return the section main object
#>
function Add-CisControlSetp {
    param (
        [Parameter(Mandatory = $true)][PsCustomObject]$DataObject,
        [Parameter(Mandatory = $true)][array]$CISPoint,
        [Parameter(Mandatory = $true)][array]$PropertiesToCheck,
        [Parameter(Mandatory = $true)][array]$CompliantValues,
        [Parameter(Mandatory = $true)][string]$FunctionToCall,
        [Parameter(Mandatory = $true)][string]$ResourceType,
        [Parameter(Mandatory = $true)][string]$ControlName    
    )
    for ($i = 0; $i -lt $CISPoint.Count; $i++) {
        #Remplace the "Propertie" & "compliance" from the param to the correct values
        $ControlNameReplaced = $ControlName.Replace("Propertie", $($PropertiesToCheck[$i]))
        $ControlNameReplaced = $ControlNameReplaced.Replace("Compliant", $($CompliantValues[$i]))
        $ControlNameToPrint = $($CISPoint[$i]) + " " + $ControlNameReplaced
        $FunctionToCallWithParam = $FunctionToCall + " -PropertieToCheck $($PropertiesToCheck[$i]) -CompliantValue $($CompliantValues[$i])"
        $ControlData = Invoke-Expression $FunctionToCallWithParam
        try {
            $DataObject | Add-Member -MemberType NoteProperty -Name $ControlNameToPrint -Value $ControlData
        }
        catch {
            Write-Host "[Add-CisControlSetp] : Error while adding member to object"
            Write-Host "$($_.Exception.Message)"
            continue
        }     
        Write-Host "$ControlNameToPrint" -ForegroundColor Blue
        foreach ($Object in $DataObject.$ControlNameToPrint.Psobject.Properties) {
            Write-Host "$ResourceType : $($Object.Name) is : $($Object.Value.Compliance)"
        }
    }
    return $DataObject
}

<#
.SYNOPSIS
Set the object containing the result of the control for a unique resource
.OUTPUTS
[PsCustomObject] : The object containing the result of the control point for a resource
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Set-ControlResultObject {
    param (
        [Parameter(Mandatory = $true)][PscustomObject]$ControlResult,
        [Parameter(Mandatory = $true)][string]$PropertieToCheck,
        [Parameter(Mandatory = $true)][string]$CompliantValue,
        [Parameter(Mandatory = $true)][string][AllowEmptyString()]$CurrentValue,
        [Parameter(Mandatory = $true)][string]$ResourceName,
        [Parameter(Mandatory = $true)][string]$Subscription
    )
    #Get compliance of the control (Compliant/Uncompliant)
    $Compliance = Get-Compliance -CurrentValue $CurrentValue -CompliantValue $CompliantValue

    #Format value to delete Regex in Output
    if ($CompliantValue.Contains("/W")) {
        $CompliantValue = $CompliantValue.Replace("/W", "Not ")
    }
    if ($CurrentValue -eq "") {
        $CurrentValue = "Null"
    }
    
    $Resource = [PSCustomObject]@{
        ResourceName     = $ResourceName
        Subscription     = $Subscription
        PropertieChecked = $PropertieToCheck
        CompliantValue   = $CompliantValue
        CurrentValue     = $CurrentValue
        Compliance       = $Compliance
    }
    try {
        $ControlResult | Add-Member -MemberType NoteProperty -Name $Resource.ResourceName -Value $Resource
    }
    catch {
        Write-Host "An error has occured during control"
    }
    return $ControlResult 
}


<#
.SYNOPSIS
Get the audit result with only compliant or uncompliant data
.OUTPUTS
[PsCustomObject] : The object containing the datas of filtered
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-DataFilteredByCompliance {
    param (
        [Parameter(Mandatory = $true)][string]$ComplianceState
    )
    $AllData = Get-Content ./Reports/AuditResult.json | ConvertFrom-Json
    $SectionList = ($AllData | Get-Member -MemberType NoteProperty).Name
    foreach ($Section in $SectionList) {
        $AllControlPoint = ($AllData.$Section | Get-Member -memberType NoteProperty).Name
        foreach ($ControlPoint in $AllControlPoint) {
            $AllResources = ($AllData.$Section.$ControlPoint | Get-Member -memberType NoteProperty).Name
            foreach ($Resource in $AllResources) {
                if ($AllData.$Section.$ControlPoint.$Resource.Compliance -ne $ComplianceState) {
                    $AllData.$Section.$ControlPoint.PSobject.properties.Remove("$Resource")
                }
            }
        }
    }
    $AllData | ConvertTo-Json -Depth 20 | Set-Content "./Reports/$($ComplianceState).json" -Force
    Remove-NullControlPoint -DataToCheck "$($ComplianceState)"
}

<#
.SYNOPSIS
Get the audit result with only compliant or uncompliant data
.OUTPUTS
[PsCustomObject] : The object containing the datas of filtered
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Remove-NullControlPoint {
    param (
        [Parameter(Mandatory = $true)][string]$DataToCheck
    )
    $AllData = Get-Content "./Reports/$($DataToCheck).json" | ConvertFrom-Json
    $SectionList = ($AllData | Get-Member -MemberType NoteProperty).Name
    foreach ($Section in $SectionList) {
        $AllControlPoint = ($AllData.$Section | Get-Member -memberType NoteProperty).Name
        if ($null -eq $AllcontrolPoint) {
            $AllData.PsObject.Properties.Remove("$Section")
        }
        foreach ($ControlPoint in $AllControlPoint) {
            $AllResources = ($AllData.$Section.$ControlPoint | Get-Member -memberType NoteProperty).Name
            if ($null -eq $AllResources) {
                $AllData.$Section.PsObject.Properties.Remove("$ControlPoint")
            }
        }
    }
    $AllData | ConvertTo-Json -Depth 20 | Set-Content "./Reports/$($DataToCheck).json" -Force
}

<#
.SYNOPSIS
Get the count of compliant and Uncompliant resources for each Section
.OUTPUTS
[PsCustomObject] : The object containing the count of Compliant/Uncompliant for each
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Get-complianceCount {
    $StateToCheck = @("Compliant", "Uncompliant")
    $CountObject = [PSCustomObject]@{
        Compliant   = @{}
        Uncompliant = @{}
    }
    foreach ($State in $StateToCheck) {
        $AllData = Get-Content "./Reports/$($State).json" | ConvertFrom-Json
        $SectionList = ($AllData | Get-Member -MemberType NoteProperty).Name
        foreach ($Section in $SectionList) {
            $CountObject.$State | Add-Member -MemberType NoteProperty -Name $Section -Value 0
            $SectionStateCount = (($AllData.$Section | Get-Member -memberType NoteProperty).Name).Count
            $CountObject.$State.$Section = $SectionStateCount
            $TotalForState += $SectionStateCount
        }
        $CountObject.$State | Add-Member -MemberType NoteProperty -Name "Total" -Value $TotalForState
    }  
    return $CountObject
}