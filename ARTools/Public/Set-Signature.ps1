function Set-Signature
{
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'Medium')]

    Param(
        [Parameter(Mandatory = $False)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate = (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert),
        
        [Parameter(Mandatory = $False,ValueFromPipeline= $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('Path')]
        [system.io.fileinfo[]]$FilePath = $null,
        
        [Parameter(Mandatory = $False)]
        [switch]$Force
    )

    Begin{
        Push-Location C:\Windows\System32
        
        $TimeStampServer = 'http://timestamp.verisign.com/scripts/timstamp.dll'
    }

    Process{
        If($null -eq $FilePath)
        {
            If($Host.Name -match 'Visual Studio')
            {
                $null = $dte.ActiveDocument.Save()
                [System.IO.FileInfo]$FilePath = $dte.ActiveDocument.FullName
            }
            ElseIf($Host.Name -match 'Windows PowerShell ISE')
            {
                $null = $psISE.CurrentFile.Save()
                [System.IO.FileInfo]$FilePath = $psISE.CurrentFile.FullPath
            }
            Else
            {
                Write-Warning -Message 'Current host not supported.'
                Break
            }
        }
        
        Foreach($File in $FilePath)
        {
            If($PSCmdlet.ShouldProcess($($File.Name))){
                $File | 
				Where-Object -FilterScript {$_.Extension -match '.ps1|.ps1xml|.psd1|.psm1'} |
                Get-AuthenticodeSignature |
                ForEach-Object -Process{
                    If($Force -or ($_.Status -ne 'Valid'))
                    {
                        Set-AuthenticodeSignature -FilePath $_.Path -Certificate $Certificate -IncludeChain All -TimestampServer $TimeStampServer -Force
                    }
                    ElseIf($_.Status -eq 'Valid')
                    {
                        Write-Warning -Message "Valid signature already found for file '$($_.Path)'."
                    }
                }
            }
        }
        
    }

    End{
        Pop-Location
    }
}


