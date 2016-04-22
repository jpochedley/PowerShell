#requires -Version 2
function Disconnect-LoggedOnUser
{
    [cmdletbinding()]
    
    Param(
        [Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $True,Position = 1,ValueFromPipelineByPropertyName = $True)]
        [int]$ID
    )
    
    Begin{}
    
    Process{
        $ProcessInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "$env:windir\System32\logoff.exe"
        $ProcessInfo.RedirectStandardError = $True
        $ProcessInfo.RedirectStandardOutput = $True
        $ProcessInfo.CreateNoWindow = $True
        $ProcessInfo.UseShellExecute = $False
        $ProcessInfo.Arguments = "$ID /SERVER:$ComputerName"
        $Process = New-Object -TypeName System.Diagnostics.Process
        If(Test-Path -Path "$env:windir\System32\logoff.exe")
        {
            $Process.StartInfo = $ProcessInfo
            $null = $Process.Start()
            $Process.WaitForExit()
            #$ProcessOutput = $Process.StandardOutput.ReadToEnd().Trim() -split "`n"
            $ProcessError = $Process.StandardError.ReadToEnd().Trim()
            If($ProcessError)
            {
                Write-Warning -Message "Unable to logoff Session ID $ID on $($ComputerName.ToUpper()). $ProcessError."
            }
        }
        Else
        {
            Write-Warning -Message 'Logoff.exe is not available.'
        }
        
    }
    
    End{}
}


