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

    #foreach ($Subscription in ($AllData | Get-Member -memberType NoteProperty).Name) {
        #$ElementToAdd += "<h1>Subscription : " + $Subscription + "</h1>`n"

        foreach ($SubjectToControl in ($AllData | Get-Member -memberType NoteProperty).Name) {
            $ElementToAdd += "<h2>" + $SubjectToControl + "</h2><br>`n"
            
            foreach ($ControlPoint in ($AllData.$SubjectToControl | Get-Member -memberType NoteProperty).Name) {
                $split = $ControlPoint.Split(".",2)
                if ($split[1] -match "^0") {
                    $split[1] = $split[1].Replace("0","")
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
    #}
    $HtmlPage = $HtmlPage -replace "DATAHERE", $ElementToAdd
    $HtmlPage | Set-Content -Path "./Web/index.html" -Force
}
