function Find-AlternateEmailAddress
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $False)]
        [string]$Identity = '*'
    )

    Begin{
        Try
        {
            Write-Verbose -Message 'Checking for Exchange session ...'
            $null = Get-PSSession -Name Exchange -ErrorAction Stop
            Write-Verbose -Message 'Exchange session found.'
        }
        Catch
        {
            Write-Warning -Message 'Unable to find Exchange session. Please run Connect-Exchange and try again.'
            Break
        }
    }
	
    Process{
        Get-Mailbox -Identity $Identity |
        Select-Object -Property Name, PrimarySMTPAddress, Alias, SamaccountName, @{
            n = 'AlternateEmailAddress'
            e = {
                $Alias = $_.Alias
                $AlternateEmails = $_.EmailAddresses |
                Where-Object -FilterScript {
                    $_ -match '^(SMTP|smtp).*$' -and $_ -notmatch "(SMTP|smtp):$Alias@.*"
                }
        
                $AlternateEmails -ireplace 'smtp:', ''
            }
        } |
        Where-Object -Property AlternateEmailAddress
    }

    End{}
}


