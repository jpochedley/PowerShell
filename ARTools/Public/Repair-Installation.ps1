#requires -Version 2
function Repair-Installation
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $True,ParameterSetName = 'MSI',ValueFromPipelineByPropertyName = $True)]
        [ValidatePattern("^\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$")]
        [string]$SoftwareCode,
        
        [Parameter(Mandatory = $False)]
        [ValidateSet('FPECMS','FPUM')]
        [string]$RepairParameters = 'FPUM',
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{}

    Process{
        [scriptblock]$ScriptBlock = {
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
        
            Write-Verbose -Message "Starting repair of $Using:SoftwareCode using repair parameters $Using:RepairParameters ..." -Verbose:$VerboseSwitch
            Start-Process -FilePath "$env:windir\System32\msiexec.exe" -ArgumentList "/$Using:RepairParameters $Using:SoftwareCode /qn" -Wait -Verb RunAs -WindowStyle Hidden
            Write-Verbose -Message "Repair of $Using:SoftwareCode finished." -Verbose:$VerboseSwitch
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


