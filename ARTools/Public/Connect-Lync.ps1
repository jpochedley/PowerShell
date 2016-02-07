#requires -Version 2
function Connect-Lync
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null,
        
        [Parameter(Mandatory = $True)]
        [string]$Server,
        
        [Parameter(Mandatory = $False)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        
        [Parameter(Mandatory = $False)]
        [switch]$SkipImportModule
    )
    
    Begin{}

    Process{
        $SessionOptions = New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck
    
        $NewPSSessionParams = @{
            Name           = 'Lync'
            ConnectionUri  = "https://$Server/ocspowershell"
            ErrorAction    = 'Stop'
            Authentication = 'NegotiateWithImplicitCredential'
            SessionOption  = $SessionOptions
        }

        If($null -ne $Credential)
        {
            $NewPSSessionParams.Credential = $Credential
            $User = $Credential.UserName
        }
        Else
        {
            $User = $env:USERNAME
        }
        
        Try
        {
            Remove-PSSession -Name Lync -ErrorAction SilentlyContinue
            Write-Verbose -Message 'Connecting to Lync server ...'
            $Session = New-PSSession @NewPSSessionParams 3> $null
            Write-Verbose -Message 'Successfully connected to Lync server.'
        }
        Catch
        {
            Write-Warning -Message "Unable to connect to Lync. $($_.Exception.Message)"
        }
        
        If($null -ne $Session)
        {
            If(-not $SkipImportModule)
            {
                $ImportSessionParams = @{
                    Session      = $Session
                    ErrorAction  = 'Stop'
                    Verbose      = $False
                    AllowClobber = $True
                }
        
                If($PSBoundParameters.ContainsKey('Certificate'))
                {
                    $ImportSessionParams.Certificate = $Certificate
                }
        
                Try
                {
                    Write-Verbose -Message 'Importing Lync cmdlets and functions ...'
                    $ModuleInfo = Import-PSSession @ImportSessionParams 3> $null
                    Import-Module -ModuleInfo $ModuleInfo -Global -Verbose:$False 3> $null
                    Write-Verbose -Message 'Lync cmdlets and functions imported successfully.'
                }
                Catch
                {
                    Write-Warning -Message "Import failed. $($_.Exception.Message)"
                }
            }
        }
        Else
        {
            Write-Warning -Message 'No session found. Lync cmdlets and functions not imported.'
        }
    }

    End{}
}


