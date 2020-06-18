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
    Describe 'Get-DscLogs' {
        BeforeAll {
            # Mocks for all context blocks. Avoid if possible.
        }

        # Context block cannot always be used.
        Context 'Function runs as expected' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should successfully generate and execute the scriptblock' {
                #Get-DscLogs
            }
        }
    }
}
