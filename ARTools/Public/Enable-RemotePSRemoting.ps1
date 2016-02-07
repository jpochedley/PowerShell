#requires -Version 2
function Enable-RemotePSRemoting
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $False)]
        [switch]$Force,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{
        $InvokeArgs = @{
            Path = 'win32_process'
            Name = 'Create'
            ArgumentList = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command Enable-PSRemoting -Force'
            ErrorAction = 'Stop'
        }
        
        If($null -ne $Credential)
        {
            $InvokeArgs.Credential = $Credential
        }
    }

    Process{
        Foreach($Computer in $ComputerName)
        {
            If(Test-Connection -ComputerName $Computer -Quiet -Count 1)
            {
                If($null -ne $Credential)
                {
                    $null = Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue -ErrorVariable Test -Credential $Credential
                }
                Else
                {
                    $null = Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue -ErrorVariable Test
                }

                If($Test -ne $null -or $Force)
                {
                    Write-Verbose -Message "Enabling PSRemoting on $Computer ..."
                    Try
                    {
                        $null = Invoke-WmiMethod @InvokeArgs -ComputerName $Computer
                        
                        $StartTime = Get-Date
                        
                        Write-Verbose -Message 'Please wait ...'
                    
                        do
                        {
                            $TimedOut = $WSManEnabled = $False
                            
                            If((Get-Date)-$StartTime -gt (New-TimeSpan -Minutes 1))
                            {
                                $TimedOut = $True
                            }
                            Else
                            {
                                Try
                                {
                                    If($null -ne $Credential)
                                    {
                                        $null = Test-WSMan -ComputerName $Computer -ErrorAction Stop -Credential $Credential
                                    }
                                    Else
                                    {
                                        $null = Test-WSMan -ComputerName $Computer -ErrorAction Stop
                                    }
                                    
                                    $WSManEnabled = $True
                                }
                                Catch
                                {
                                    $WSManEnabled = $False
                                }
                            }
                        }
                        until($WSManEnabled -or $TimedOut)
                    
                        If($WSManEnabled)
                        {
                            Write-Verbose -Message "PSRemoting enabled on $Computer successfully."
                        }
                        Else
                        {
                            Write-Warning -Message "Failure. PSRemoting not enabled on $Computer."
                        }
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to create remote process on $Computer. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Verbose -Message "PSRemoting is already enabled on $Computer."
                }
            }
            Else
            {
                Write-Warning -Message "Cannot connect to $Computer. Verify that the computer exists on the network and that the name provided is spelled correctly."
            }
        }
    }

    End{}
}


