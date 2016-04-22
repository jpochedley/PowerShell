#requires -Version 2
function Add-LocalGroupMember
{
    [CmdletBinding()]
    
    param
    (
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = 'localhost',
        
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [ValidateSet('Administrators','Remote Desktop Users')]
        [string]$Group,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )
    
    Begin{}
    
    Process{
        [scriptblock]$Scriptblock = {
            $Group = $Using:Group
            $Name = $Using:Name
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference
            
            $GroupObject = [ADSI]"WinNT://$env:COMPUTERNAME/$Group"
            
            If($null -ne $GroupObject)
            {
                Foreach($Member in $Name)
                {
                    Try
                    {
                        $GroupObject.Add("WinNT://$env:USERDOMAIN/$Member")
                        
                        If($PSVersionTable.PSVersion.Major -ge 3)
                        {
                            $GroupMembership = (Get-CimInstance -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$env:COMPUTERNAME',Name='$Group'`"" -Verbose:$False).PartComponent.Name
                        }
                        Else
                        {
                            $GroupMembership = $GroupObject.PSBase.Invoke('Members') | ForEach-Object -Process {
                                $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)
                            }
                        }
                        
                        If($Member -in $GroupMembership)
                        {
                            Write-Verbose -Message "Member '$Member' added to $Group group on $env:COMPUTERNAME." -Verbose:$VerboseSwitch
                        }
                    }
                    Catch
                    {
                        Write-Error -Message "Unable to add member '$Member' to $Group group on $env:COMPUTERNAME. $($_.Exception.InnerException.Message)"
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
        
        $InvokeArgs.ScriptBlock = $Scriptblock
        
        Invoke-Command @InvokeArgs
    }
    
    End{}
}


