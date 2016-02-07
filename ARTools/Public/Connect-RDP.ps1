#requires -Version 2
function Connect-RDP
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = $null,
        
        [Parameter(Mandatory = $False)]
        [switch]$Force
    )
    
    DynamicParam{
        If($ComputerName)
        {
            New-DynamicParameter -Name Credential -TypeConstraint ([pscredential])
        }
    }
    
    Begin{
        If($PSBoundParameters.ContainsKey('Credential'))
        {
            $Credential = $PSBoundParameters.Credential
            $User = $Credential.UserName
            $Password = $Credential.GetNetworkCredential().Password

            If($User -like "$env:USERDOMAIN*")
            {
                Add-Type -AssemblyName System.DirectoryServices.AccountManagement
                $Domain = $env:USERDOMAIN
                $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
                $PrincipalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ContextType, $Domain
                $CredentialValidity = $PrincipalContext.ValidateCredentials($User,$Password)
                If(-not $CredentialValidity)
                {
                    Write-Warning -Message 'Logon failure: Unknown username or bad password.' 
                    Break
                }
            }
        }
    }

    Process{
        If($PSBoundParameters.ContainsKey('ComputerName'))
        {
            Foreach($Computer in $ComputerName)
            {
                If((Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -or $Force)
                {
                    If($PSBoundParameters.ContainsKey('Credential'))
                    {
                        Start-Process -FilePath $env:windir\System32\cmdkey.exe -ArgumentList "/generic:$Computer /user:$User /pass:$Password"
                    }

                    Start-Process -FilePath $env:windir\System32\mstsc.exe -ArgumentList "/v:$Computer /f" -WindowStyle Normal
                }
                Else
                {
                    Write-Warning -Message "Cannot contact $Computer."
                }
            }
        }
        Else
        {
            Start-Process -FilePath $env:windir\System32\mstsc.exe
        }
    }

    End{}
}


