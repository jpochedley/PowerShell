function Add-LocalGroupMember
{
    [CmdletBinding()]
    
    param
    (
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = 'localhost',
        
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [ValidateScript({
            $Username = $PSItem
                    
            Try
            {
                $null = Get-ADGroup -Identity $Username -ErrorAction Stop
                $True
            }
            Catch
            {
                Try
                {
                    $null = Get-ADUser -Identity $Username -ErrorAction Stop
                    $True
                }
                Catch
                {
                    Throw "Cannot find user or group with identity: '$Username'."
                }
            }
        })]
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
            $VerbosePreference = $Using:VerbosePreference
            $WarningPreference = $Using:WarningPreference
            
            $GroupObject = [ADSI]"WinNT://$env:COMPUTERNAME/$Using:Group"
        
            If($null -ne $GroupObject)
            {
                Foreach($Member in $Using:Name)
                {
                    Try
                    {
                        $GroupObject.Add("WinNT://$env:USERDOMAIN/$Member")
                        
                        If($PSVersionTable.PSVersion.Major -ge 3)
                        {
                            $GroupMembership = (Get-CimInstance -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$env:COMPUTERNAME',Name='$Using:Group'`"" -Verbose:$False).PartComponent.Name
                        }
                        Else
                        {
                            $GroupMembership = $GroupObject.PSBase.Invoke('Members') | ForEach-Object -Process {
                                $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)
                            }
                        }
                        
                        If($Member -in $GroupMembership)
                        {
                            Write-Verbose -Message "Member '$Member' added to $Using:Group group on $env:COMPUTERNAME."
                        }
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to add member '$Member' to $Using:Group group on $env:COMPUTERNAME. $($_.Exception.InnerException.Message)"
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
