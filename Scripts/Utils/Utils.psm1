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

function Format-HtmlTable {
    $HtmlPage = Get-content -path ./Web/initializer.html
    $AllData = Get-content -path ./Reports/AuditResult.json | Convertfrom-json
    $ElementToAdd = ""

    foreach ($Subscription in ($AllData | Get-Member -memberType NoteProperty).Name) {
        $ElementToAdd += "<h1>Subscription : " + $Subscription + "</h1>`n"

        foreach ($SubjectToControl in ($AllData.$Subscription | Get-Member -memberType NoteProperty).Name) {
            $ElementToAdd += "<h2>" + $SubjectToControl + "</h2><br>`n"
            
            foreach ($ControlPoint in ($AllData.$Subscription.$SubjectToControl | Get-Member -memberType NoteProperty).Name) {
                $split = $ControlPoint.Split(".",2)
                if ($split[1] -match "^0") {
                    $split[1] = $split[1].Replace("0","")
                }
                $PrintedControlPoint = $split[0] + "." + $split[1]
                $ElementToAdd += "<br><h3>" + $PrintedControlPoint + "</h3><br>`n"
                $ElementToAdd += "<table>`n<colgroup><col/><col/><col/><col/><col/></colgroup>`n"
                $ElementToAdd += "<tr><th>ResourceName</th><th>PropertieChecked</th><th>CompliantValue</th><th>CurrentValue</th><th>Compliance</th></tr>`n"

                foreach ($Resource in ($AllData.$Subscription.$SubjectToControl.$ControlPoint | Get-Member -memberType NoteProperty).Name) {
                    $ElementToAdd += "<tr><td>$($AllData.$Subscription.$SubjectToControl.$ControlPoint.$Resource.ResourceName)</td><td>$($AllData.$Subscription.$SubjectToControl.$ControlPoint.$Resource.PropertieChecked)</td><td>$($AllData.$Subscription.$SubjectToControl.$ControlPoint.$Resource.CompliantValue)</td><td>$($AllData.$Subscription.$SubjectToControl.$ControlPoint.$Resource.CurrentValue)</td><td>$($AllData.$Subscription.$SubjectToControl.$ControlPoint.$Resource.Compliance)</td></tr>`n"
                }

                $ElementToAdd += "</table>"
            }

        }
    }
    $HtmlPage = $HtmlPage -replace "DATAHERE", $ElementToAdd
    $HtmlPage | Set-Content -Path "./Web/index.html" -Force
}


<#
.SYNOPSIS
Sort the audit output
.DESCRIPTION
Sort the audit output
.OUTPUTS
[Pscustomobject] : the audit output
.NOTES
Author : Maxime BOUDIER
Version : 1.0.0
#>
function Sort-Audit {
    param (
        [Parameter(Mandatory = $true)][PSCustomObject]$Auditoutput
    )
    $SortedAuditOutput = [PSCustomObject]@{}
    


    return $SortedAuditOutput
}