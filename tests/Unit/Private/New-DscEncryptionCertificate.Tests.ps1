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
    Describe 'New-DscEncryptionCertificate' {
        BeforeAll {
            # Mocks for all context blocks. Avoid if possible.
        }

        # Context block cannot always be used.
        Context 'Function runs as expected, certificate already exists' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Get-ChildItem' -MockWith {
                    return @{
                        Subject    = 'DscEncryptionCert'
                        Thumbprint = '1234567890'
                    }
                }
            }

            It 'Should get existing certificate thumbprint' {
                $testparams = @{
                    CertificateSubject = 'DscEncryptionCert'
                }

                New-DscEncryptionCertificate @testparams | Should -Be '1234567890'
            }
        }

        Context 'Function runs as expected, create new certificate in Local Machine store' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Get-ChildItem' -MockWith {
                    if ($global:gciCount -eq 0)
                    {
                        $global:gciCount++
                        return $null
                    }
                    else
                    {
                        return @{
                            Subject      = 'DscEncryptionCert'
                            Thumbprint   = '1234567890'
                        }
                    }
                }

                Mock -CommandName 'New-SelfSignedCertificate' -MockWith {
                    return @{
                        Subject      = 'DscEncryptionCert'
                        Thumbprint   = '1234567890'
                        PSParentPath = 'Microsoft.PowerShell.Security\Certificate::LocalMachine\my'
                    }
                }
            }

            It 'Should create new certificate and get thumbprint' {
                $testparams = @{
                    CertificateSubject = 'DscEncryptionCert'
                }

                $global:gciCount = 0
                New-DscEncryptionCertificate @testparams | Should -Be '1234567890'
            }
        }

        Context 'Function runs as expected, create new certificate in Current User store' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Get-ChildItem' -MockWith {
                    if ($global:gciCount -eq 0)
                    {
                        $global:gciCount++
                        return $null
                    }
                    else
                    {
                        return @{
                            Subject      = 'DscEncryptionCert'
                            Thumbprint   = '1234567890'
                        }
                    }
                }

                Mock -CommandName 'New-SelfSignedCertificate' -MockWith {
                    return @{
                        Subject      = 'DscEncryptionCert'
                        Thumbprint   = '1234567890'
                        PSParentPath = 'Microsoft.PowerShell.Security\Certificate::CurrentUser\my'
                        PSPath       = 'c:\dummy'
                    }
                }

                # Needs to be done because real Export-Certificate $cert parameter requires an actual [X509Certificate2] object
                function Export-Certificate
                {
                    [CmdletBinding()]
                    param
                    (
                        [Parameter()]
                        $FilePath,

                        [Parameter()]
                        $Cert,

                        [Parameter()]
                        [switch]
                        $Force,

                        [Parameter()]
                        $Type
                    )
                }

                Mock -CommandName 'Export-Certificate' -MockWith { }
                Mock -CommandName 'Remove-Item' -MockWith { }
                Mock -CommandName 'Import-Certificate' -MockWith { }
            }

            It 'Should create and move new certificate and get thumbprint' {
                $testparams = @{
                    CertificateSubject = 'DscEncryptionCert'
                }

                $global:gciCount = 0
                New-DscEncryptionCertificate @testparams | Should -Be '1234567890'
                Assert-MockCalled -CommandName 'Export-Certificate' -Times 1
            }
        }
    }
}
