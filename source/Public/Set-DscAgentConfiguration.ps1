<#
    .SYNOPSIS
    Configure

    .DESCRIPTION
    Using this script you can search for log files of DSC runs. It lists all
    executed DSC jobs and then retrieves all log files for the job that is
    selected.

    .EXAMPLE
    Get-DscLog

    https://docs.microsoft.com/en-us/powershell/scripting/dsc/managing-nodes/metaconfig?view=powershell-7
    https://docs.microsoft.com/en-us/powershell/scripting/dsc/pull-server/pullclientconfignames?view=powershell-7
#>

function Set-DscAgentConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ServerName = 'localhost',

        [Parameter()]
        [System.String]
        $CertificateSubject,

        [Parameter()]
        [ValidateSet('ContinueConfiguration','StopConfiguration')]
        [System.String]
        $ActionAfterReboot,

        [Parameter()]
        [ValidateSet('ApplyOnly','ApplyAndMonitor','ApplyAndAutoCorrect')]
        [System.String]
        $ConfigurationMode,

        [Parameter()]
        [ValidateRange(5,3600)]
        [System.UInt32]
        $ConfigurationModeFrequencyMins,

        [Parameter()]
        [ValidateSet('Disabled', 'Push', 'Pull')]
        [System.String]
        $RefreshMode,

        [Parameter()]
        [ValidateRange(5,3600)]
        [System.UInt32]
        $RefreshFrequencyMins,

        [Parameter()]
        [System.String]
        $ConfigurationID,

        [Parameter()]
        [System.Boolean]
        $RebootNodeIfNeeded,

        [Parameter()]
        [System.String]
        $ConfigRepoServerUrl,

        [Parameter()]
        [System.String]
        $ConfigRepoRegistrationKey,

        [Parameter()]
        [System.String]
        $ConfigRepoSourcePath,

        [Parameter()]
        [System.String]
        $ResourceRepoServerUrl,

        [Parameter()]
        [System.String]
        $ResourceRepoRegistrationKey,

        [Parameter()]
        [System.String]
        $ResourceRepoSourcePath,

        [Parameter()]
        [System.String]
        $ReportServerUrl,

        [Parameter()]
        [System.String]
        $ReportRegistrationKey
    )

    Write-Log -Message 'Set-DscAgentConfiguration started'

    Write-Log -Message '  Generating DSC configuration.'
    $LCMConfigContent = [System.Text.StringBuilder]::new()
    [void]$LCMConfigContent.AppendLine("    [DSCLocalConfigurationManager()]")
    [void]$LCMConfigContent.AppendLine("    Configuration DscAgentConfig")
    [void]$LCMConfigContent.AppendLine("    {")
    [void]$LCMConfigContent.AppendLine("        Node $ServerName")
    [void]$LCMConfigContent.AppendLine("        {")
    [void]$LCMConfigContent.AppendLine("            Settings")
    [void]$LCMConfigContent.AppendLine("            {")

    if ($PSBoundParameters.ContainsKey("CertificateSubject"))
    {
        Write-Verbose -Message "Checking DSC Encryption certificate"
        $thumbprint = New-DscEncryptionCertificate -Server $ServerName `
                                                   -CertificateSubject $CertificateSubject

        Write-Verbose -Message "Using DSC Encryption certificate with thumbprint {$thumbprint}"
        [void]$LCMConfigContent.AppendLine("                CertificateID = '$thumbprint'")
    }

    if ($PSBoundParameters.ContainsKey("ActionAfterReboot"))
    {
        [void]$LCMConfigContent.AppendLine("                ActionAfterReboot = '$ActionAfterReboot'")
    }

    if ($PSBoundParameters.ContainsKey("ConfigurationMode"))
    {
        [void]$LCMConfigContent.AppendLine("                ConfigurationMode = '$ConfigurationMode'")
    }

    if ($PSBoundParameters.ContainsKey("ConfigurationModeFrequencyMins"))
    {
        [void]$LCMConfigContent.AppendLine("                ConfigurationModeFrequencyMins = '$ConfigurationModeFrequencyMins'")
    }

    if ($PSBoundParameters.ContainsKey("RefreshMode"))
    {
        [void]$LCMConfigContent.AppendLine("                RefreshMode = '$RefreshMode'")
    }

    if ($PSBoundParameters.ContainsKey("RefreshFrequencyMins"))
    {
        [void]$LCMConfigContent.AppendLine("                RefreshFrequencyMins = '$RefreshFrequencyMins'")
    }

    if ($PSBoundParameters.ContainsKey("ConfigurationID"))
    {
        [void]$LCMConfigContent.AppendLine("                ConfigurationID = '$ConfigurationID'")
    }

    if ($PSBoundParameters.ContainsKey("RebootNodeIfNeeded"))
    {
        [void]$LCMConfigContent.AppendLine("                RebootNodeIfNeeded = `$$RebootNodeIfNeeded")
    }

    [void]$LCMConfigContent.AppendLine("            }")

    if ($PSBoundParameters.ContainsKey("RefreshMode") -and $RefreshMode -eq "Pull")
    {
        if ($PSBoundParameters.ContainsKey("ConfigRepoSourcePath") -eq $true -or `
            $PSBoundParameters.ContainsKey("ConfigRepoServerUrl") -eq $true -or
            $PSBoundParameters.ContainsKey("ConfigRepoRegistrationKey") -eq $true)
        {
            if ($PSBoundParameters.ContainsKey("ConfigRepoSourcePath") -eq $true -and `
                ($PSBoundParameters.ContainsKey("ConfigRepoServerUrl") -eq $true -or
                 $PSBoundParameters.ContainsKey("ConfigRepoRegistrationKey") -eq $true))
            {
                throw "You cannot specify ConfigRepoSourcePath with ConfigRepoServerUrl or ConfigRepoRegistrationKey"
            }

            if ($PSBoundParameters.ContainsKey("ConfigRepoServerUrl") -eq $false -and
                    $PSBoundParameters.ContainsKey("ConfigRepoRegistrationKey") -eq $true)
            {
                throw "You have to specify ConfigRepoServerUrl with ConfigRepoRegistrationKey"
            }

            if ($PSBoundParameters.ContainsKey("ConfigRepoServerUrl") -eq $true -and
                    $PSBoundParameters.ContainsKey("ConfigRepoRegistrationKey") -eq $false)
            {
                throw "You have to specify ConfigRepoRegistrationKey with ConfigRepoServerUrl"
            }

            [void]$LCMConfigContent.AppendLine("")
            if ($PSBoundParameters.ContainsKey("ConfigRepoSourcePath") -eq $false)
            {
                # Use Web
                [void]$LCMConfigContent.AppendLine("            ConfigurationRepositoryWeb 'HTTPConfigurationServer'")
                [void]$LCMConfigContent.AppendLine("            {")
                [void]$LCMConfigContent.AppendLine("                ServerUrl          = $ConfigRepoServerUrl")
                [void]$LCMConfigContent.AppendLine("                RegistrationKey    = $ConfigRepoRegistrationKey")
                [void]$LCMConfigContent.AppendLine("                ConfigurationNames = $ConfigurationNames")
                [void]$LCMConfigContent.AppendLine("            }")
            }
            else
            {
                # Use Share
                [void]$LCMConfigContent.AppendLine("            ConfigurationRepositoryShare 'SMBConfigurationServer'")
                [void]$LCMConfigContent.AppendLine("            {")
                [void]$LCMConfigContent.AppendLine("                SourcePath = $ConfigRepoSourcePath")
                [void]$LCMConfigContent.AppendLine("            }")
            }

        }

        if ($PSBoundParameters.ContainsKey("ResourceRepoSourcePath") -eq $true -or `
            $PSBoundParameters.ContainsKey("ResourceRepoServerUrl") -eq $true -or
            $PSBoundParameters.ContainsKey("ResourceRepoRegistrationKey") -eq $true)
        {
            if ($PSBoundParameters.ContainsKey("ResourceRepoSourcePath") -eq $true -and `
                ($PSBoundParameters.ContainsKey("ResourceRepoServerUrl") -eq $true -or
                $PSBoundParameters.ContainsKey("ResourceRepoRegistrationKey") -eq $true))
            {
                throw "You cannot specify ResourceRepoSourcePath with ResourceRepoServerUrl or ResourceRepoRegistrationKey"
            }

            if ($PSBoundParameters.ContainsKey("ResourceRepoServerUrl") -eq $false -and
                $PSBoundParameters.ContainsKey("ResourceRepoRegistrationKey") -eq $true)
            {
                throw "You have to specify ResourceRepoServerUrl with ResourceRepoRegistrationKey"
            }

            if ($PSBoundParameters.ContainsKey("ResourceRepoServerUrl") -eq $true -and
                $PSBoundParameters.ContainsKey("ResourceRepoRegistrationKey") -eq $false)
            {
                throw "You have to specify ResourceRepoRegistrationKey with ResourceRepoServerUrl"
            }

            [void]$LCMConfigContent.AppendLine("")
            if ($PSBoundParameters.ContainsKey("ResourceRepoSourcePath") -eq $false)
            {
                # Use Web
                [void]$LCMConfigContent.AppendLine("            ResourceRepositoryWeb 'HTTPResourceServer'")
                [void]$LCMConfigContent.AppendLine("            {")
                [void]$LCMConfigContent.AppendLine("                ServerUrl       = $ResourceRepoServerUrl")
                [void]$LCMConfigContent.AppendLine("                RegistrationKey = $ResourceRepoRegistrationKey")
                [void]$LCMConfigContent.AppendLine("            }")
            }
            else
            {
                # Use Share
                [void]$LCMConfigContent.AppendLine("            ResourceRepositoryShare 'SMBResourceServer'")
                [void]$LCMConfigContent.AppendLine("            {")
                [void]$LCMConfigContent.AppendLine("                SourcePath = $ResourceRepoSourcePath")
                [void]$LCMConfigContent.AppendLine("            }")
            }
        }

        if ($PSBoundParameters.ContainsKey("ReportServerUrl") -eq $true -or
            $PSBoundParameters.ContainsKey("ReportRegistrationKey") -eq $true)
        {
            if ($PSBoundParameters.ContainsKey("ReportServerUrl") -eq $false -or
                $PSBoundParameters.ContainsKey("ReportRegistrationKey") -eq $false)
            {
                throw "You have to specify both ReportServerUrl and ReportRegistrationKey"
            }

            [void]$LCMConfigContent.AppendLine("")
            [void]$LCMConfigContent.AppendLine("            ReportServerWeb 'HTTPReportServer'")
            [void]$LCMConfigContent.AppendLine("            {")
            [void]$LCMConfigContent.AppendLine("                ServerUrl       = $ReportServerUrl")
            [void]$LCMConfigContent.AppendLine("                RegistrationKey = $ReportRegistrationKey")
            [void]$LCMConfigContent.AppendLine("            }")
        }
    }

    [void]$LCMConfigContent.AppendLine("        }")
    [void]$LCMConfigContent.AppendLine("    }")
    [void]$LCMConfigContent.AppendLine("    DscAgentConfig | Out-Null")
    [void]$LCMConfigContent.AppendLine("    Set-DSCLocalConfigurationManager -Path 'DscAgentConfig' -ComputerName $ServerName")

    Write-Log -Message "  Configuration generated: $($LCMConfigContent.ToString())"
    Write-Log -Message '  Deploying configuration.'
    $sb = [Scriptblock]::Create($LCMConfigContent.ToString())
    Invoke-Command -ScriptBlock $sb

    Write-Log -Message '  Performing clean up of temporary data'
    Remove-Item -Path "./DscAgentConfig" -Recurse -Confirm:$false

    Write-Log -Message 'Set-DscAgentConfiguration completed'
}
