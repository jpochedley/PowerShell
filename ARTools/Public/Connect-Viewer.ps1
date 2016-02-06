#requires -Version 2
function Connect-Viewer
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $False)]
        [switch]$Hidden,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{
        If(-not (Test-Path -Path "$env:SMS_ADMIN_UI_PATH\cmrcviewer.exe"))
        {
            Write-Warning -Message 'Could not find Remote Control Viewer.'
            Break
        }
    }
    
    Process{
        [scriptblock]$InitialScriptBlock = {
            $VerbosePreference = $Using:VerbosePreference
            $WarningPreference = $Using:WarningPreference

            Write-Verbose -Message "Backing up default Remote Control Viewer settings on $env:COMPUTERNAME ..."

            $Backup = Start-Process -FilePath $env:windir\system32\reg.exe -ArgumentList "export `"HKLM\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control`" `"$env:windir\Temp\RemoteControlDefaultSettings.reg`"" -PassThru -Wait
            
            If($Backup.ExitCode -ne 0)
            {
                Throw "Problem encountered backing up Remote Control Viewer settings on $env:COMPUTERNAME."
            }
            Else
            {
                Write-Verbose -Message "Default Remote Control Viewer settings on $env:COMPUTERNAME backed up successfully."
            
                'Permission Required', 'RemCtrl Taskbar Icon', 'RemCtrl Connection Bar', 'Audible Signal' |

                ForEach-Object -Process {
                    Write-Verbose -Message "Changing $_ setting on $env:COMPUTERNAME ..."
                    
                    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Name $_ -Value 0
                    
                    Write-Verbose -Message "$_ setting set to 0 on $env:COMPUTERNAME."
                }

                Write-Verbose -Message "Changing Access Level setting on $env:COMPUTERNAME ..."
                
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Name 'Access Level' -Value 1
                
                Write-Verbose -Message "Access Level setting set to 1 on $env:COMPUTERNAME."
            }
        }

        If($PSBoundParameters.ContainsKey('ComputerName'))
        {
            $InvokeArgs = @{
                ComputerName = $ComputerName
            }
    
            If($null -ne $Credential)
            {
                $InvokeArgs.Credential = $Credential
            }
        
            $InvokeArgs.ComputerName = $ComputerName = Test-PSRemoting @InvokeArgs -WarningAction $WarningPreference

            If($Hidden)
            {
                If($null -ne $ComputerName)
                {
                    $InvokeArgs.ScriptBlock = $InitialScriptBlock
        
                    Invoke-Command @InvokeArgs -ErrorAction Stop
                }
            }

            Foreach($Computer in $ComputerName)
            {
                Start-Process -FilePath "$env:SMS_ADMIN_UI_PATH\cmrcviewer.exe" -ArgumentList "$Computer" -WindowStyle Maximized
            }
            
            If($Hidden)
            {
                [scriptblock]$CleanupScriptBlock = {
                    $VerbosePreference = $Using:VerbosePreference
                    $WarningPreference = $Using:WarningPreference
                        
                    Write-Verbose -Message "Restoring default Remote Control Viewer settings on $env:COMPUTERNAME ..."
                        
                    $Restore = Start-Process -FilePath $env:windir\system32\reg.exe -ArgumentList "import `"$env:windir\Temp\RemoteControlDefaultSettings.reg`"" -PassThru -Wait
                        
                    If($Restore.ExitCode -ne 0)
                    {
                        Write-Error "Problem encountered restoring Remote Control Viewer settings on $env:COMPUTERNAME."
                    }
                    Else
                    {
                        Write-Verbose -Message "Default Remote Control Viewer settings on $env:COMPUTERNAME restored successfully."
                            
                        Remove-Item -Path "$env:windir\Temp\RemoteControlDefaultSettings.reg" -Force
                    }
                }

                If($null -ne $ComputerName)
                {
                    If($psISE)
                    {
                        Add-Type -AssemblyName System.Windows.Forms
                        $null = [System.Windows.Forms.MessageBox]::Show('Click OK to reset Remote Control Viewer settings ...')
                    }
                    Else
                    {
                        Write-Output -InputObject 'Press any key to reset Remote Control Viewer settings ...'

                        $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                    }

                    $InvokeArgs.ScriptBlock = $CleanupScriptBlock
        
                    Invoke-Command @InvokeArgs
                }
            }
        }
        Else
        {
            Start-Process -FilePath "$env:SMS_ADMIN_UI_PATH\cmrcviewer.exe"
        }
    }

    End{}
}

# SIG # Begin signature block
# MIISDAYJKoZIhvcNAQcCoIIR/TCCEfkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU74hCFxiP7g9WxVJQWpGC0e9i
# glCggg3cMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggU/MIIEJ6ADAgECAhN4AAAAc4W2eXB+zY31AAAAAABzMA0GCSqGSIb3DQEBBQUA
# MFQxEzARBgoJkiaJk/IsZAEZFgNvcmcxHTAbBgoJkiaJk/IsZAEZFg1ibGFja2hp
# bGxzZmN1MR4wHAYDVQQDExVibGFja2hpbGxzZmN1LUJIQ0EtQ0EwHhcNMTUwODEy
# MjMxNDM4WhcNMTYwODExMjMxNDM4WjB0MRMwEQYKCZImiZPyLGQBGRYDb3JnMR0w
# GwYKCZImiZPyLGQBGRYNYmxhY2toaWxsc2ZjdTEWMBQGA1UECxMNVXNlciBBY2Nv
# dW50czELMAkGA1UECxMCSVQxGTAXBgNVBAMTEEFkcmlhbiBSb2RyaWd1ZXowgZ8w
# DQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAJ5ZDMvhBWGsWxF+1tGMRbvdsQx9th2S
# oTrEa4TGjPJo1S+NtPGditPNBlsJO9G/NhucjSwAT2Vc7/7aGQjNPaF3SyYwhSxV
# NfJjFqtpZjBgsxXDA4GlLYESC5LZ32ZR6ettkUSeHt/qXLAm3hBJGca6FjTvO5lk
# ayiqeZr9iRWnAgMBAAGjggJsMIICaDAlBgkrBgEEAYI3FAIEGB4WAEMAbwBkAGUA
# UwBpAGcAbgBpAG4AZzATBgNVHSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4Aw
# HQYDVR0OBBYEFAhHzZ02lmNv/fQPGxn1kyQ8cmzlMB8GA1UdIwQYMBaAFF/X6Uf5
# osbZbSp9/Vsx1FcTcWzlMIHWBgNVHR8Egc4wgcswgciggcWggcKGgb9sZGFwOi8v
# L0NOPWJsYWNraGlsbHNmY3UtQkhDQS1DQSxDTj1CSENBLENOPUNEUCxDTj1QdWJs
# aWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9u
# LERDPWJsYWNraGlsbHNmY3UsREM9b3JnP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxp
# c3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCBzQYIKwYB
# BQUHAQEEgcAwgb0wgboGCCsGAQUFBzAChoGtbGRhcDovLy9DTj1ibGFja2hpbGxz
# ZmN1LUJIQ0EtQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENO
# PVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9YmxhY2toaWxsc2ZjdSxEQz1v
# cmc/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25B
# dXRob3JpdHkwNAYDVR0RBC0wK6ApBgorBgEEAYI3FAIDoBsMGWFkcmlhbnJAYmxh
# Y2toaWxsc2ZjdS5vcmcwDQYJKoZIhvcNAQEFBQADggEBAJufqHfcfbsgqU+3d0vN
# NHCeAF59ygRRQX55uPiATRt3KAaEah79BmwzmzvA1n4WBh4fsGwNSpzEl2cBChCA
# NARhRh0018QpExSid+l3EEWg9jNFqRSkgDFz9UmTsIjPiXWkXPJzTtoyG/Ga0hcp
# Ol/Lx7niAIfmxQcBmOsLXKsSlnrfmeiaBhB+D+K2fELmMuEsEiEIZeeV3A5/U4Mb
# VFBa4OOhK2jiZzQgvjDDXwMs8MRYHFG5Y9rFE8wDHq21aLMYAItRKXqNOvGtq5bX
# ZUJM+ZakmWBJhy/q7j451vxXcs1QmCJpOWgD5OpXK3TvycAaIq7iiOlcvjMyOL3k
# dqkxggOaMIIDlgIBATBrMFQxEzARBgoJkiaJk/IsZAEZFgNvcmcxHTAbBgoJkiaJ
# k/IsZAEZFg1ibGFja2hpbGxzZmN1MR4wHAYDVQQDExVibGFja2hpbGxzZmN1LUJI
# Q0EtQ0ECE3gAAABzhbZ5cH7NjfUAAAAAAHMwCQYFKw4DAhoFAKB4MBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDtWRIgp
# np8kj0vdbpqPkz10DXu2MA0GCSqGSIb3DQEBAQUABIGAJqXlTS937CFlxU8/D1B5
# aS8VhVZ+TXLecA2RhxE/nP7W3VwQSR4pyTBspYtGQpSrGm8niiPXIz1b9g+IayS3
# 2Zxzohn+TrrbIp3ilePKWyhN025IoTXd4gp5An93JQXcP1GGNqii4Yj13KxNRdQr
# BwTLhT7DXAWICiaoaNmwt3ihggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEw
# cjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24x
# MDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBH
# MgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsG
# CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwMTA4MTIyMjM5WjAjBgkqhkiG
# 9w0BCQQxFgQU/89dAagvDNRa4fFQy59982la4QQwDQYJKoZIhvcNAQEBBQAEggEA
# RBbJLVT6SownwTDNlwc4uY3u+5OtXWlsUmyP9fEnW04wRqBfz1dLajsgKEUAU0Qr
# AAfrN4eZk5jbR8IZNnG61RcKgQeTUM4A/VM4hSMREDhmO2uLlnHBg1IQS+6My2vU
# MTi+k/OFQe0Nw2mVK5/e4T9u0CR4ax6gciuoib9/IygGoyGEja5b868RUB3V6Km6
# Wy9fZM7gbcr6RVKdyzueWs8Y9ppi5x9TWSc4RIup1Gd7PTzaJoueYQlgRvv0Z4Qv
# 4+73yLsC2dq09rXMmxRYUVQTXSmiii9kjNXqCGP/3BoO4zNXx4oeh/f6eTt+9E5F
# 3AwTwzf02aKtDpgYVC/xFw==
# SIG # End signature block
