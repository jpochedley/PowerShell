#requires -Version 3
function Get-Monitor
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,Position = 0)]
        [string[]]$ComputerName
    )

    Begin{}

    Process{
        $ScriptBlock = {
            Try
            {
                $Monitors = Get-WmiObject -Class wmimonitorid -Namespace root/wmi -ErrorAction Stop
                Foreach($Monitor in $Monitors)
                {
                    If($null -ne $Monitor.UserFriendlyName)
                    {
                        $Model = [System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)
                    }
                    Else
                    {
                        $Model = 'N/A'
                    }
                    If($null -ne $Monitor.SerialNumberID)
                    {
                        $SerialNumber = [System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)
                        If($SerialNumber -eq 0)
                        {
                            $SerialNumber = 'N/A'
                        }
                    }
                    Else
                    {
                        $SerialNumber = 'N/A'
                    }
                    New-Object -TypeName PSCustomObject -Property @{
                        ComputerName = $Env:COMPUTERNAME
                        Model        = $Model
                        SerialNumber = $SerialNumber
                    }
                }
            }
            Catch
            {
                Write-Warning -Message "Cannot query WMIMonitorID WMI class on $Computer. $($_.Exception.Message)"
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
        
        Invoke-Command @InvokeArgs
    }

    End{}
}
