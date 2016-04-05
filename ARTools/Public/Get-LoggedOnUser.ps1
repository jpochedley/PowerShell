#requires -Version 3
function Get-LoggedOnUser
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $False)]
        [string[]]$ComputerName = 'Localhost',
        
        [Parameter(Mandatory = $False)]
        [string]$Username = $null,

        [Parameter(Mandatory = $False)]
        [switch]$RPC,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{
        $Jobs = @()
        
        $Computer = $null
        
        [scriptblock]$Scriptblock = {
            $Computer = $Using:Computer
            
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference
            
            $LockScreenPresent = Get-Process -Name LogonUI -ErrorAction SilentlyContinue
            
            If($LockScreenPresent){$LockScreenActive = $True}
            Else{$LockScreenActive = $False}

            $ProcessInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "$env:windir\System32\quser.exe"
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $False
            
            If($null -ne $Computer)
            {
                $ProcessInfo.Arguments = "/Server:$Computer"
            }
            Else
            {
                $Computer = $env:COMPUTERNAME
            }
            
            $Process = New-Object -TypeName System.Diagnostics.Process
            
            If(Test-Path -Path "$env:windir\System32\quser.exe")
            {
                $Process.StartInfo = $ProcessInfo
                $null = $Process.Start()
                $Process.WaitForExit()
                $ProcessOutput = $Process.StandardOutput.ReadToEnd().Trim() -split "`n" |
                Select-Object -Skip 1 |
                ForEach-Object -Process {
                    $CurrentLine = $_.Trim() -Replace '\s+', ' ' -Split '\s'
                    $HashProps = @{
                        Username     = $CurrentLine[0] -replace '>'
                        ComputerName = $Computer.ToUpper()
                        LockScreenActive = $LockScreenActive
                    }

                    If($CurrentLine[2] -eq 'Disc') 
                    {
                        $HashProps.SessionName = $null
                        $HashProps.Id = $CurrentLine[1]
                        $HashProps.State = $CurrentLine[2]
                        $HashProps.IdleTime = $CurrentLine[3]
                        $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
                    } 
                    Else
                    {
                        $HashProps.SessionName = $CurrentLine[1]
                        $HashProps.Id = $CurrentLine[2]
                        $HashProps.State = $CurrentLine[3]
                        $HashProps.IdleTime = $CurrentLine[4]
                        $HashProps.LogonTime = $CurrentLine[5..7] -join ' '
                    }

                    New-Object -TypeName PSCustomObject -Property $HashProps |
                    Where-Object -FilterScript {
                        $_.UserName -match '\w'
                    } |
                    Select-Object -Property UserName, ComputerName, LockScreenActive, SessionName, Id, State, IdleTime, LogonTime
                }
                $ProcessError = $Process.StandardError.ReadToEnd().Trim()

                If($ProcessError -notmatch '\w')
                {
                    $ProcessOutput
                }
                ElseIf($ProcessError -match 'No User exists for *')
                {
                    Write-Verbose -Message "No users logged on to $($Computer.ToUpper())." -Verbose:$VerboseSwitch
                }
                ElseIf($ProcessError -match 1722)
                {
                    Write-Warning -Message "Cannot connect to $($Computer.ToUpper()). The RPC server is unavailable."
                }
                ElseIf($ProcessError -match 5)
                {
                    Write-Warning -Message "Cannot connect to $($Computer.ToUpper()). Access is denied."
                }
                Else
                {
                    $ProcessError
                }
            }
            Else
            {
                Write-Warning -Message "Quser is not available on $($Computer.ToUpper())."
            }
        }
    }

    Process{
        If($RPC)
        {
            $ThrottledArray = Split-Array -InputObject $ComputerName
            
            Foreach($Array in $ThrottledArray)
            {
                $Jobs = @()
            
                Foreach($Computer in $Array)
                {
                    $Jobs += Start-Job -ScriptBlock $Scriptblock -WarningAction $WarningPreference
                }

                If($PSBoundParameters.ContainsKey('Username'))
                {
                    $Jobs |
                    Wait-Job |
                    Receive-Job |
                    Where-Object -Property Username -EQ -Value $Username
                }
                Else
                {
                    $Jobs |
                    Wait-Job |
                    Receive-Job
                }

                $Jobs | Remove-Job -Force
            }
        }
        Else
        {
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
        
            $Results = Invoke-Command @InvokeArgs -HideComputerName

            If($PSBoundParameters.ContainsKey('Username'))
            {
                $Results | Where-Object -Property Username -EQ -Value $Username
            }
            Else
            {
                $Results
            }
        }
    }
}


