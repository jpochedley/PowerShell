#requires -Version 2
function Start-TeRClientSettingsManager
{
    [cmdletbinding()]
    
    Param(
		[Parameter(Mandatory = $True)]
		[string]$ExecutablePath
	)
    
    Begin{}
    
    Process{
        Try
        {
            Start-Process -FilePath $ExecutablePath -ErrorAction Stop
        }
        Catch
        {
            Write-Warning -Message "Cannot start TeR Client Settings Manager $($_.Exception.Message)"
        }
    }
    
    End{}
}


