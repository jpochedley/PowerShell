#requires -Version 2
function Get-StaleLocalUser
{
    <#
            .Synopsis
            Displays local user accounts whose passwords have not been changed in a given number of days.
    
            .DESCRIPTION
            The Get-StaleLocalUser function uses Powershell remoting to display local user accounts on remote computers whose passwords have not been changed in a given number of days.
    
            By default this function queries all domain-joined computers for any local user accounts that are enabled and whose password age has exceeded the maximum password age of the current domain.
    
            .EXAMPLE
            PS C:\> Get-StaleLocalUser
    
            This command queries all domain-joined computers for any local user accounts that are enabled and whose password age has exceeded the maximum password age of the current domain using the current user's credentials. 
    
            .EXAMPLE
            PS C:\> Get-StaleLocalUser -Credential (Get-Credential)
    
            This command queries all domain-joined computers for any local user accounts that are enabled and whose password age has exceeded the maximum password age of the current domain using the specified credentials. 
    
            .EXAMPLE
            PS C:\> Get-StaleLocalUser -IncludeDisabled

            This command queries all domain-joined computers for any local user accounts (both enabled and disabled) whose password age has exceeded the maximum password age of the current domain using the current user's credentials. 

            .EXAMPLE
            PS C:\> Get-StaleLocalUser -IncludeDisabled | Export-csv -Path c:\LocalUsers.csv

            This command queries all domain-joined computers for any local user accounts (both enabled and disabled) whose password age has exceeded the maximum password age of the current domain using the current user's credentials. The results are then exported to a CSV file named LocalUsers.csv at the root of the C drive.

            .EXAMPLE
            PS C:\>Set-Item -Path wsman:\localhost\Client\TrustedHosts -Value 172.16.0.0
    
            In this example a non-domain-joined computer is queried for any local user accounts (both enabled and disabled) whose password age has exceeded the maximum password age of the current domain. First, in order to use an IP adress in the value of the ComputerName parameter, the IP address of the remote computer must be included in the WinRM TrustedHosts list on the local computer. To do so, the first command is run. Please note, this command assumes the WinRM TrustedHosts list on the local computer has not been previously set or is empty.

            Next, the non-domain-joined computer can now be queried. The credentials of an administrator account on the remote computer must be provided as shown in the command below.
    

            PS C:\>Get-StaleLocalUser -IncludeDisabled -ComputerName 172.16.0.0 -Credential Administrator


            Finally, unless otherwise needed, the IP address of the remote computer can now be removed from the WinRM TrustedHosts list on the local computer. To do so, the below command is run. Please note, the above command assumes the WinRM TrustedHosts list on the local computer has not been previously set or is empty.


            PS C:\>Clear-Item -Path wsman:\localhost\Client\TrustedHosts
    
            .NOTES
            The Get-StaleLocalUser function requires administrator rights on the remote computer(s) to be queried.
        
            Powershell remoting must be enabled on the remote computer to properly query local user accounts. 
        
            If Powershell remoting is not enabled on a remote computer it can be enabled by either
            - Running Enable-PSRemoting locally or 
            - By running Enable-RemotePSRemoting and specifying the name of the remote computer.
    
            .PARAMETER ComputerName
            Specifies the computers on which the command runs. The default is all domain-joined computers.
        
            Type the NETBIOS name, IP address, or fully-qualified domain name of one or more computers in a comma-separated list. To specify the local computer, type the computer name, "localhost", or a dot (.).
        
            To use an IP address in the value of the ComputerName parameter, the command must include the Credential parameter. Also, the computer must be configured for HTTPS transport or the IP address of the remote computer must be included in the WinRM TrustedHosts list on the local computer. For instructions for adding a computer name to the TrustedHosts list, see "How to Add  a Computer to the Trusted Host List" in about_Remote_Troubleshooting.
    
            .PARAMETER Credential
            Specifies a user account that has permission to perform this action. The default is the current user.
        
            Type a user name, such as "User01" or "Domain01\User01", or enter a variable that contains a PSCredential object, such as one generated by the Get-Credential cmdlet. When you type a user name, you will be prompted for a password.
    
            .PARAMETER DaysOld
            Specifies the maximum password age in number of days. The default is the maximum password age of the current domain.
    
            .PARAMETER IncludeDisabled
            Specifies the function include disabled local user accounts in the results.

    #>
    
    [cmdletbinding()]
    
    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('Name')]
        [string[]]$ComputerName = (Get-ADComputer -Filter *).Name,
    
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null,
        
        [Parameter(Mandatory = $False)]
        [int]$DaysOld = (Get-ADDefaultDomainPasswordPolicy -Identity $env:USERDNSDOMAIN).MaxPasswordAge.Days,
        
        [Parameter(Mandatory = $False)]
        [switch]$IncludeDisabled
    )
    
    Begin{}
    
    Process{
        $ScriptBlock = {
            [int]$DaysOld = $Using:DaysOld
            [bool]$IncludeDisabled = $Using:IncludeDisabled
            $WarningPreference = $Using:WarningPreference
        
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
            $PrincipalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList ([System.DirectoryServices.AccountManagement.ContextType]::Machine, $env:COMPUTERNAME)
            $UserPrincipal = New-Object -TypeName System.DirectoryServices.AccountManagement.UserPrincipal -ArgumentList ($PrincipalContext)
            $Searcher = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalSearcher
            $Searcher.QueryFilter = $UserPrincipal
            $Searcher.FindAll() |
            
            Where-Object -FilterScript {
                $_.LastPasswordSet -le (Get-Date).AddDays($(-$DaysOld))
            } |
    
            Select-Object -Property Name, @{
                n = 'Username'
                e = {
                    $_.samaccountname
                }
            }, Enabled, Description, LastPasswordSet, PasswordNeverExpires, PasswordNotRequired |
            
            ForEach-Object -Process {
                $Object  = $_
                If($IncludeDisabled)
                {
                    $Object
                }
                Else
                {
                    $Object |
                    Where-Object -FilterScript {
                        $_.Enabled -eq $True
                    }
                }
            }
        }
    
        $InvokeArgs = @{
            ComputerName = $ComputerName
        }
    
        If($null -ne $Credential)
        {
            $InvokeArgs.Credential = $Credential
        }
        
        $InvokeArgs.ComputerName = Test-PSRemoting @InvokeArgs -WarningAction $WarningPreference
        
        If($null -eq $InvokeArgs.ComputerName)
        {
            Break
        }
        
        $InvokeArgs.ScriptBlock = $ScriptBlock
        
        Invoke-Command @InvokeArgs | Select-Object -Property * -ExcludeProperty RunspaceID
    }
    
    End{}
}


