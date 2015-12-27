#requires -Version 3
function Invoke-ConfigMgrInstallation
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $True,Position = 1)]
        [ValidateSet('Install','Uninstall')]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [pscredential]$Credential = $null
    )

    DynamicParam{
        $CMSite = Get-ConfigMgrSite
        
        $RuntimeParamDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        
        $ValidateSetOptions = Get-WmiObject -ComputerName $CMSite.SiteServer -Namespace "root\SMS\site_$($CMSite.SiteCode)" -Class SMS_Application -Filter 'IsLatest=1' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalizedDisplayName
        
        $RuntimeParameter = New-DynamicParameter -Name ApplicationName -ValidateSetOptions $ValidateSetOptions
        
        $RuntimeParamDictionary.Add('ApplicationName', $RuntimeParameter)
        
        return $RuntimeParamDictionary
    }

    Begin{
        $ApplicationName = $PSBoundParameters['ApplicationName']
    }

    Process{
        [scriptblock]$ScriptBlock = {
            $VerbosePreference = $Using:VerbosePreference
            $WarningPreference = $Using:WarningPreference
            $ApplicationName = $Using:ApplicationName
            
            $EnforcePreference = [uint32]0
    
            $Application = Get-CimInstance -Namespace 'root/ccm/ClientSDK' -Class CCM_Application -Verbose:$false |
            Where-Object -FilterScript {
                $_.Name -eq "$ApplicationName"
            } |
            Select-Object -First 1
    
            If($Application)
            {
                If($Application.ResolvedState -eq 'Available')
                {
                    Try
                    {
                        Write-Verbose -Message "Performing $(($Using:Action).ToLower())ation of $ApplicationName on $env:COMPUTERNAME ..."
                    
                        $null = Invoke-CimMethod -Namespace root/ccm/ClientSDK -ClassName CCM_Application -MethodName $Using:Action -Arguments @{
                            ID                = $Application.ID
                            Revision          = $Application.Revision
                            IsMachineTarget   = $Application.Target
                            EnforcePreference = $EnforcePreference
                            Priority          = 'Normal'
                            IsRebootIfNeeded  = $false
                        } -ErrorAction Stop -Verbose:$false
                    
                        Write-Verbose -Message "$ApplicationName $(($Using:Action).ToLower())ation on $env:COMPUTERNAME triggered successfully."
                    }
                    Catch
                    {
                        Write-Warning -Message "$ApplicationName $(($Using:Action).ToLower())ation on $env:COMPUTERNAME failed. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Warning -Message "$ApplicationName cannot be $(($Using:Action).ToLower())ed on $env:COMPUTERNAME. Application state is $($Application.ResolvedState)."
                }
            }
            Else
            {
                Write-Warning -Message "$ApplicationName cannot be $(($Using:Action).ToLower())ed on $env:COMPUTERNAME. Application not found."
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
