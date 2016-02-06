#requires -Version 2
function Connect-RDP
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = $null,
        
        [Parameter(Mandatory = $False)]
        [switch]$Force
    )
    
    DynamicParam{
        If($ComputerName)
        {
            New-DynamicParameter -Name Credential -TypeConstraint ([pscredential])
        }
    }
    
    Begin{
        If($PSBoundParameters.ContainsKey('Credential'))
        {
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
    }

    Process{
        If($PSBoundParameters.ContainsKey('ComputerName'))
        {
            Foreach($Computer in $ComputerName)
            {
                If((Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -or $Force)
                {
                    If($PSBoundParameters.ContainsKey('Credential'))
                    {
                        Start-Process -FilePath $env:windir\System32\cmdkey.exe -ArgumentList "/generic:$Computer /user:$User /pass:$Password"
                    }

                    Start-Process -FilePath $env:windir\System32\mstsc.exe -ArgumentList "/v:$Computer /f" -WindowStyle Normal
                }
                Else
                {
                    Write-Warning -Message "Cannot contact $Computer."
                }
            }
        }
        Else
        {
            Start-Process -FilePath $env:windir\System32\mstsc.exe
        }
    }

    End{}
}

# SIG # Begin signature block
# MIISDAYJKoZIhvcNAQcCoIIR/TCCEfkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKgHrunh2waEg9iNVvHE9Issq
# zkyggg3cMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFClOh3sh
# 99JPti5Vk/34ES/ws1YLMA0GCSqGSIb3DQEBAQUABIGARRMZlmitCqP8nEt0dJ8x
# BZEvcmPHLtSVYy8lWH1HWrlrsrvxkBmJHa5zqvJYFyaBUgLKT2kYbma3QPXlRYgS
# /hH9ADQ9/tHbdxzB1jGX9Ee2JyPF2e/1f9euEJQnqfsMxWGAMf6+bnY7zd4hFnKo
# 7GxUkm0U8mFbnvkvzvSUfLGhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEw
# cjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24x
# MDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBH
# MgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsG
# CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTUxMjI4MDI0NDQ0WjAjBgkqhkiG
# 9w0BCQQxFgQUEJNz9vbLCf2rj3qClIpbMaRzcBMwDQYJKoZIhvcNAQEBBQAEggEA
# VFpyemPzpRy1nEF7S9U76TAUj1COmUyl0Huyzu4zXxJvqnzgU2noVeGkk+dU5PoM
# bXD/g0CA79XkTB1Yr4JGkbzdbH78+z4ue/7FEcPOFwMvyJGCmAh4wy6Tq4VlQOGG
# /hlmqMIjDEsVN0QVIMiMYjGoPwQIlR82+/Z2Qc30J59HvoXycivaKWhltNlNrr3K
# 1HGcWsm8QPMIZOfMIY04cNIqV2R9VZz3R14Y6PlVGCVqK9gAh1N6IhsWmWI0J11r
# kCGjCUZtRPQy1OUkXKLt1XZxEkVfjukj7I3tNVaoU85ftnEXMHKhyUXoM9jmLfW/
# RSwj2dudT6sQsRomEIiNig==
# SIG # End signature block
