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
        Context 'LCM is busy, open live file' {
            BeforeAll {
                Mock -CommandName 'Get-DscConfigurationStatus' -MockWith {
                    throw [Microsoft.Management.Infrastructure.CimException] "LCM is busy"
                }
                Mock -CommandName 'Select-Object' -MockWith { }
                Mock -CommandName 'Out-GridView' -MockWith { }
                Mock -CommandName 'Invoke-CimMethod' -MockWith {
                    return @{
                        ShadowID = '{A27F8443-5CF2-4141-A8F7-DBC7B9DE7220}'
                    }
                }
                Mock -CommandName 'Get-CimInstance' -MockWith {
                    $returnval = @{
                        ID           = '{A27F8443-5CF2-4141-A8F7-DBC7B9DE7220}'
                        DeviceObject = '\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy6'
                    }

                    $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value {} -PassThru
                    return $returnval
                }
                Mock -CommandName 'Start-Process' -MockWith { }
                Mock -CommandName 'Start-Sleep' -MockWith { }
                Mock -CommandName 'Get-ChildItem' -MockWith { }
                Mock -CommandName 'Join-Path' -MockWith { }
                Mock -CommandName 'Get-Item' -MockWith {
                    $returnval = @{}
                    $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name 'Delete' -Value {} -PassThru
                    return $returnval
                }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should get log from active LCM run' {
                Get-DscLogs
                Should -Invoke 'Invoke-CimMethod' -Exactly 1
                Should -Invoke 'Get-CimInstance' -Exactly 1
                Should -Invoke 'Start-Process' -Exactly 2
                Should -Invoke 'Write-Log' -Exactly 6
            }
        }

        Context 'Get jobs, but user selected two jobs' {
            BeforeAll {
                Mock -CommandName 'Get-DscConfigurationStatus' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                        },
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                        }
                    )
                }
                Mock -CommandName 'Out-GridView' -MockWith { }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should display message the user selected two jobs' {
                Get-DscLogs
                Should -Invoke 'Write-Log' -Exactly 4
            }
        }

        Context 'Get jobs and user selected one job which has one log file' {
            BeforeAll {
                Mock -CommandName 'Get-DscConfigurationStatus' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }

                Mock -CommandName 'Out-GridView' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }
                Mock -CommandName 'Get-ChildItem' -MockWith {
                    return @(
                        @{
                            Name = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }
                Mock -CommandName 'Get-Content' -MockWith { return "" }
                Mock -CommandName 'ConvertFrom-Json' -MockWith { return "" }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should display the log file' {
                Get-DscLogs
                Should -Invoke 'Write-Log' -Exactly 5
                Should -Invoke 'Get-Content' -Exactly 1
                Should -Invoke 'ConvertFrom-Json' -Exactly 1
                Should -Invoke 'Out-GridView' -Exactly 2
            }
        }

        Context 'Get jobs and user selected one job which has multiple log file' {
            BeforeAll {
                Mock -CommandName 'Get-DscConfigurationStatus' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }

                Mock -CommandName 'Out-GridView' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                } -ParameterFilter { $Title -eq 'Please select the job you want to view the log for' }

                Mock -CommandName 'Get-ChildItem' -MockWith {
                    return @(
                        [PSCustomObject]@{
                            Name          = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}-0.json'
                            Length        = 1000
                            LastWriteTime = (Get-Date)
                            CreationTime  = (Get-Date).AddSeconds(-10)
                        },
                        [PSCustomObject]@{
                            Name          = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}-1.json'
                            Length        = 1000
                            LastWriteTime = (Get-Date)
                            CreationTime  = (Get-Date).AddSeconds(-10)
                        }
                    )
                }

                Mock -CommandName 'Out-GridView' -MockWith {
                    if ($global:loopCount -eq 0)
                    {
                        $global:loopCount++
                        return @(
                            @{
                                Name = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}-0.json'
                            }
                        )
                    }
                } -ParameterFilter { $Title -eq 'Please select the logfile you want to view' }

                Mock -CommandName 'Out-GridView' -MockWith { }

                Mock -CommandName 'Get-Content' -MockWith { return "" }
                Mock -CommandName 'ConvertFrom-Json' -MockWith { }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should display the log file' {
                $global:loopCount = 0
                Get-DscLogs
                Should -Invoke 'Write-Log' -Exactly 5
                Should -Invoke 'Get-Content' -Exactly 1
                Should -Invoke 'ConvertFrom-Json' -Exactly 1
                Should -Invoke 'Out-GridView' -Exactly 3
            }
        }

        Context 'Get jobs and user selected one job which has one log file' {
            BeforeAll {
                Mock -CommandName 'Get-DscConfigurationStatus' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }

                Mock -CommandName 'Out-GridView' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }
                Mock -CommandName 'Get-ChildItem' -MockWith {
                    return @(
                        @{
                            Name = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }
                Mock -CommandName 'Get-Content' -MockWith { throw [System.IO.IOException] "Cannot open file" }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should display a warning message' {
                Get-DscLogs
                Should -Invoke 'Write-Log' -Exactly 6
                Should -Invoke 'Get-Content' -Exactly 1
                Should -Invoke 'Out-GridView' -Exactly 1
            }
        }

        Context 'Get jobs and user selected one job but user cancels file selection' {
            BeforeAll {
                Mock -CommandName 'Get-DscConfigurationStatus' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }

                Mock -CommandName 'Out-GridView' -MockWith {
                    return @(
                        @{
                            Status                     = 'Failed'
                            StartDate                  = (Get-Date)
                            DurationInSeconds          = 10
                            ResourcesNotInDesiredState = @()
                            Error                      = ''
                            Type                       = 'Consistency'
                            Mode                       = 'PUSH'
                            RebootRequested            = $false
                            NumberOfResources          = 5
                            JobID                      = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                } -ParameterFilter { $Title -eq 'Please select the job you want to view the log for' }

                Mock -CommandName 'Get-ChildItem' -MockWith {
                    return @(
                        @{
                            Name = '{48E9CE5F-B13C-11EA-A828-000D3AAD181A}'
                        }
                    )
                }
                Mock -CommandName 'Out-GridView' -MockWith { }
                Mock -CommandName 'Get-Content' -MockWith { throw [System.IO.IOException] "Cannot open file" }
                Mock -CommandName 'Write-Log' -MockWith { }
            }

            It 'Should display a warning message' {
                Get-DscLogs
                Should -Invoke 'Write-Log' -Exactly 6
                Should -Invoke 'Get-Content' -Exactly 1
                Should -Invoke 'Out-GridView' -Exactly 1
            }
        }
    }
}
