    <#
      .SYNOPSIS
      This function gets the thumbprint of the DSC Encryption certificate and create one if it doesn't exist.

      .DESCRIPTION
      This function gets the thumbprint of the DSC Encryption certificate and create one if it doesn't exist.

      .EXAMPLE
      New-DscEncryptionCertificate -Server "server1"

      .PARAMETER PrivateData
      The PrivateData parameter is what will be returned without transformation.

#>
function New-DscEncryptionCertificate
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $Server = 'localhost',

        [Parameter(Mandatory = $true)]
        [System.String]
        $CertificateSubject
    )

    process
    {
        Write-Log -Message "  Generating DSC Encryption certificate for server {$Server}"
        $scriptblock = {
            $existingCertificate = Get-ChildItem -Path Cert:\LocalMachine\My | `
                Where-Object -FilterScript { $_.Subject -match $CertificateSubject }

            if ($null -eq $existingCertificate)
            {
                Write-Verbose -Message "No existing DSC Encryption certificate found. Creating one."
                $cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp `
                    -DnsName 'PowerShell DSC' `
                    -Subject $CertificateSubject `
                    -HashAlgorithm SHA256 `
                    -NotAfter (Get-Date).AddYears(10)

                if ($cert.PSParentPath -notlike '*LocalMachine*')
                {
                    # Move certificate to Local Machine certificate store
                    $certificateFilePath = "$env:Temp\DSCEncryptionCert.cer"
                    $null = Export-Certificate -Cert $cert -FilePath $certificateFilePath -Force
                    $null = Remove-Item -Path $cert.PsPath -Confirm:$false

                    $null = Import-Certificate -FilePath $certificateFilePath `
                                            -CertStoreLocation 'Cert:\LocalMachine\My' `
                                            -Confirm:$false
                    $null = Remove-Item -Path $certificateFilePath `
                                        -Confirm:$false
                }

                $existingCertificate = Get-ChildItem -Path Cert:\LocalMachine\My | `
                    Where-Object -FilterScript { $_.Subject -match $CertificateSubject }
            }
            else
            {
                Write-Verbose -Message "An existing DSC Encryption certificate was found. Re-using it."
            }
            $thumbprint = $existingCertificate.Thumbprint

            return $thumbprint
        }

        if ($Server -eq 'localhost')
        {
            $thumbprint = Invoke-Command -Scriptblock $scriptblock
        }
        else
        {
            $thumbprint = Invoke-Command -ComputerName $Server -ScriptBlock $scriptblock
        }

        Write-Log -Message '  Completed generating DSC Encryption certificate'
        return $thumbprint
    }
}
