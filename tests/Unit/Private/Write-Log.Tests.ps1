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
    Describe 'Write-Log' {
        BeforeAll {
            # Mocks for all context blocks. Avoid if possible.
        }

        # Context block cannot always be used.
        Context 'Function runs as expected' {
            BeforeAll {
                Mock -CommandName 'Write-Host' -MockWith { }
            }

            It 'Should log new message' {
                $testparams = @{
                    Message = 'This is a test message'
                }

                Write-Log @testparams
                Assert-MockCalled -CommandName Write-Host -Times 1
            }
        }
    }
}
