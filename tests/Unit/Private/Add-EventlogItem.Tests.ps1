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
    Describe 'Add-EventlogItem' {
        BeforeAll {
            # Mocks for all context blocks. Avoid if possible.
        }

        # Context block cannot always be used.
        Context 'Function runs as expected, event log and source exist' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Confirm-SourceExists' -MockWith {
                    return $true
                }

                Mock -CommandName 'Get-LogNameFromSource' -MockWith {
                    return 'Application'
                }

                Mock -CommandName 'Write-EventLog' -MockWith { }
            }

            $testparams = @{
                Message   = 'This is a test message'
                Source    = 'PesterTests'
                EntryType = 'Information'
                LogName   = 'Application'
                EventID  = 1
            }

            It 'Should create new eventlog item' {
                Add-EventlogItem @testparams
                Assert-MockCalled -CommandName Write-Eventlog -Times 1
            }
        }

        Context 'Function runs as expected, event log and source do not exist' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Confirm-SourceExists' -MockWith {
                    return $false
                }

                Mock -CommandName 'Confirm-LogExists' -MockWith {
                    return $false
                }

                Mock -CommandName 'New-EventLog' -MockWith { }

                Mock -CommandName 'Write-EventLog' -MockWith { }
            }

            $testparams = @{
                Message   = 'This is a test message'
                Source    = 'PesterTests'
                EntryType = 'Information'
                LogName   = 'Application'
                EventID  = 1
            }

            It 'Should create the eventlog and new eventlog item' {
                Add-EventlogItem @testparams
                Assert-MockCalled -CommandName New-Eventlog -Times 1
                Assert-MockCalled -CommandName Write-Eventlog -Times 1
            }
        }

        Context 'Function runs as expected, source do not exist but log does' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Confirm-SourceExists' -MockWith {
                    return $false
                }

                Mock -CommandName 'Confirm-LogExists' -MockWith {
                    return $true
                }

                Mock -CommandName 'New-EventSource' -MockWith { }

                Mock -CommandName 'Write-EventLog' -MockWith { }
            }

            $testparams = @{
                Message   = 'This is a test message'
                Source    = 'PesterTests'
                EntryType = 'Information'
                LogName   = 'Application'
                EventID  = 1
            }

            It 'Should create the eventsource and new eventlog item' {
                Add-EventlogItem @testparams
                Assert-MockCalled -CommandName New-EventSource -Times 1
                Assert-MockCalled -CommandName Write-Eventlog -Times 1
            }
        }

        Context 'Function cannot run, source exists on incorrect log' {
            BeforeAll {
                Mock -CommandName 'Write-Log' -MockWith { }

                Mock -CommandName 'Confirm-SourceExists' -MockWith {
                    return $true
                }

                Mock -CommandName 'Get-LogNameFromSource' -MockWith {
                    return 'System'
                }

                Mock -CommandName 'Write-EventLog' -MockWith { }
            }

            $testparams = @{
                Message   = 'This is a test message'
                Source    = 'PesterTests'
                EntryType = 'Information'
                LogName   = 'Application'
                EventID  = 1
            }

            It 'Should not create a new eventlog item' {
                Add-EventlogItem @testparams
                Assert-MockCalled -CommandName Write-Eventlog -Times 0
            }
        }
    }
}
