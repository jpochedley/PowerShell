<#
	.EXAMPLE
	Invoke-Installation -ComputerName VM-ADRIANR -ProductName CDM -WorkingDirectory '\\corp-sdp1\install$\Fiserv\CDM-8dot1' -FilePath CDMInstall.ps1 -PowerShellScript -Credential $MyCredential -Verbose
#>
function Invoke-Installation
{
    [cmdletbinding(DefaultParameterSetName = 'MSI')]

    Param(
        [Parameter(Mandatory = $True,Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $True,ParameterSetName = 'MSI')]
        [ValidatePattern("^\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$")]
        [string]$SoftwareCode,

        [Parameter(Mandatory = $True,ParameterSetName = 'Other')]
        [string]$ProductName,

        [Parameter(Mandatory = $True)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $True)]
        [string]$FilePath,

        [Parameter(Mandatory = $False)]
        [string]$ArgumentList,
        
        [Parameter(Mandatory = $False)]
        [switch]$PowerShellScript,
        
        [Parameter(Mandatory = $True)]
        [pscredential]$Credential
    )

    Begin{
        $Credential = $PSBoundParameters.Credential
        $User = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password

        If($User -like "$env:USERDOMAIN*")
        {
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
            $Domain = $env:USERDOMAIN
            $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
            $PrincipalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ContextType, $Domain
            $CredentialValidity = $PrincipalContext.ValidateCredentials($User,$Password)
            If(-not $CredentialValidity)
            {
                Write-Warning -Message 'Logon failure: Unknown username or bad password.' 
                Break
            }
        }
    }

    Process{
        [scriptblock]$ScriptBlock = {
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference

            $Password = $Using:Password
            $User = $Using:User
            $SoftwareCode = $Using:SoftwareCode
            $ProductName = $Using:ProductName
            $WorkingDirectory = $Using:WorkingDirectory
            $FilePath = $Using:FilePath
            $ArgumentList = $Using:ArgumentList
            $PowerShellScript = $Using:PowerShellScript

            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($User, $SecurePassword)

            Try
            {
                Write-Verbose -Message 'Mapping installation directory ...' -Verbose:$VerboseSwitch

                $null = New-PSDrive -Name Temp -PSProvider FileSystem -Root $WorkingDirectory -Credential $Credential -ErrorAction Stop

                Write-Verbose -Message 'Installation directory mapped successfully.' -Verbose:$VerboseSwitch

                Try
                {
                    If(-not [string]::IsNullOrEmpty($SoftwareCode))
                    {
                        Write-Verbose -Message "Beginning installation of MSI package $SoftwareCode on $env:COMPUTERNAME ..." -Verbose:$VerboseSwitch
                    }
                    Else
                    {
                        Write-Verbose -Message "Beginning installation of $ProductName on $env:COMPUTERNAME ..." -Verbose:$VerboseSwitch
                    }

                    If($PowerShellScript)
                    {
                        Push-Location -Path Temp:\

						Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
                        
                        . ".\$FilePath" $ArgumentList
                        
                        Pop-Location
                    }
                    Else
                    {
                        Start-Process -WorkingDirectory Temp:\ -FilePath $FilePath -ArgumentList $ArgumentList -WindowStyle Hidden -Wait -ErrorAction Stop
                    }

                    If(-not [string]::IsNullOrEmpty($SoftwareCode))
                    {
                        $IsPresent = Get-WmiObject -Namespace root/cimv2/sms -Class sms_installedsoftware -Filter "SoftwareCode='$SoftwareCode'"

                        If($IsPresent)
                        {
                            Write-Verbose -Message "Installation of  MSI package $SoftwareCode on $env:COMPUTERNAME completed successfully." -Verbose:$VerboseSwitch
                        }
                        Else
                        {
                            Write-Warning -Message "Installation of  MSI package $SoftwareCode failed on $env:COMPUTERNAME."
                        }
                    }
                    Else
                    {
                        $IsPresent = Get-WmiObject -Namespace root/cimv2/sms -Class sms_installedsoftware -Filter "ProductName LIKE '%$ProductName%'"

                        If($IsPresent)
                        {
                            Write-Verbose -Message "Installation of $ProductName on $env:COMPUTERNAME completed successfully." -Verbose:$VerboseSwitch
                        }
                        Else
                        {
                            Write-Warning -Message "Installation of $ProductName failed on $env:COMPUTERNAME."
                        }
                    }
                }
                Catch
                {
                    $_
                }
            }
            Catch
            {
                $_
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


