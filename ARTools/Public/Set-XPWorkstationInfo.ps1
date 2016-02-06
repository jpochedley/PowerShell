#requires -Version 2
function Set-XPWorkstationInfo 
{
    [cmdletbinding(SupportsShouldProcess = $True)]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('Name')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $False,ParameterSetName = 'Default',ValueFromPipelineByPropertyName = $True)]
        [ValidatePattern('\d')]
        [string]$WorkstationNumber = $null,

        [Parameter(Mandatory = $False,ParameterSetName = 'Default',ValueFromPipelineByPropertyName = $True)]
        [ValidateSet('true','false')]
        [string]$SSLEnabled = $null,

        [Parameter(Mandatory = $False,ParameterSetName = 'Default',ValueFromPipelineByPropertyName = $True)]
        [ValidateSet('true','false')]
        [string]$AssignFromPC = $null,

        [Parameter(Mandatory = $False,ParameterSetName = 'Default',ValueFromPipelineByPropertyName = $True)]
        [string]$WorkstationDescription = $null,

        [Parameter(Mandatory = $False,ParameterSetName = 'Default',ValueFromPipelineByPropertyName = $True)]
        [string]$ApplicationServer = $null,

        [Parameter(Mandatory = $False,ParameterSetName = 'Default',ValueFromPipelineByPropertyName = $True)]
        [string]$ApplicationName = $null,

        [Parameter(Mandatory = $False,ParameterSetName = 'RenameConfigFiles',ValueFromPipelineByPropertyName = $True)]
        [Switch]$RenameConfigFiles,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null,

		[Parameter(Mandatory = $False)]
		[switch]$Force
    )

    Begin{}

    Process{
        $Properties = @{
            WorkstationNumber      = $null
            SSLEnabled             = $null
            AssignFromPC           = $null
            WorkstationDescription = $null
            ApplicationServer      = $null
            ApplicationName        = $null
        }

        $AvailableParams = 'WorkstationNumber', 'SSLEnabled', 'AssignFromPC', 'WorkstationDescription', 'ApplicationServer', 'ApplicationName'
        
        Foreach($Param in $AvailableParams)
        {
            If($PSBoundParameters.ContainsKey($Param))
            {
                $Properties.$Param = $PSBoundParameters.Item($Param)
            }
        }

        If($PSCmdlet.ParameterSetName -eq 'Default')
        {
            $ScriptBlock = {
                $Properties = $Using:Properties
                $AvailableParams = $Using:AvailableParams
                $VerbosePreference = $Using:VerbosePreference
				$Force = $Using:Force
                
                If([environment]::Is64BitOperatingSystem)
                {
                    $Path = "${env:ProgramFiles(x86)}\fiserv\xp2 workstation\client\configuration"
                }
                Else
                {
                    $Path = "$env:ProgramFiles\fiserv\xp2 workstation\client\configuration"
                }

                Write-Verbose -Message "Finding WorkstationOptionSettings XML file on $env:COMPUTERNAME ..."
                $XPWSSettings = Get-Item -Path "$Path\*WorkstationOptionSettings.xml" -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1
            
                If($null -ne $XPWSSettings)
                {
                    Write-Verbose -Message "WorkstationOptionSettings XML file found on $env:COMPUTERNAME."
                    [xml]$Workstation = Get-Content -Path $XPWSSettings.fullname -ErrorAction SilentlyContinue
                    Foreach($Param in $AvailableParams)
                    {
                        If($null -ne $Properties.$Param)
                        {
                            Write-Verbose -Message "Setting $Param to $($Properties.$Param) on $env:COMPUTERNAME ..."
                            $Workstation.WorkstationOptionsViewModel.$Param = $Properties.$Param
                        }
                    }

					If($Force)
					{
						Get-Process -Name xp2 -ErrorAction SilentlyContinue | Stop-Process
					}

                    Rename-Item -Path $XPWSSettings.fullname -NewName "$($XPWSSettings.basename)-$(Get-Date -Format yyyyMMddHHmmss).old" -Force
                    $Workstation.Save("$XPWSSettings")
                    Write-Verbose -Message "WorkstationOptionSettings XML file on $env:COMPUTERNAME updated successfully."
                }
                Else
                {
                    Write-Warning -Message "No WorkstationOptionSettings XML file found on $env:COMPUTERNAME."
                }
            }
        }
        
        ElseIf($PSCmdlet.ParameterSetName -eq 'RenameConfigFiles')
        {
            $ScriptBlock = {
                $VerbosePreference = $Using:VerbosePreference
				$Force = $Using:Force
                
                If([environment]::Is64BitOperatingSystem)
                {
                    $Path = "${env:ProgramFiles(x86)}\fiserv\xp2 workstation\client\configuration"
                }

                Else
                {
                    $Path = "$env:ProgramFiles\fiserv\xp2 workstation\client\configuration"
                }
                Write-Verbose -Message "Finding XP configuration files on $env:COMPUTERNAME ..."
                $NavigatorFile = Get-Item -Path "$Path\*NavigatorSettings.xml" -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1
                $WorkstationFile = Get-Item -Path "$Path\*WorkstationOptionSettings.xml" -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1
                $PrinterFile = Get-Item -Path "$Path\*PrinterOptionSettings.xml" -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1
                $ScannerFile = Get-Item -Path "$Path\*.ScannerSettings.xml" -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1
                
                If($Force)
				{
					Get-Process -Name xp2 -ErrorAction SilentlyContinue | Stop-Process
				}

                If($null -ne $NavigatorFile)
                {
                    Try
                    {
                        Write-Verbose -Message "Renaming NavigatorSettings XML file from $($NavigatorFile.basename) to $env:COMPUTERNAME.NavigatorSettings.xml ..."
                        Rename-Item -Path $NavigatorFile.fullname -NewName "$env:COMPUTERNAME.NavigatorSettings.xml" -ErrorAction Stop
                        Write-Verbose -Message "Successfully renamed NavigatorSettings XML file found on $env:COMPUTERNAME."
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to rename NavigatorSettings XML file found on $env:COMPUTERNAME. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Warning -Message "No NavigatorSettings XML file found on $env:COMPUTERNAME."
                }
                If($null -ne $WorkstationFile)
                {
                    Try
                    {
                        Write-Verbose -Message "Renaming WorkstationOptionSettings XML file from $($WorkstationFile.basename) to $env:COMPUTERNAME.WorkstationOptionSettings.xml ..."
                        Rename-Item -Path $WorkstationFile.fullname -NewName "$env:COMPUTERNAME.WorkstationOptionSettings.xml" -ErrorAction Stop
                        Write-Verbose -Message "Successfully renamed WorkstationOptionSettings XML file found on $env:COMPUTERNAME."
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to rename WorkstationOptionSettings XML file found on $env:COMPUTERNAME. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Warning -Message "No WorkstationOptionSettings XML file found on $env:COMPUTERNAME."
                }
                IF($null -ne $PrinterFile)
                {
                    Try
                    {
                        Write-Verbose -Message "Renaming PrinterOptionSettings XML file from $($PrinterFile.basename) to $env:COMPUTERNAME.PrinterOptionSettings.xml ..."
                        Rename-Item -Path $PrinterFile.fullname -NewName "$env:COMPUTERNAME.PrinterOptionSettings.xml" -ErrorAction Stop
                        Write-Verbose -Message "Successfully renamed PrinterOptionSettings XML file found on $env:COMPUTERNAME."
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to rename PrinterOptionSettings XML file found on $env:COMPUTERNAME. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Warning -Message "No PrinterOptionSettings XML file found on $env:COMPUTERNAME."
                }
                If($null -ne $ScannerFile)
                {
                    Try
                    {
                        Write-Verbose -Message "Renaming ScannerSettings XML file from $($ScannerFile.basename) to $env:COMPUTERNAME.ScannerSettings.xml ..."
                        Rename-Item -Path $ScannerFile.fullname -NewName "$env:COMPUTERNAME.ScannerSettings.xml" -ErrorAction Stop
                        Write-Verbose -Message "Successfully renamed ScannerSettings XML file found on $env:COMPUTERNAME."
                    }
                    Catch
                    {
                        Write-Warning -Message "Unable to rename ScannerSettings XML file found on $env:COMPUTERNAME. $($_.Exception.Message)"
                    }
                }
                Else
                {
                    Write-Warning -Message "No ScannerSettings XML file found on $env:COMPUTERNAME."
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
        
        If($PSCmdlet.ShouldProcess($($InvokeArgs.ComputerName -join ', '))){
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

# SIG # Begin signature block
# MIIVqAYJKoZIhvcNAQcCoIIVmTCCFZUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1ImeyEGk4hjNMwgFMfJMDuPQ
# 3TWgghF4MIIDmDCCAoCgAwIBAgIQFTuOD6CJ+6NFVKZ6+fJQbzANBgkqhkiG9w0B
# AQUFADBUMRMwEQYKCZImiZPyLGQBGRYDb3JnMR0wGwYKCZImiZPyLGQBGRYNYmxh
# Y2toaWxsc2ZjdTEeMBwGA1UEAxMVYmxhY2toaWxsc2ZjdS1CSENBLUNBMB4XDTEz
# MTIzMTIzMTgxMloXDTI4MTIzMTIzMjgxMlowVDETMBEGCgmSJomT8ixkARkWA29y
# ZzEdMBsGCgmSJomT8ixkARkWDWJsYWNraGlsbHNmY3UxHjAcBgNVBAMTFWJsYWNr
# aGlsbHNmY3UtQkhDQS1DQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# ANliX6Op+J0AilINTvsinTTROSxyz/PYuja5257UdIUqCyIjiZ+0GA+jLcKjU12y
# ijfQaQs9g/hQp3/BFxDtxXIfXVZ2pDTLPCdIecPgv8BbmFl09wHvD87h+fkqMddR
# l4GBQI0YWGF4Ntb3fypW4+9MOHIViAxwbxHIiqC4MICl764xAWNEjYXcVAOpnRb2
# EiqQG0xieg/D2kdYl1UpFmiLwMj/C5GgtllopHggEEN8KSas1Zzus7MQBHBq+QLd
# UvmuDo5fkCa3JN+1gmsxz2yTaIK1gRRpNZJH1/55EJ2iYfYT330Oi0i2CJzHHbki
# MCvci1Bw9NE0gs31FUrmY5cCAwEAAaNmMGQwEwYJKwYBBAGCNxQCBAYeBABDAEEw
# CwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFF/X6Uf5osbZ
# bSp9/Vsx1FcTcWzlMBAGCSsGAQQBgjcVAQQDAgEAMA0GCSqGSIb3DQEBBQUAA4IB
# AQAn5UDeAopPF/wpu5SL5DV7BrrvSvSDg1fmVHq5DKanQMp2rycfi51/W0RFwSHu
# LVaoUajhCl0GfX2ODHvLvKBJUxOSxienx9AaXkpi92nM85/qDeMzviQQRrcVTxj1
# Zt+/fJf4hKtlmuj+Yf/rMP2EU3nAr57YAO0FOFDkTHJu03/lx21aEUMLBlKDMdiq
# 4sJbbmoAFsYj7kmK5dCFTi1PwWocvgO1Ap5E1oV4SULAO+9LtFr4ISnfgL9m5gwD
# XPJXPQmHSIwAI6V97BDdRLahbC4RBp7oOvTQWOPvu0cx2yTcxmvQq1hPODivah3H
# qFWseGOy066WYThhNGBiuN0TMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8
# OzANBgkqhkiG9w0BAQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rl
# cm4gQ2FwZTEUMBIGA1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEd
# MBsGA1UECxMUVGhhd3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBU
# aW1lc3RhbXBpbmcgQ0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBe
# MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAu
# BgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcq
# b9y4JsRDc2vCvy5QWvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRr
# zV9FO9FEzkMScxeCi2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ
# 5/6M4lc/PcaS3Er4ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTa
# wIHwHw103pIiq8r3+3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrl
# Dqcsn6plINPYlujIfKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXEC
# AwEAAaOB+jCB9zAdBgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYB
# BQUHAQEEJjAkMCIGCCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIG
# A1UdEwEB/wQIMAYBAf8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50
# aGF3dGUuY29tL1RoYXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggr
# BgEFBQcDCDAOBgNVHQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMT
# EFRpbWVTdGFtcC0yMDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9o
# tfrjCR27T4IGXTdfplKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuw
# GsOO61mWAK3ODE2y0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlX
# Px13SYcqFgZepjhqIhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqY
# GxpQMA0GCSqGSIb3DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1h
# bnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGlu
# ZyBTZXJ2aWNlcyBDQSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1
# OVowYjELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9u
# MTQwMgYDVQQDEytTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25l
# ciAtIEc0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOn
# REm7Dv+h8GEKU5OwmNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBD
# SyKV7sIrQ8Gf2Gi0jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4ky
# W7BemVqonShQDhfultthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9
# JYDh6NIipdC6Anqhd5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aL
# M73ZY8hJnTrFxeozC9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+Z
# COEQKHKqzQIDAQABo4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAK
# BggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsG
# AQUFBzABhh5odHRwOi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUH
# MAKGK2h0dHA6Ly90cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIw
# PAYDVR0fBDUwMzAxoC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20v
# dHNzLWNhLWcyLmNybDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1w
# LTIwNDgtMjAdBgNVHQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgw
# FoAUX5r1blzMzHSa1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEq
# AEzwj2IwN3ijhCcHbxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9Cwm
# YzPkSWRtDebDZw73BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgE
# IKOq8UvEiCmRDoDREfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2
# DBYr8X9bCT2bW+IWyhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4ax
# gohd8D20UaF5Mysue7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzF
# HTx/kuDDvBzYBHUwggU/MIIEJ6ADAgECAhN4AAAAc4W2eXB+zY31AAAAAABzMA0G
# CSqGSIb3DQEBBQUAMFQxEzARBgoJkiaJk/IsZAEZFgNvcmcxHTAbBgoJkiaJk/Is
# ZAEZFg1ibGFja2hpbGxzZmN1MR4wHAYDVQQDExVibGFja2hpbGxzZmN1LUJIQ0Et
# Q0EwHhcNMTUwODEyMjMxNDM4WhcNMTYwODExMjMxNDM4WjB0MRMwEQYKCZImiZPy
# LGQBGRYDb3JnMR0wGwYKCZImiZPyLGQBGRYNYmxhY2toaWxsc2ZjdTEWMBQGA1UE
# CxMNVXNlciBBY2NvdW50czELMAkGA1UECxMCSVQxGTAXBgNVBAMTEEFkcmlhbiBS
# b2RyaWd1ZXowgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAJ5ZDMvhBWGsWxF+
# 1tGMRbvdsQx9th2SoTrEa4TGjPJo1S+NtPGditPNBlsJO9G/NhucjSwAT2Vc7/7a
# GQjNPaF3SyYwhSxVNfJjFqtpZjBgsxXDA4GlLYESC5LZ32ZR6ettkUSeHt/qXLAm
# 3hBJGca6FjTvO5lkayiqeZr9iRWnAgMBAAGjggJsMIICaDAlBgkrBgEEAYI3FAIE
# GB4WAEMAbwBkAGUAUwBpAGcAbgBpAG4AZzATBgNVHSUEDDAKBggrBgEFBQcDAzAL
# BgNVHQ8EBAMCB4AwHQYDVR0OBBYEFAhHzZ02lmNv/fQPGxn1kyQ8cmzlMB8GA1Ud
# IwQYMBaAFF/X6Uf5osbZbSp9/Vsx1FcTcWzlMIHWBgNVHR8Egc4wgcswgciggcWg
# gcKGgb9sZGFwOi8vL0NOPWJsYWNraGlsbHNmY3UtQkhDQS1DQSxDTj1CSENBLENO
# PUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1D
# b25maWd1cmF0aW9uLERDPWJsYWNraGlsbHNmY3UsREM9b3JnP2NlcnRpZmljYXRl
# UmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Q
# b2ludDCBzQYIKwYBBQUHAQEEgcAwgb0wgboGCCsGAQUFBzAChoGtbGRhcDovLy9D
# Tj1ibGFja2hpbGxzZmN1LUJIQ0EtQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUy
# MFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9YmxhY2to
# aWxsc2ZjdSxEQz1vcmc/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNl
# cnRpZmljYXRpb25BdXRob3JpdHkwNAYDVR0RBC0wK6ApBgorBgEEAYI3FAIDoBsM
# GWFkcmlhbnJAYmxhY2toaWxsc2ZjdS5vcmcwDQYJKoZIhvcNAQEFBQADggEBAJuf
# qHfcfbsgqU+3d0vNNHCeAF59ygRRQX55uPiATRt3KAaEah79BmwzmzvA1n4WBh4f
# sGwNSpzEl2cBChCANARhRh0018QpExSid+l3EEWg9jNFqRSkgDFz9UmTsIjPiXWk
# XPJzTtoyG/Ga0hcpOl/Lx7niAIfmxQcBmOsLXKsSlnrfmeiaBhB+D+K2fELmMuEs
# EiEIZeeV3A5/U4MbVFBa4OOhK2jiZzQgvjDDXwMs8MRYHFG5Y9rFE8wDHq21aLMY
# AItRKXqNOvGtq5bXZUJM+ZakmWBJhy/q7j451vxXcs1QmCJpOWgD5OpXK3TvycAa
# Iq7iiOlcvjMyOL3kdqkxggOaMIIDlgIBATBrMFQxEzARBgoJkiaJk/IsZAEZFgNv
# cmcxHTAbBgoJkiaJk/IsZAEZFg1ibGFja2hpbGxzZmN1MR4wHAYDVQQDExVibGFj
# a2hpbGxzZmN1LUJIQ0EtQ0ECE3gAAABzhbZ5cH7NjfUAAAAAAHMwCQYFKw4DAhoF
# AKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcN
# AQkEMRYEFI8WDsu4IFJmB54GZl+qs4POen5rMA0GCSqGSIb3DQEBAQUABIGAbews
# JLsE5SHU73HKKsqATYRQPu8sYzjWIYpeLHioOzSKcNUwNo4uYlBzGnall/YUXPTx
# WhpFS8/5iopEro1+TI+H9XN1ImrsvNEMOiKUiyrjyVa63CAIWcPrmpA96jzCzbOx
# XRbxG+mz8UoQxUNVn8or5g3sZm7txJD0DqdAe/6hggILMIICBwYJKoZIhvcNAQkG
# MYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMg
# Q29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vy
# dmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwMTIyMjEz
# MTEyWjAjBgkqhkiG9w0BCQQxFgQUqh/1nESdeSZzjbJgfYxhj7aQpfQwDQYJKoZI
# hvcNAQEBBQAEggEAKcIqH1tskbbZzhvqbhNoAeUC6JVT8tSy5ACwxohIowQDJrpz
# UVHbg8hmwQXd/M0qF01oyethECT/U3psjD+JXdpK3dHA4tWHsEtf/MjCCrpXp8Bm
# H9VI+C9Rvc9HIs6la2/tawSzUjFQpCPSwYiSKOaep+nIUZlQBxhQc8cdMVgz7Fs+
# BYgViY7Av1wpGZYGaGJ+nd/oD0is1HlBBItl9nwhE38AgQr9camtT/3Qm9i3SOML
# cVcgVwIE1izGvHexbKm5sqowYf6PGeMLGkx9ewq1ZtuM/F/T7RTepsVB7kkm3b7K
# Z7sVTTYZ/au4H6hLHTV4aqU6mbmuXFvnAM3hBA==
# SIG # End signature block
