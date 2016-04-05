#requires -Version 2
function Invoke-ConfigMgrUpdate
{
    [cmdletbinding(DefaultParameterSetName = 'SpecificAction')]

    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $False,ParameterSetName = 'SpecificAction')]
        [ValidateSet('HardwareInventoryCycle','SoftwareUpdatesDeploymentEvaluationCycle','SoftwareUpdatesScanCycle','SoftwareInventoryCycle','SoftwareMeteringUsageReportCycle','WindowsInstallerSourceListUpdateCycle','MachinePolicyRetrievalandEvaluationCycle','DiscoveryDataCollectionCycle','ApplicationDeploymentEvaluationCycle')]
        [string[]]$Action = @('ApplicationDeploymentEvaluationCycle', 'MachinePolicyRetrievalandEvaluationCycle'),

        [Parameter(Mandatory = $true,ParameterSetName = 'AllActions')]
        [switch]$AllActions,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )
    
    Begin{
        $ConfigMgrActions = @{
            ApplicationDeploymentEvaluationCycle     = '{00000000-0000-0000-0000-000000000121}'
            DiscoveryDataCollectionCycle             = '{00000000-0000-0000-0000-000000000003}'
            HardwareInventoryCycle                   = '{00000000-0000-0000-0000-000000000001}'
            MachinePolicyRetrievalandEvaluationCycle = '{00000000-0000-0000-0000-000000000021}'
            SoftwareInventoryCycle                   = '{00000000-0000-0000-0000-000000000002}'
            SoftwareMeteringUsageReportCycle         = '{00000000-0000-0000-0000-000000000031}'
            SoftwareUpdatesDeploymentEvaluationCycle = '{00000000-0000-0000-0000-000000000108}'
            SoftwareUpdatesScanCycle                 = '{00000000-0000-0000-0000-000000000113}'
            WindowsInstallerSourceListUpdateCycle    = '{00000000-0000-0000-0000-000000000032}'
        }

        If($AllActions)
        {
            $Action = 'HardwareInventoryCycle', 'SoftwareUpdatesDeploymentEvaluationCycle', 'SoftwareUpdatesScanCycle', 'SoftwareInventoryCycle', 'SoftwareMeteringUsageReportCycle', 'WindowsInstallerSourceListUpdateCycle', 'MachinePolicyRetrievalandEvaluationCycle', 'DiscoveryDataCollectionCycle', 'ApplicationDeploymentEvaluationCycle'
        }
    }

    Process{
        [scriptblock]$Scriptblock = {
            $Action = $Using:Action
            $ConfigMgrActions = $Using:ConfigMgrActions
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference
            
            Foreach($Trigger in $Action)
            {
                $ScheduleID = $ConfigMgrActions.$Trigger

                Write-Debug -Message "$ScheduleID"
                
                Try
                {
                    Write-Verbose -Message "Invoking $Trigger action on $env:COMPUTERNAME ..." -Verbose:$VerboseSwitch
                    $null = Invoke-CimMethod -Class sms_client -Namespace root\ccm -MethodName triggerschedule -Arguments @{
                        sScheduleID = $ScheduleID
                    } -ErrorAction Stop -Verbose:$False
                    Write-Verbose -Message "$Trigger action invoked on $env:COMPUTERNAME successfully." -Verbose:$VerboseSwitch
                }
                Catch
                {
                    Write-Warning -Message "Could not invoke $Trigger action on $env:COMPUTERNAME. $($_.Exception.Message)"
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


