#requires -Version 3
function Connect-Viewer
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $False)]
        [switch]$Hidden,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{
        If(-not (Test-Path -Path "$env:SMS_ADMIN_UI_PATH\cmrcviewer.exe"))
        {
            Write-Warning -Message 'Could not find Remote Control Viewer.'
            Break
        }
    }
    
    Process{
        [scriptblock]$InitialScriptBlock = {
            $VerbosePreference = $Using:VerbosePreference
            $WarningPreference = $Using:WarningPreference

            Write-Verbose -Message "Backing up default Remote Control Viewer settings on $env:COMPUTERNAME ..."

            $Backup = Start-Process -FilePath $env:windir\system32\reg.exe -ArgumentList "export `"HKLM\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control`" `"$env:windir\Temp\RemoteControlDefaultSettings.reg`"" -PassThru -Wait
            
            If($Backup.ExitCode -ne 0)
            {
                Throw "Problem encountered backing up Remote Control Viewer settings on $env:COMPUTERNAME."
            }
            Else
            {
                Write-Verbose -Message "Default Remote Control Viewer settings on $env:COMPUTERNAME backed up successfully."
            
                'Permission Required', 'RemCtrl Taskbar Icon', 'RemCtrl Connection Bar', 'Audible Signal' |

                ForEach-Object -Process {
                    Write-Verbose -Message "Changing $_ setting on $env:COMPUTERNAME ..."
                    
                    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Name $_ -Value 0
                    
                    Write-Verbose -Message "$_ setting set to 0 on $env:COMPUTERNAME."
                }

                Write-Verbose -Message "Changing Access Level setting on $env:COMPUTERNAME ..."
                
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Name 'Access Level' -Value 1
                
                Write-Verbose -Message "Access Level setting set to 1 on $env:COMPUTERNAME."
            }
        }

        If($PSBoundParameters.ContainsKey('ComputerName'))
        {
            $InvokeArgs = @{
                ComputerName = $ComputerName
            }
    
            If($null -ne $Credential)
            {
                $InvokeArgs.Credential = $Credential
            }
        
            $InvokeArgs.ComputerName = $ComputerName = Test-PSRemoting @InvokeArgs -WarningAction $WarningPreference

            If($Hidden)
            {
                If($null -ne $ComputerName)
                {
                    $InvokeArgs.ScriptBlock = $InitialScriptBlock
        
                    Invoke-Command @InvokeArgs -ErrorAction Stop
                }
            }

            Foreach($Computer in $ComputerName)
            {
                Start-Process -FilePath "$env:SMS_ADMIN_UI_PATH\cmrcviewer.exe" -ArgumentList "$Computer" -WindowStyle Maximized
            }
            
            If($Hidden)
            {
                [scriptblock]$CleanupScriptBlock = {
                    $VerbosePreference = $Using:VerbosePreference
                    $WarningPreference = $Using:WarningPreference
                        
                    Write-Verbose -Message "Restoring default Remote Control Viewer settings on $env:COMPUTERNAME ..."
                        
                    $Restore = Start-Process -FilePath $env:windir\system32\reg.exe -ArgumentList "import `"$env:windir\Temp\RemoteControlDefaultSettings.reg`"" -PassThru -Wait
                        
                    If($Restore.ExitCode -ne 0)
                    {
                        Write-Error "Problem encountered restoring Remote Control Viewer settings on $env:COMPUTERNAME."
                    }
                    Else
                    {
                        Write-Verbose -Message "Default Remote Control Viewer settings on $env:COMPUTERNAME restored successfully."
                            
                        Remove-Item -Path "$env:windir\Temp\RemoteControlDefaultSettings.reg" -Force
                    }
                }

                If($null -ne $ComputerName)
                {
                    If($psISE)
                    {
                        Add-Type -AssemblyName System.Windows.Forms
                        $null = [System.Windows.Forms.MessageBox]::Show('Click OK to reset Remote Control Viewer settings ...')
                    }
                    Else
                    {
                        Write-Output 'Press any key to reset Remote Control Viewer settings ...'

                        $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                    }

                    $InvokeArgs.ScriptBlock = $CleanupScriptBlock
        
                    Invoke-Command @InvokeArgs
                }
            }
        }
        Else
        {
            Start-Process -FilePath "$env:SMS_ADMIN_UI_PATH\cmrcviewer.exe"
        }
    }

    End{}
}
