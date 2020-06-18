function Add-EventLogItem
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Source,

        [Parameter()]
        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
        [System.String]
        $EntryType = 'Information',

        [Parameter()]
        [System.String]
        $LogName = 'Application',

        [Parameter()]
        [System.UInt32]
        $EventID = 1
    )

    process
    {
        Write-Log -Message "  Adding item to Event Log {$LogName}"
        Write-Log -Message "    Checking Source {$Source}"
        if (Confirm-SourceExists -Source $Source)
        {
            Write-Log -Message '    Source exists, checking in which log'
            $sourceLogName = Get-LogNameFromSource -Source $Source
            if ($LogName -ne $sourceLogName)
            {
                Write-Log -Message "  [ERROR] Specified source {$Source} already exists on log {$sourceLogName}"
                return
            }
        }
        else
        {
            if ((Confirm-LogExists -LogName $LogName) -eq $false)
            {
                Write-Log -Message '    Creating event log'
                $null = New-EventLog -LogName $LogName -Source $Source
            }
            else
            {
                Write-Log -Message '    Creating specified source in log'
                New-EventSource -Source $Source -LogName $LogName
            }
        }

        try
        {
            Write-Log -Message '    Writing item to event log'
            Write-EventLog -LogName $LogName `
                           -Source $Source `
                           -EventID $EventID `
                           -Message $Message `
                           -EntryType $EntryType `
                           -ErrorAction SilentlyContinue
        }
        catch
        {
            Write-Log -Message "  [ERROR] Error while writing item to event log: $($_.Exception.Message)"
        }
        Write-Log -Message '  Completed adding item to Event Log'
    }
}

function Confirm-SourceExists()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Source
    )

    return [System.Diagnostics.EventLog]::SourceExists($Source)
}

function Confirm-LogExists()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    return [System.Diagnostics.EventLog]::Exists($LogName)
}

function Get-LogNameFromSource()
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Source
    )

    return [System.Diagnostics.EventLog]::LogNameFromSourceName($Source,".")
}

function New-EventSource()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Source,

        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    [System.Diagnostics.EventLog]::CreateEventSource($Source, $LogName)
}
