#requires -Version 2
function Remove-UserProfile
{
    [CmdletBinding(DefaultParameterSetName = 'Specific')]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True,ParameterSetName = 'Specific')]
        [ValidateScript({
                    If($_ -ne $env:USERNAME)
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Cannot run command with specified user account at this time.'
                    }
                }
        )]
        [alias('SamAccountName')]
        [string]$Username,
        
        [Parameter(Mandatory = $True,ParameterSetName = 'Purge')]
        [switch]$Purge,
        
        [Parameter(Mandatory = $False,ParameterSetName = 'Purge')]
        [string[]]$ExcludeUser,

        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [alias('PSComputerName')]
        [Alias('Hostname')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $False)]
        [pscredential]$Credential
    )

    Begin{}

    Process{
        If($Purge)
        {
            If($ExcludeUser)
            {
                $ExcludedSIDs = $ExcludeUser | ForEach-Object -Process { 
                    Get-ADUser -Identity $_ -ErrorAction Stop |
                    Select-Object -ExpandProperty SID |
                    Select-Object -ExpandProperty Value
                }
            }
            Else
            {
                $ExcludedSIDs = $null
            }
            
            $SID = $null
        }
        Else
        {
            $ExcludedSIDs = $null
            
            Try
            {
                $SID = Get-ADUser -Identity $Username -ErrorAction Stop |
                Select-Object -ExpandProperty SID |
                Select-Object -ExpandProperty Value

                If($null -eq $SID)
                {
                    Write-Warning -Message 'User SID not obtained from Active Directory.'
                    Break
                }
            }
            Catch
            {
                Write-Warning -Message "$($_.Exception.Message)"
                Break
            }
        }

        [scriptblock]$Scriptblock = {
            $SID = $Using:SID
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference
            
            $LoggedonUsers = Get-WmiObject -Class win32_process |
            Invoke-WmiMethod -Name GetOwnerSID |
            Sort-Object -Property SID -Unique |
            Select-Object -ExpandProperty SID |
            Where-Object -FilterScript {
                $_ -match "^S-\d-\d+-(\d+-){1,14}\d+$" -and $_ -notmatch 'S-1-5-90-0-2'
            }
            
            Try
            {
                If($Using:Purge)
                {
                    $Profiles = Get-WmiObject -Class win32_userprofile | Where-Object -FilterScript {
                        $_.SID -match "^S-\d-\d+-(\d+-){1,14}\d+$" -and $_.SID -notmatch 'S-1-5-90-0-2' -and $LoggedonUsers -notcontains $_.SID -and $using:ExcludedSIDs -notcontains $_.SID
                    }
                }
                Else
                {
                    $Profiles = Get-WmiObject -Class win32_userprofile -Filter "SID='$SID'" -ErrorAction Stop
                    
                    If($LoggedonUsers -contains $Profiles.SID)
                    {
                        Write-Warning -Message 'Cannot remove profile while user is logged in.'
                        
                        $Profiles = $null
                    }
                }
                
                If($null -ne $Profiles)
                {
                    Try
                    {
                        Foreach($Profile in $Profiles)
                        {
                            Write-Verbose -Message "Removing profile $($Profile.LocalPath) from $env:COMPUTERNAME ..." -Verbose:$VerboseSwitch
                            $Profile | Remove-WmiObject -ErrorAction Stop
                            Write-Verbose -Message "Profile $($Profile.LocalPath) successfully removed on $env:COMPUTERNAME." -Verbose:$VerboseSwitch
                        }
                    }
                    Catch
                    {
                        Write-Error -Message "Failed to remove profile on $env:COMPUTERNAME. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Verbose -Message "No user profile found on $env:COMPUTERNAME."
                }
            }
            Catch
            {
                Write-Warning -Message "Unable to query profiles on $env:COMPUTERNAME."
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
        
        $InvokeArgs.ScriptBlock = $Scriptblock
        
        Invoke-Command @InvokeArgs -HideComputerName
    }

    End{}
}


