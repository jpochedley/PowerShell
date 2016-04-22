#requires -Version 2
function Get-InstalledProgram
{  
    [CmdletBinding(DefaultParameterSetName = 'Default')]

    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('Name')]
        [string[]]$ComputerName = 'Localhost',

        [Parameter(Mandatory = $True,ParameterSetName = 'MSISearch')]
        [ValidatePattern("^\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$")]
        [string]$SoftwareCode = $null,

        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True,ParameterSetName = 'ExeSearch')]
        [string]$ProductName = $null,

        [Parameter(Mandatory = $False,ValueFromPipelineByPropertyName = $True,ParameterSetName = 'ExeSearch')]
        [Parameter(Mandatory = $False,ValueFromPipelineByPropertyName = $True,ParameterSetName = 'MSISearch')]
        [string]$ProductVersion = $null,

        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True,ParameterSetName = 'GenericSearch')]
        [string]$Filter = $null,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{}

    Process{
        [scriptblock]$ScriptBlock = {
            $WarningPreference = $Using:WarningPreference

            $Filter = $Using:Filter
            $SoftwareCode = $Using:SoftwareCode
            $ProductName = $($Using:ProductName).Replace('*','%')
            $ProductVersion = $($Using:ProductVersion).Replace('*','%')

            $Params = @{
                Namespace = 'root/cimv2/sms'
                Class     = 'sms_installedsoftware'
            }

            If(-not[string]::IsNullOrEmpty($Filter))
            {
                $Params.Filter = $Filter
            }

            If(-not[string]::IsNullOrEmpty($ProductName))
            {
                $Params.Filter = "ProductName LIKE '$ProductName'"
            }

            If(-not[string]::IsNullOrEmpty($SoftwareCode))
            {
                $Params.Filter = "SoftwareCode='$SoftwareCode'"
            }

            If(-not[string]::IsNullOrEmpty($ProductVersion))
            {
                If($Params.Filter)
                {
                    $Params.Filter += " AND ProductVersion LIKE '$ProductVersion'"
                }
                Else
                {
                    $Params.Filter = "ProductVersion LIKE '$ProductVersion'"
                }
            }
            
            Get-CimInstance @Params | Sort-Object ProductName
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


