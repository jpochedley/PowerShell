#requires -Version 2
function Restart-CNS 
{
    [cmdletbinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]

    Param(
        [Parameter(Mandatory = $True)]
        [string]$Server,
        
        [Parameter(Mandatory = $False)]
        [string[]]$ApplicationPool = ('DefaultAppPool', 'TiCBalancingModulePool'),
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{}

    Process{
        $ScriptBlock = {
            $ApplicationPool = $Using:ApplicationPool
            $VerbosePreference = $Using:VerbosePreference
            
            Try
            {
                Import-Module -Name WebAdministration -ErrorAction Stop -Verbose:$False
                Foreach($Item in $ApplicationPool)
                {
                    Try
                    {
                        Write-Verbose -Message "Restarting application pool $Item ..."
                        Restart-WebAppPool -Name $Item -Verbose:$False
                        Write-Verbose -Message "Application pool $Item restarted successfully."
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to restart application pool $Item. $($_.Exception.Message)"
                        Write-Warning -Message "Please log in to $ENV:COMPUTERNAME and attempt to restart the application pool $Item."
                    }
                }
            }
            Catch
            {
                Write-Warning -Message "Unable to import WebAdministration module. Please log in to $ENV:COMPUTERNAME and restart the application pools $($ApplicationPool -join ' & ')."
            }
        }
        
        $InvokeArgs = @{
            ComputerName = $Server
        }
    
        If($null -ne $Credential)
        {
            $InvokeArgs.Credential = $Credential
        }
        
        If($PSCmdlet.ShouldProcess('CNS','Restart')){
            $InvokeArgs.ComputerName = Test-PSRemoting @InvokeArgs -WarningAction $WarningPreference
        
            If($null -eq $InvokeArgs.ComputerName)
            {
                Break
            }
        
            $InvokeArgs.ScriptBlock = $ScriptBlock
        
            Invoke-Command @InvokeArgs
        }
    }

    End{}
}


