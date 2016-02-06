function Test-SNMPCommunityString 
{
    <#
            .Synopsis
            Tests SNMP community strings.
            .DESCRIPTION
            The Test-SNMPCommunityString function sends SNMP requests to user defined IP ranges using a user defined list of community strings and outputs their response. 
    
            The default community string list includes the default communitry string 'public'.

            .EXAMPLE
            Test-SNMPCommunityString -StartIPAddress 10.11.16.38

            This command queries the IP address 10.11.16.38 to see if it will respond to the default community string of 'public'.

            .EXAMPLE
            Test-SNMPCommunityString -StartIPAddress 10.11.16.38 -QueryDescription

            This command queries the IP address 10.11.16.38 to see if it will respond to the default community string of 'public'. If the device does respond the function will return whatever device description the device manufacturer has provided.

            .EXAMPLE
            Test-SNMPCommunityString -StartIPAddress 10.11.16.38 -EndIPAddress 10.11.17.255

            This command queries IP addresses from 10.11.16.38 to 10.11.17.255 to see if they will respond to the default community string of 'public'.

            .EXAMPLE
            Test-SNMPCommunityString -StartIPAddress 10.11.16.38 -EndIPAddress 10.11.17.255 -Community 'public', 'private', 'snmpd', 'mngt', 'cisco', 'admin'

            This command queries IP addresses from 10.11.16.38 to 10.11.17.255 to see if they will respond to any of the above community strings.

            .EXAMPLE
            Test-SNMPCommunityString -SelectIPRangeFromList

            This command queries IP addresses from selected IP ranges to see if they will respond to the default community string of 'public'. The IP Range list can be found and updated from the IT Department's Sharepoint page.

            .EXAMPLE
            Test-SNMPCommunityString -Audit

            This command queries IP addresses from all IP ranges found in the IP range list to see if they will respond to the default community string of 'public'. The IP Range list can be found and updated from the IT Department's Sharepoint page.
    
            .EXAMPLE
            Test-SNMPCommunityString -Audit | Export-csv -Path c:\SNMPQuery.csv

            This command queries IP addresses from all IP ranges found in the IP range list to see if they will respond to the default community string of 'public'. The results are then exported to a CSV file named SNMPQuery.csv at the root of the C drive.
    
            The IP Range list can be found and updated from the IT Department's Sharepoint page.
    
            .EXAMPLE
            Test-SNMPCommunityString -Audit -AsJob

            This command queries IP addresses from all IP ranges found in the IP range list to see if they will respond to the default community string of 'public'. When you use the AsJob parameter, the command immediately returns an object that represents the background job. You can continue to work in the session while the job completes. The job is created on the local computer. To get the job results, use the Receive-Job cmdlet 
    
            The IP Range list can be found and updated from the IT Department's Sharepoint page.
    
            .NOTES
            The Test-SNMPCommunityString function supports SNMPv2 as currently implemented.

            .PARAMETER AsJob

            Runs the command as a background job.
    
            When you use the AsJob parameter, the command immediately returns an object that represents the background job. You can continue to work in the session while the job completes. The job is created on the local computer. To get the job results, use the Receive-Job cmdlet.
    #>
    
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $True,Position = 0,ParameterSetName = 'Undefined')]
        [string]$StartIPAddress,
        
        [Parameter(Mandatory = $False,Position = 1,ParameterSetName = 'Undefined')]
        [string]$EndIPAddress = $null,
        
        [Parameter(Mandatory = $True,ParameterSetName = 'Defined')]
        [switch]$SelectIPRangeFromList,
        
        [Parameter(Mandatory = $True,ParameterSetName = 'Audit')]
        [switch]$Audit,

		[Parameter(Mandatory = $True,ParameterSetName = 'Audit')]
		[Parameter(Mandatory = $True,ParameterSetName = 'Defined')]
		[string]$SharePointCSV,
        
        [Parameter(Mandatory = $False)]
        [string[]]$Community = 'public', #'private', 'snmpd', 'mngt', 'cisco', 'admin'
        
        [Parameter(Mandatory = $False)]
        [switch]$QueryDescription,
        
        [Parameter(Mandatory = $False)]
        [int]$TimeOut = 1000,
        
        [Parameter(Mandatory = $False,ParameterSetName = 'Audit')]
        [Parameter(Mandatory = $False,ParameterSetName = 'Defined')]
        [switch]$AsJob
    )

    Begin{}

    Process{
        If($PSCmdlet.ParameterSetName -ne 'Undefined')
        {
            Try
            {
                $ImportedRanges = Invoke-RestMethod -Uri $SharePointCSV -UseDefaultCredentials -Verbose:$False | ConvertFrom-Csv
            }
            Catch
            {
                Write-Warning -Message 'Could not find IP Range CSV file.'
                Break
            }
            
            If($SelectIPRangeFromList)
            {
                $Ranges = $ImportedRanges | Out-GridView -Title 'Please select IP ranges to scan:' -PassThru
            }
            ElseIf($Audit)
            {
                $Ranges = $ImportedRanges
            }
            
            $Jobs = @()
            
            Foreach($Range in $Ranges)
            {
                If($Range.EndIPAddress)
                {
                    Write-Verbose -Message "Starting background job to scan IP range $($Range.StartIPAddress) - $($Range.EndIPAddress) ..."
            
                    $Jobs += Start-Job -Name "$($Range.StartIPAddress)-$($Range.EndIPAddress)" -ScriptBlock {
                        Import-Module -Name ARTools -Force
                        Import-Module -Name DnsClient
                    
                        Test-SNMPCommunityString -StartIPAddress $($Using:Range.StartIPAddress) -EndIPAddress $($Using:Range.EndIPAddress) -Community $Using:Community -QueryDescription -Verbose:$Using:VerbosePreference
                    }
                }
                Else
                {
                    Write-Verbose -Message "Starting background job to scan IP $($Range.StartIPAddress) ..."
            
                    $Jobs += Start-Job -Name "$($Range.StartIPAddress)" -ScriptBlock {
                        Import-Module -Name ARTools -Force
                        Import-Module -Name DnsClient
                    
                        Test-SNMPCommunityString -StartIPAddress $($Using:Range.StartIPAddress) -Community $Using:Community -QueryDescription -Verbose:$Using:VerbosePreference
                    }
                }
            }
            
            
            If(-not $AsJob)
            {
                Write-Verbose -Message 'Waiting for all background jobs ...'
            
                $Jobs |
                Wait-Job |
                Receive-Job
            
                $Jobs | Remove-Job -Force
            }
            Else
            {
                $Jobs
            }
        }
        Else
        {
            If(-not $PSBoundParameters.ContainsKey('EndIPAddress'))
            {
                $EndIPAddress = $StartIPAddress
            }
        
            $IPList = Get-IPAddressRange -StartIPAddress $StartIPAddress.Trim() -EndIPAddress $EndIPAddress.Trim()
        
            Add-Type -Path $PSScriptRoot\..\lib\Lextm.SharpSnmpLib\8.5.0.0\lib\net40\SharpSnmpLib.Full.dll
    
            $SNMPVersion = [Lextm.SharpSnmpLib.VersionCode]::V2
        
            $OID = @()
            $OID += New-Object -TypeName Lextm.SharpSnmpLib.ObjectIdentifier -ArgumentList ('1.3.6.1.2.1.1.5.0')
        
            If($QueryDescription)
            {
                $OID += New-Object -TypeName Lextm.SharpSnmpLib.ObjectIdentifier -ArgumentList ('1.3.6.1.2.1.1.1.0')
            }
        
            $OIDList = New-Object -TypeName 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
        
            $OID | ForEach-Object -Process {
                $OIDList.Add($_)
            }
        
            $i = 1
    
            Foreach($IP in $IPList)
            {
                $IPAddress = [System.Net.IPAddress]::Parse($IP)
                $Endpoint = New-Object -TypeName System.Net.IpEndPoint -ArgumentList ($IPAddress, 161)
        
                Foreach($String in $Community)
                {
                    try 
                    {
                        $Response = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get($SNMPVersion, $Endpoint, $String, $OIDList, $TimeOut)
                    
                        $Hostname = Resolve-DnsName -Name $IP -ErrorAction SilentlyContinue -Verbose:$False | Select-Object -ExpandProperty NameHost
            
                        $Properties = [ordered]@{
                            IPAddress       = $IP
                            HostName        = If($Hostname)
                            {
                                $Hostname
                            }
                            Else
                            {
                                $Response |
                                Where-Object -Property ID -EQ -Value '.1.3.6.1.2.1.1.5.0' |
                                Select-Object -ExpandProperty Data
                            }
                            CommunityString = $String
                        }
                    
                        If($QueryDescription)
                        {
                            $Properties.Description = $Response |
                            Where-Object -Property ID -EQ -Value '.1.3.6.1.2.1.1.1.0' |
                            Select-Object -ExpandProperty Data
                        }
                
                        $Object = New-Object -TypeName PSObject -Property $Properties
                        $Object.PSObject.Typenames.Insert(0,'ARTools.SNMPReturn')
                        $Object
                    }
                    catch [Lextm.SharpSnmpLib.Messaging.TimeoutException]
                    {
                        Write-Verbose -Message "$IP`: No response to SNMP request using '$String' as a community string."
                    }
                    catch [System.Net.Sockets.SocketException]
                    {
                        Write-Verbose -Message "$IP`: Connection to port 161 failed. Device may not support SNMP or SNMP is disabled."
                    }
                    catch 
                    {
                        Write-Warning -Message "$($_.Exception.Message)"
                    }
                
                    Write-Progress -Activity "Sending SNMP Request to $IP" -Status "Testing SNMP Community String: $String" -PercentComplete (($i / ($IPList.length*$Community.length))  * 100)
                
                    $i++
                }
            }
        }
    
        
    }

    End{}
}
# SIG # Begin signature block
# MIIVqAYJKoZIhvcNAQcCoIIVmTCCFZUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFb3IfRA6uad02xCgcbWlVINO
# 7tCgghF4MIIDmDCCAoCgAwIBAgIQFTuOD6CJ+6NFVKZ6+fJQbzANBgkqhkiG9w0B
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
# AQkEMRYEFGhYie1giYQCkUWd2LptwcfjtbVlMA0GCSqGSIb3DQEBAQUABIGAd4wT
# fuUQFa3VrksSDcT8ZmMculkpz9CGa6Lmix5ADCdSmgS/W7d62DBPtOffnBCEx+tg
# 8uaOIvMLQOqKikWSGvJ1997X+6Yc/uuWzIdJQxNyONGMSQvw6JpRnZlZUDwyTLG6
# 0bZMi9eQ65c+zSbXfzrHXEAzKZVWumzu9R9c08qhggILMIICBwYJKoZIhvcNAQkG
# MYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMg
# Q29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vy
# dmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwMjA2MTgy
# NDU4WjAjBgkqhkiG9w0BCQQxFgQU5m1faufkuVm24RGtnOkJEv4jUIwwDQYJKoZI
# hvcNAQEBBQAEggEAek+bMGYUoQiLgFgNPAzU1uQmLsuSZOd0799fy5+wFn4t1DOa
# unzSLjKn4oG8Ad1Au9bqq0C5lpvsFk8iifkjqCQj61yMNKZMFTHMjxlduv7Kj3iE
# YTzb6auhUpMnQzbSy2N/cWhzh8/3UokI0dHUNjXrtg0fE8f59wGYVxRIGSZpxbfZ
# IaeJpKFRt48YDdshQBQwPw0qfGBg3dKNfmlY13BEGlGh8FUzRv8kFvFMykP73b/o
# Q1pibkH9nO5Kn2GaYVKIJo1uXrNkbu5HyEFTTyF3QjUbSpv9E1s7UbTSKcOs+cFL
# ZhysMphOJ2zQL44so2NpCncnWrF09QDpsUstdg==
# SIG # End signature block
