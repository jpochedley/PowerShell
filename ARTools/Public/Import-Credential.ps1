#requires -Version 2
function Import-Credential
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        [string]$Username = $env:USERNAME,
        
        [Parameter(Mandatory = $False)]
        [string]$Domain = $env:USERDNSDOMAIN,
    
        [Parameter(Mandatory = $False)]
        [ValidateScript({
                    If(Test-Path -Path $_)
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please specify path to CredStore.xml file.'
                    }
                }
        )]
        [string]$FilePath = "$env:APPDATA\SavedCreds\CredStore.xml",
        
        [Parameter(Mandatory = $False)]
        [switch]$AsUPN
    )

    Begin{}

    Process{
        If(Test-Path -Path $FilePath)
        {
            If($AsUPN)
            {
                $Principal = "$Username@$Domain"
            }
            Else
            {
                $Principal = "$Domain\$Username"
            }
    
            [xml]$XML = Get-Content -Path $FilePath
            $Query = Select-Xml -Xml $XML -XPath "//Account[Username='$Username' and Domain='$Domain']"
            If($null -ne $Query)
            {
                Foreach($Item in $Query)
                {
                    $SecurePassword = $Item.Node.Password | ConvertTo-SecureString
                    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Principal, $SecurePassword)
                }
            }
            Else
            {
                Write-Warning -Message "No credential for $Principal found."
            }
        }
        Else
        {
            Write-Warning -Message 'No credential store found.'
        }
    }

    End{}
}


