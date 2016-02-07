#requires -Version 2
function Get-StaleDomainUser
{
    <#
            .Synopsis
            Displays domain user accounts whose passwords have not been changed in a given number of days.

            .DESCRIPTION
            The Get-StaleDomainUser function displays all domain user acounts whose passwords have not been changed in a given number of days.
    
            By default this function displays domain user accounts that are enabled and whose password age has exceeded the maximum password age of the current domain.

            .EXAMPLE
            PS C:\> Get-StaleDomainUser

            This command displays all domain user accounts that are enabled and whose password age has exceeded the maximum password age of the current domain. 

            .EXAMPLE
            PS C:\> Get-StaleDomainUser -IncludeDisabled | Export-csv -Path c:\DomainUsers.csv

            This command displays all domain user accounts (both enabled and disabled) whose password age has exceeded the maximum password age of the current domain. The results are then exported to a CSV file named DomainUsers.csv at the root of the C drive.
    
            .EXAMPLE
            PS C:\> Get-StaleDomainUser

            This command displays all domain user accounts that are enabled and whose password age has exceeded the maximum password age of the current domain. 

            .NOTES
            The Get-StaleDomainUser function requires the ActiveDirectory module to be installed. This module can be obtained by installing the Remote Server Administration Tools on one's computer.
    
            .PARAMETER DaysOld
            Specifies the maximum password age in number of days. The default is the maximum password age of the current domain.
    
            .PARAMETER IncludeDisabled
            Specifies the function return disabled domain user accounts as well.

    #>
    
    [cmdletbinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        [int]$DaysOld = (Get-ADDefaultDomainPasswordPolicy -Identity $env:USERDNSDOMAIN).MaxPasswordAge.Days,
        
        [Parameter(Mandatory = $False)]
        [switch]$IncludeDisabled
    )
    
    Begin{}
    
    Process{
        Get-ADUser -Filter * -Properties pwdLastSet, PasswordNeverExpires, PasswordNotRequired, Description |
        Select-Object -Property *, @{
            n = 'LastPasswordSet'
            e = {
                [datetime]::FromFileTime($_.pwdlastset)
            }
        } | 
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
    
    End{}
}



