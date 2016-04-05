#requires -Version 2
function Reset-WindowsUpdate
{
    [cmdletbinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]

    Param(
        [Parameter(Mandatory = $True)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{}

    Process{
        [scriptblock]$Scriptblock = {
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference
            
            Try
            {
                'bits', 'wuauserv', 'appidsvc', 'cryptsvc' | ForEach-Object -Process {
                    Write-Verbose -Message "Stopping service : $_" -Verbose:$VerboseSwitch
                    Stop-Service -Name $_ -Force -Confirm:$False -ErrorAction Stop
                }
                
                Write-Verbose -Message "Deleting qmgr*.dat files ..." -Verbose:$VerboseSwitch
                Get-ChildItem -Path "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat" | Remove-Item -Force -Confirm:$False

                Write-Verbose -Message "Renaming SoftwareDistribution and Catroot2 folders." -Verbose:$VerboseSwitch
                
                "$env:SystemRoot\SoftwareDistribution", "$env:SystemRoot\system32\catroot2" | 

                ForEach-Object -Process {
                    $Path = $_
                    
                    $NewName = "$(Split-Path -Path $Path -Leaf).bak"
                    
                    Remove-Item -Path "$Path.bak" -Recurse -Force -Confirm:$False -ErrorAction SilentlyContinue

                    Rename-Item -Path $Path -NewName $NewName -Force -Confirm:$False
                }

                Write-Verbose -Message "Resetting permissions for BITS and WUASERV services ..." -Verbose:$VerboseSwitch

                Start-Process -FilePath "$env:SystemRoot\System32\sc.exe" -ArgumentList 'sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)' -Wait -WindowStyle Hidden

                Start-Process -FilePath "$env:SystemRoot\System32\sc.exe" -ArgumentList 'sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)' -Wait -WindowStyle Hidden

                'atl.dll', 'urlmon.dll', 'mshtml.dll', 'shdocvw.dll', 'browseui.dll', 'jscript.dll', 'vbscript.dll', 'scrrun.dll', 
                'msxml.dll', 'msxml3.dll', 'msxml6.dll', 'actxprxy.dll', 'softpub.dll', 'wintrust.dll', 'dssenh.dll', 'rsaenh.dll', 
                'gpkcsp.dll', 'sccbase.dll', 'slbcsp.dll', 'cryptdlg.dll', 'oleaut32.dll', 'ole32.dll', 'shell32.dll', 'initpki.dll', 
                'wuapi.dll', 'wuaueng.dll', 'wuaueng1.dll', 'wucltui.dll', 'wups.dll', 'wups2.dll', 'wuweb.dll', 'qmgr.dll', 'qmgrprxy.dll', 
                'wucltux.dll', 'muweb.dll', 'wuwebv.dll' |

                ForEach-Object -Process {
                    Write-Verbose -Message "Re-registering dll: $_" -Verbose:$VerboseSwitch
                    Start-Process -FilePath "$env:SystemRoot\System32\regsvr32.exe" -ArgumentList "/s $_" -Wait -WindowStyle Hidden
                }
                
                Write-Verbose -Message "Resetting network adapter." -Verbose:$VerboseSwitch
                Start-Process -FilePath "$env:SystemRoot\System32\netsh.exe" -ArgumentList 'winsock reset' -Wait -WindowStyle Hidden

                'bits', 'wuauserv', 'appidsvc', 'cryptsvc' | ForEach-Object -Process {
                    Write-Verbose -Message "Starting service: $_" -Verbose:$VerboseSwitch
                    Start-Service -Name $_
                }
            }
            Catch
            {
                Write-Warning -Message "$($_.Exception.Message)"
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
        
        If($PSCmdlet.ShouldProcess($ComputerName -join ', '))
        {
            Invoke-Command @InvokeArgs -HideComputerName
        }
    }
    
    End{}
}


