function Write-Log()
{
    # Logging function - Write logging to screen and log file
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message
    )

    process
    {
        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host -Object "$date - $message"
    }
}
