function Get-DscServerCompliancy()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SmtpServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailFrom,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailTo,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Servers
    )

    process
    {
        Write-Log -Message "Get-DscServerCompliancy started"

        $date = Get-Date -Format "yyyy-MM-dd"

        $analysis = "<html>`r`n<head>`r`n  <title>DSC Compliancy Report - $date</title>`r`n"
        $analysis += "<style>table, th, td { border: 1px solid black; border-collapse: collapse; } th, td { padding: 10px; } th { background-color: #f1f1c1; } .failed { background-color: red; }</style>"
        $analysis += "</head>`r`n<body>`r`n"

        $analysis += "<h2>DSC Compliancy Report - $date</h2>`r`n"

        $analysis += "<table>`r`n<tr><th>Server</th><th>Start Time</th><th>In Desired State</th><th>Failing Resource</th></tr>`r`n"

        foreach ($server in $Servers)
        {
            Write-Log -Message "  Processing $server"
            $start = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            try
            {
                $results = Test-DscConfiguration -ComputerName $server -Detailed -ErrorAction Stop

                if ($results.InDesiredState)
                {
                    Write-Log -Message "    Server in desired state"
                    $analysis += "<tr><td>$($results.PSComputerName)</td><td>$start</td><td>Yes</td><td>None</td></tr>`r`n"
                }
                else
                {
                    Write-Log -Message "    Server NOT in desired state ($($results.ResourcesNotInDesiredState.Count) resources not compliant)"
                    $analysis += "<tr><td>$($results.PSComputerName)</td><td>$start</td><td class=failed align='center'>No</td><td>$($results.ResourcesNotInDesiredState.ResourceId -join "<br />`r`n")</td></tr>`r`n"
                }
            }
            catch
            {
                Write-Log -Message "    [ERROR] Could not check server. Reason: $($_.Exception.Message)"
                $analysis += "<tr><td>$($results.PSComputerName)</td><td>$start</td><td class=failed align='center'>ERROR</td><td>$($_.Exception.Message)</td></tr>`r`n"
            }
        }
        $analysis += "</table>`r`n`r`n"
        $analysis += "</body>`r`n</html>`r`n"

        $source = 'Get-DscServerCompliancy'
        try
        {
            Write-Log -Message "  Sending report via email"
            Send-MailMessage -SmtpServer $SmtpServer -Subject "DSC Compliancy Report - $date" -From $MailFrom -To $MailTo -Body $analysis -BodyAsHtml -ErrorAction Stop

            Write-Log -Message "Get-DscServerCompliancy completed successfully"
        }
        catch
        {
            Add-EventLogItem -LogName 'Application' `
                            -Source $source `
                            -EventID 200 `
                            -Message "Get-DscServerCompliancy failed with error message {$($_.Exception.Message)}" `
                            -EntryType Error
            Write-Log -Message "Get-DscServerCompliancy failed with error message {$($_.Exception.Message)}"
        }
    }
}
