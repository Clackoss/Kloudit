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
    Connect-AzAccount
    Write-Output "`n"
}

<#
.SYNOPSIS
Format a powershell custom object to an html format table
.DESCRIPTION
Format a powershell custom object to an html format table
.OUTPUTS
An html file with the html table in
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Format-HtmlTable {
    param (
        [Parameter(Mandatory = $true)][string]$AuditSectionToPrint
    )
    $HtmlPage = Get-content -path "./Web/initializer.html"
    $AllData = Get-content -path "./Reports/$AuditSectionToPrint.json" | Convertfrom-json
    $ElementToAdd = ""

    foreach ($SubjectToControl in ($AllData | Get-Member -memberType NoteProperty).Name) {
        $ElementToAdd += "<h2>" + $SubjectToControl + "</h2><br>`n"
            
        foreach ($ControlPoint in ($AllData.$SubjectToControl | Get-Member -memberType NoteProperty).Name) {
            #Remove the 0 before control point number like "2.03"
            $split = $ControlPoint.Split(".", 2)
            if ($split[1] -match "^0") {
                $split[1] = $split[1].Replace("0", "")
            }
            $PrintedControlPoint = $split[0] + "." + $split[1]
            $ElementToAdd += "<br><h3>" + $PrintedControlPoint + "</h3><br>`n"
            $ElementToAdd += "<table>`n<colgroup><col/><col/><col/><col/><col/></colgroup>`n"
            $ElementToAdd += "<tr><th>ResourceName</th><th>SubscriptionId</th><th>PropertieChecked</th><th>CompliantValue</th><th>CurrentValue</th><th>Compliance</th></tr>`n"

            foreach ($Resource in ($AllData.$SubjectToControl.$ControlPoint | Get-Member -memberType NoteProperty).Name) {
                $ElementToAdd += "<tr><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.ResourceName)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.Subscription)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.PropertieChecked)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.CompliantValue)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.CurrentValue)</td><td>$($AllData.$SubjectToControl.$ControlPoint.$Resource.Compliance)</td></tr>`n"
            }

            $ElementToAdd += "</table>"
        }

    }
    $HtmlPage = $HtmlPage -replace "DATAHERE", $ElementToAdd
    $HtmlPage | Set-Content -Path "./Web/index.html" -Force
}


function Format-HtmlTable2 {
    param (
        [Parameter(Mandatory = $true)][string]$AuditSectionToPrint
    )
    $HtmlPage = Get-content -path "./Web/initializer2.html"
    $AllData = Get-content -path "./Reports/$AuditSectionToPrint.json" | Convertfrom-json
    $ElementToAdd = ""

    foreach ($SubjectToControl in ($AllData | Get-Member -memberType NoteProperty).Name) {
        $ElementToAdd += "<h2>" + $SubjectToControl + "</h2><br>`n"
            
        foreach ($ControlPoint in ($AllData.$SubjectToControl | Get-Member -memberType NoteProperty).Name) {
            #Remove the 0 before control point number like "2.03"
            $split = $ControlPoint.Split(".", 2)
            if ($split[1] -match "^0") {
                $split[1] = $split[1].Replace("0", "")
            }
            $PrintedControlPoint = $split[0] + "." + $split[1]
            $ElementToAdd += "<br><h3>" + $PrintedControlPoint + "</h3><br>`n"
            $ElementToAdd += "<table class='rwd-table'>`n<tr>"
            
            $FistResource = ($AllData.$SubjectToControl.$ControlPoint | Get-Member -memberType NoteProperty).Name
           
            
            if ($FirstResource.GetType().Name -match "Object") {
                $FistResource = $FistResource[0]
            }
            foreach ($TableColumn in ($AllData.$SubjectToControl.$ControlPoint.$FistResource | Get-Member -memberType NoteProperty).Name) {
                $ElementToAdd += "<th>$TableColumn</th>"
                $AllColumn += $TableColumn #TODO fix foreach
            }
            $ElementToAdd += "</tr>`n<tr>"
            foreach ($Resource in ($AllData.$SubjectToControl.$ControlPoint | Get-Member -memberType NoteProperty).Name) {
                foreach ($TableColumn in ($AllData.$SubjectToControl.$ControlPoint.$Resource | Get-Member -memberType NoteProperty).Name) {
                    $ElementToAdd += "<td data-th='$($TableColumn)'>$($AllData.$SubjectToControl.$ControlPoint.$Resource.$TableColumn)</td>"
                }
            }
            $ElementToAdd += "</tr>"
            $ElementToAdd += "</table>"
        }

    }
    $HtmlPage = $HtmlPage -replace "DATAHERE", $ElementToAdd
    $HtmlPage | Set-Content -Path "./Web/index.html" -Force
}


<#
.SYNOPSIS
Check if a resource config is compliant with the CIS recomandations
.OUTPUTS
[String] : Compliant/Uncompliant according to CIS Recomandations
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Check-Compliance {
    param (
        [Parameter(Mandatory = $true)][string]$CurrentValue,
        [Parameter(Mandatory = $true)][string]$CompliantValue
    )
    if ($CurrentValue -notmatch $CompliantValue) {
        return "Uncompliant"
    }
    else {
        return "Compliant"
    }
}

<#
.SYNOPSIS
Add a Cis control step and print the current check
.OUTPUTS
[PsCustomObject] : The dataobject that will be return the section main object
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
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
        $ControlName = $ControlName.Replace("Propertie", $PropertiesToCheck[$i])
        $ControlName = $ControlName.Replace("Compliant", $CompliantValues[$i])
        $ControlNameToPrint = $($CISPoint[$i]) + " " + $ControlName
        #$ControlName = "$($CISPoint[$i]) Ensure that [$($PropertiesToCheck[$i])] is set to [$($CompliantValues[$i])]"
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