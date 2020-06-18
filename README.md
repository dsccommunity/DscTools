# DscTools

[![Build Status](https://dev.azure.com/dsccommunity/DscTools/_apis/build/status/dsccommunity.DscTools?branchName=master)](https://dev.azure.com/dsccommunity/DscTools/_build/latest?definitionId=14&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/DscTools/14/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/DscTools/14/master)](https://dsccommunity.visualstudio.com/DscTools/_test/analytics?definitionId=14&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/DscTools?label=DscTools%20Preview)](https://www.powershellgallery.com/packages/DscTools/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/DscTools?label=DscTools)](https://www.powershellgallery.com/packages/DscTools/)

The DscTools PowerShell module provides several tools that make implementing,
managing and troubleshooting PowerShell Desired State Configuration easier.

Please leave comments, feature requests, and bug reports in the issues tab for
this module.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

If you would like to modify DscTools module, please feel free. Please
refer to the [Contribution Guidelines](https://dsccommunity.org/guidelines/contributing)
for information about style guides, testing and patterns for contributing
to DSC resources.

## Installation

To manually install the module, download the source code and unzip the contents
of the \Modules\DscTools directory to the
$env:ProgramFiles\WindowsPowerShell\Modules folder

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

    Find-Module -Name DscTools -Repository PSGallery | Install-Module

## Requirements

The minimum PowerShell version required is 4.0, which ships in Windows 8.1
or Windows Server 2012R2 (or higher versions). The preferred version is
PowerShell 5.0 or higher, which ships with Windows 10 or Windows Server 2016.

## Documentation and examples

For a full list of functionalities in DscTools and examples on their use, check
out the [DscTools wiki](https://github.com/dsccommunity/DscTools/wiki).

## Changelog

A full list of changes in each version can be found in the
[change log](CHANGELOG.md)
