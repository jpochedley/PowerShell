#requires -Version 2
function Get-LockOutInfo 
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('SAMAccountName')]
        [string[]]$Username
    )

    Begin{
        $DCS = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
    }

    Process{
        Foreach($User in $Username)
        {
            $Jobs = Foreach($DC in $DCS)
            {
                Start-Job -ScriptBlock{
                    Get-ADUser -Identity $Using:User -Properties LockedOut, CannotChangePassword, PasswordLastSet, PasswordNeverExpires, LastBadPasswordAttempt, PasswordNotRequired, PasswordExpired, badPwdCount, Enabled -Server $Using:DC | Select-Object -Property *, @{
                        n = 'DC'
                        e = {
                            $Using:DC
                        }
                    }
                }
            }
            
            $Info = $Jobs |
            Wait-Job |
            Receive-Job -Keep

            $Info |
            Select-Object -Property DC, LockedOut, PasswordExpired, LastBadPasswordAttempt, badPwdCount, PasswordLastSet, Enabled |
            Out-GridView -Title "Lockout Status For $($Info[0].Name)"
        }
    }

    End{}
}


