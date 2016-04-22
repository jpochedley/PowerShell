#requires -Version 2
function Reset-ADPassword
{
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]

    Param(
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    Try
                    {
                        $account = $_
                        $null = Get-ADUser -Identity $account -ErrorAction Stop
                        $True 
                    }
                    Catch
                    {
                        Throw "User $account not found. Please check spelling and try again."
                    }
                }
        )]
        [string]$Username,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [securestring]$Password = (New-RandomPassword).SecureStringObject,

        [Parameter(Mandatory = $False)]
        [switch]$ChangePasswordAtLogon,
        
        [Parameter(Mandatory = $True)]
        [string]$Server
    )

    Begin{}

    Process{
        If($PSCmdlet.ShouldProcess($Username))
        {
            If($InformationPreference -eq 'Continue')
            {
                $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Password)
                $PTPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
            
                Write-Information -MessageData "Password:`t$PTPassword"
            }
            
            Try
            {
                Write-Verbose -Message "Resetting user's password and unlocking account ..."
                Set-ADAccountPassword -Identity $Username -NewPassword $Password -Reset -ErrorAction Stop -PassThru -Server $Server | Unlock-ADAccount -Server $Server
                Write-Verbose -Message "User's password was reset successfully and account was unlocked."            

                If($ChangePasswordAtLogon)
                {
                    Try
                    {
                        Write-Verbose -Message 'Specifying password must be changed at next logon ...'
                        Set-ADUser -Identity $Username -ChangePasswordAtLogon $True -Server $Server
                        Write-Verbose -Message 'Password must now be changed at next logon.'
                    }
                    Catch
                    {
                        Write-Warning -Message  "Failed to specify password must be changed at next logon: $($_.Exception.Message)"
                    }
                }
            }
            Catch
            {
                Write-Warning -Message  "Failed to reset password: $($_.Exception.Message)"
            }
        }
    }

    End{}
}


