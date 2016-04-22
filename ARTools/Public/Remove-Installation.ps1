#requires -Version 2
function Remove-Installation
{
    [cmdletbinding(DefaultParameterSetName = 'MSI')]

    Param(
        [Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $True,ParameterSetName = 'MSI',ValueFromPipelineByPropertyName = $True)]
        [ValidatePattern("^\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$")]
        [string]$SoftwareCode,

        [Parameter(Mandatory = $True,ParameterSetName = 'Other')]
        [string]$ProductName,

        [Parameter(Mandatory = $True,ParameterSetName = 'Other')]
        [string]$FilePath,

        [Parameter(Mandatory = $True,ParameterSetName = 'Other')]
        [string]$ArgumentList,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential
    )

    Begin{}

    Process{
        [scriptblock]$ScriptBlock = {
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference

            $SoftwareCode = $Using:SoftwareCode
            $ProductName = $Using:ProductName
            $FilePath = $Using:FilePath
            $ArgumentList = $Using:ArgumentList
            
            If(-not [string]::IsNullOrEmpty($SoftwareCode))
            {
                Write-Verbose -Message "Beginning uninstallation of MSI package $SoftwareCode on $env:COMPUTERNAME ..." -Verbose:$VerboseSwitch
                $ArgumentList = "/X $SoftwareCode /qn /norestart"
                $FilePath = "$env:windir\System32\msiexec.exe"
            }
            Else
            {
                Write-Verbose -Message "Beginning uninstallation of $ProductName on $env:COMPUTERNAME ..." -Verbose:$VerboseSwitch
            }

            Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -Wait -WindowStyle Hidden
            
            If(-not [string]::IsNullOrEmpty($SoftwareCode))
            {
                $IsPresent = Get-WmiObject -Namespace root/cimv2/sms -Class sms_installedsoftware -Filter "SoftwareCode='$SoftwareCode'"

                If($IsPresent)
                {
                    Write-Warning -Message "Uninstallation of  MSI package $SoftwareCode failed on $env:COMPUTERNAME."
                }
                Else
                {
                    Write-Verbose -Message "Uninstallation of  MSI package $SoftwareCode on $env:COMPUTERNAME completed successfully." -Verbose:$VerboseSwitch
                }
            }
            Else
            {
                $IsPresent = Get-WmiObject -Namespace root/cimv2/sms -Class sms_installedsoftware -Filter "ProductName LIKE '%$ProductName%'"

                If($IsPresent)
                {
                    Write-Warning -Message "Uninstallation of $ProductName failed on $env:COMPUTERNAME."
                }
                Else
                {
                    Write-Verbose -Message "Uninstallation of $ProductName on $env:COMPUTERNAME completed successfully." -Verbose:$VerboseSwitch
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
        
        $InvokeArgs.ScriptBlock = $ScriptBlock
        
        Invoke-Command @InvokeArgs
    }

    End{}
}


