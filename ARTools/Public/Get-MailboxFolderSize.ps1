#requires -Version 2
function Get-MailboxFolderSize
{
    [CmdletBinding(DefaultParametersetName = 'Default')]
    
    Param(
        [Parameter(Mandatory = $True,Position = 0)]
        [Alias('Username')]
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
        [string]$Identity
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
        Try
        {
            Get-MailboxFolderStatistics -Identity $Identity -ErrorAction Stop | 
            Select-Object -Property FolderPath, @{
                name       = 'FolderSize (MB)'
                expression = {
                    [math]::Round(($_.FolderSize).Split('(')[1].Split(' ')[0].Replace(',', '')/1MB)
                }
            } | 
            Sort-Object -Property 'FolderSize (MB)' -Descending
        }
        Catch
        {
            Write-Warning -Message "$($_.Exception.Message)"
        }
    }

    End{}
}


