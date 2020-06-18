<#
    .SYNOPSIS
    Search for and view log files for DSC runs

    .DESCRIPTION
    Using this script you can search for log files of DSC runs. It lists all
    executed DSC jobs and then retrieves all log files for the job that is
    selected.

    .EXAMPLE
    Get-DscLog
#>

function Get-DscLogs
{
    [CmdletBinding()]
    param
    ()

    process
    {
        Write-Log -Message 'Get-DscLogs started'

        try
        {
            Write-Log -Message '  Retrieving all DSC jobs'
            $job = Get-DscConfigurationStatus -All -ErrorAction Stop | `
                    Select-Object -Property Status, `
                                            StartDate, `
                                            DurationInSeconds, `
                                            ResourcesNotInDesiredState, `
                                            Error, `
                                            Type, `
                                            Mode, `
                                            RebootRequested, `
                                            NumberOfResources | `
                    Out-GridView -PassThru -Title 'Please select the job you want to view the log for'

            if ($null -eq $job -or $job -is [System.Array])
            {
                Write-Log -Message '  You have selected $($job.Count) jobs. Please select one job only!'
            }
            else
            {
                Write-Log -Message "  Searching logs for job {$($job.JobID)}"
                $logFolder = 'C:\Windows\System32\Configuration\ConfigurationStatus'
                $logfiles = Get-ChildItem -Path $logFolder -Exclude "*.mof" | `
                             Where-Object -FilterScript { $_.Name -like "*$($job.JobID)*" }
                if ($logfiles -is [System.Array])
                {
                    $logfile = $logfiles | Sort-Object -Property LastWriteTime -Descending | `
                                Select-Object -Property Name, `
                                                        Length, `
                                                        LastWriteTime, `
                                                        CreationTime, `
                                                        @{ Name = 'Duration';  Expression = { [Math]::Round(($_.LastWriteTime - $_.CreationTime).TotalSeconds,1) }} | `
                                Out-GridView -PassThru -Title 'Please select the logfile you want to view'
                }
                else
                {
                    $logfile = $logfiles
                }

                if ($null -ne $logfile)
                {
                    Write-Log -Message "  Opening log for with name {$($logfile.Name)}"
                    $fullPath = Join-Path -Path $logFolder -ChildPath $logfile.Name

                    try
                    {
                        $content = Get-Content -Raw -Path $fullPath -Encoding Unicode -ErrorAction Stop
                        $json    = ConvertFrom-Json -InputObject $content
                        $json | Out-GridView
                    }
                    catch [System.IO.IOException]
                    {
                        Write-Log -Message ("Cannot access file $($logfile.Name) since the LCM is still running. Please wait for the LCM to complete!")
                    }
                }
                else
                {
                    Write-Log -Message 'Cancelled logfile selection process'
                }
            }
        }
        catch [Microsoft.Management.Infrastructure.CimException]
        {
            Write-Log -Message '  Cannot read log files while the LCM is working. Opening the most recent log using ShadowCopy!'
            Write-Log -Message '    NOTE: Since the LCM only flushes log entries periodically, this log might not be 100% complete/accurate!'

            $s1 = Invoke-CimMethod -ClassName 'Win32_ShadowCopy' `
                                   -MethodName 'Create' `
                                   -Arguments @{ Volume = 'C:\'; Context = 'ClientAccessible' }
            $s2 = Get-CimInstance -ClassName 'Win32_ShadowCopy' | Where-Object -FilterScript { $_.ID -eq $s1.ShadowID }
            $d  = $s2.DeviceObject + '\'
            cmd /c mklink /d C:\dsc_logs "$d" | Out-Null

            Start-Sleep -Seconds 2

            $scpath   = 'C:\dsc_logs\Windows\System32\Configuration\ConfigurationStatus'
            $logfile  = Get-ChildItem -Path $scpath -Filter *.json | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
            $fullPath = Join-Path -Path $scpath -ChildPath $logfile

            cmd /c notepad $fullPath

            $folder = Get-Item -Path 'C:\dsc_logs'
            $folder.Delete()

            $s2.Dispose()
            Write-Log -Message '  All ShadowCopies flushed'
        }
        Write-Log -Message 'Get-DscLogs completed'
    }
}
