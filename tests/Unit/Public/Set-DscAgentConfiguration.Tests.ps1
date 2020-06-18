[CmdletBinding()]
param
()

$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName -Force

InModuleScope -ModuleName $ProjectName -Scriptblock {
    Describe 'Set-DscAgentConfiguration' {
        BeforeAll {
            # Mocks for all context blocks. Avoid if possible.
        }

        # Context block cannot always be used.
        Context 'Function runs as expected' {
            BeforeAll {
                Mock -CommandName 'New-DscEncryptionCertificate' -MockWith {
                    return '1125FF7FE5BDA96715C343E066025E0504A3234C'
                }

                Mock -CommandName 'Set-DSCLocalConfigurationManager' -MockWith { $global:generatedSB = $sb.ToString() }
                Mock -CommandName 'Remove-Item' -MockWith { }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should successfully generate and execute the scriptblock' {
                $testparams = @{
                    ServerName                     = 'localhost'
                    CertificateSubject             = 'DSCEncryptionCert'
                    ActionAfterReboot              = 'ContinueConfiguration'
                    ConfigurationMode              = 'ApplyAndAutoCorrect'
                    ConfigurationModeFrequencyMins = 15
                    RefreshMode                    = 'Push'
                    RefreshFrequencyMins           = 45
                    ConfigurationID                = '98d4c423-fd3e-4fef-ae80-2b3a7b685c85'
                    RebootNodeIfNeeded             = $true
                }

                $result = @"
    [DSCLocalConfigurationManager()]
    Configuration DscAgentConfig
    {
        Node localhost
        {
            Settings
            {
                CertificateID = '1125FF7FE5BDA96715C343E066025E0504A3234C'
                ActionAfterReboot = 'ContinueConfiguration'
                ConfigurationMode = 'ApplyAndAutoCorrect'
                ConfigurationModeFrequencyMins = '15'
                RefreshMode = 'Push'
                RefreshFrequencyMins = '45'
                ConfigurationID = '98d4c423-fd3e-4fef-ae80-2b3a7b685c85'
                RebootNodeIfNeeded = `$True
            }
        }
    }
    DscAgentConfig | Out-Null
    Set-DSCLocalConfigurationManager -Path 'DscAgentConfig' -ComputerName localhost

"@
                Set-DscAgentConfiguration @testparams
                $global:generatedSB | Should -Be $result
                Assert-MockCalled -CommandName Set-DscLocalConfigurationManager -Times 1
            }
        }

        Context 'Checking invalid ConfigRepo* parameter values' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Parameter ConfigRepoSourcePath is specified with ConfigRepoServerUrl. Should throw an exception' {
                $testparams = @{
                    RefreshMode          = 'Pull'
                    ConfigRepoSourcePath = '\\server\share'
                    ConfigRepoServerUrl  = 'https://www.domain.com/service.svc'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You cannot specify ConfigRepoSourcePath with ConfigRepoServerUrl or ConfigRepoRegistrationKey'
            }

            It 'Parameter ConfigRepoRegistrationKey is specified, but ConfigRepoServerUrl is missing. Should throw an exception' {
                $testparams = @{
                    RefreshMode               = 'Pull'
                    ConfigRepoRegistrationKey = 'abcdefghij'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You have to specify ConfigRepoServerUrl with ConfigRepoRegistrationKey'
            }

            It 'Parameter ConfigRepoServerUrl is specified, but ConfigRepoRegistrationKey is missing. Should throw an exception' {
                $testparams = @{
                    RefreshMode          = 'Pull'
                    ConfigRepoServerUrl  = 'https://www.domain.com/service.svc'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You have to specify ConfigRepoRegistrationKey with ConfigRepoServerUrl'
            }
        }

        Context 'Checking invalid ResourceRepo* parameter values' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Parameter ResourceRepoSourcePath is specified with ResourceRepoServerUrl. Should throw an exception' {
                $testparams = @{
                    RefreshMode          = 'Pull'
                    ResourceRepoSourcePath = '\\server\share'
                    ResourceRepoServerUrl  = 'https://www.domain.com/service.svc'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You cannot specify ResourceRepoSourcePath with ResourceRepoServerUrl or ResourceRepoRegistrationKey'
            }

            It 'Parameter ResourceRepoRegistrationKey is specified, but ResourceRepoServerUrl is missing. Should throw an exception' {
                $testparams = @{
                    RefreshMode               = 'Pull'
                    ResourceRepoRegistrationKey = 'abcdefghij'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You have to specify ResourceRepoServerUrl with ResourceRepoRegistrationKey'
            }

            It 'Parameter ResourceRepoServerUrl is specified, but ResourceRepoRegistrationKey is missing. Should throw an exception' {
                $testparams = @{
                    RefreshMode          = 'Pull'
                    ResourceRepoServerUrl  = 'https://www.domain.com/service.svc'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You have to specify ResourceRepoRegistrationKey with ResourceRepoServerUrl'
            }
        }

        Context 'Checking invalid Report* parameter values' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Parameter ResourceRepoSourcePath is specified with ResourceRepoServerUrl. Should throw an exception' {
                $testparams = @{
                    RefreshMode     = 'Pull'
                    ReportServerUrl = '\\server\share'
                }

                { Set-DscAgentConfiguration @testparams } | Should -Throw 'You have to specify both ReportServerUrl and ReportRegistrationKey'
            }
        }
    }
}
