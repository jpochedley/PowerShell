#requires -Version 3
function Connect-Exchange
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null,
        
        [Parameter(Mandatory = $True)]
        [string]$Server = $null,
        
        [Parameter(Mandatory = $False)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        
        [Parameter(Mandatory = $False)]
        [switch]$SkipImportModule
    )
    
    Begin{}

    Process{
        $NewPSSessionParams = @{
            Name              = 'Exchange'
            ConfigurationName = 'Microsoft.Exchange'
            ConnectionUri     = "http://$Server/powershell"
            ErrorAction       = 'Stop'
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
            Remove-PSSession -Name Exchange -ErrorAction SilentlyContinue
            Write-Verbose -Message 'Connecting to Exchange server ...'
            $Session = New-PSSession @NewPSSessionParams 3> $null
            Write-Verbose -Message 'Successfully connected to Exchange server.'
        }
        Catch
        {
            Write-Warning -Message "Unable to connect to $Server. $($_.Exception.Message)"
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
                    Write-Verbose -Message 'Importing Exchange cmdlets and functions ...'
                    $ModuleInfo = Import-PSSession @ImportSessionParams 3> $null
                    Import-Module -ModuleInfo $ModuleInfo -Global -Verbose:$False 3> $null
                    Write-Verbose -Message 'Exchange cmdlets and functions imported successfully.'
                }
                Catch
                {
                    Write-Warning -Message "Import failed. $($_.Exception.Message)"
                }
            }
        }
        Else
        {
            Write-Warning -Message 'No session found. Exchange cmdlets and functions not imported.'
        }
    }

    End{}
}
