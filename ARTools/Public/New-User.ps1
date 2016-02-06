#requires -Version 3

function New-User
{
    [cmdletbinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]

    Param(
        [Parameter(Mandatory = $True,ParameterSetName = 'SpecificUser')]
        [string]$ReferenceUsername,

        [Parameter(Mandatory = $True,ParameterSetName = 'Browse')]
        [switch]$Browse,

		[Parameter(Mandatory = $True, ParameterSetName = 'Browse')]
		[string[]]$Offices,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    $ProposedUsername = $_
                    $Exists = Get-ADUser -Filter "SamAccountName -eq '$ProposedUsername'" -ErrorAction Stop
                    If($Exists)
                    {
                        Throw "Object found with identity: '$ProposedUsername'."
                    }
                    Else
                    {
                        If($ProposedUsername -cmatch "^[a-z0-9\.]{1,19}$")
                        {
                            $True
                        }
                        Else
                        {
                            Throw 'Please ensure username contains only lowercase letters, numbers, and/or a period.'
                        }
                    }
                }
        )]
        [ValidateLength(3,20)]
        [Alias('Username')]
        [string]$SamAccountName,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    If($_ -cmatch "^[A-Z][A-Za-z0-9_-]{1,19}$")
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please capitalize first letter of first name.'
                    }
                }
        )]
        [string]$FirstName,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    If($_ -cmatch "^[A-Z][A-Za-z0-9_-]{1,19}$")
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please capitalize first letter of last name.'
                    }
                }
        )]
        [string]$LastName,
        
        [Parameter(Mandatory = $False)]
        [ValidateScript({
                    If($_ -cmatch "^[A-Z]$")
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please capitalize middle initial.'
                    }
                }
        )]
        [string]$MiddleInitial = $null,
        
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [securestring]$Password = (New-RandomPassword).SecureStringObject,
        
        [Parameter(Mandatory = $True)]
        [string]$Server
    )

    Begin{
        Try
        {
            Write-Verbose -Message 'Checking for Exchange session ...'
            $null = Get-PSSession -Name Exchange -ErrorAction Stop
            Write-Verbose -Message 'Exchange session found.'
        }
        Catch
        {
            Write-Warning -Message 'Unable to find Exchange session. Please run Connect-Exchange and try again.'
            Break
        }
        
        Try
        {
            Write-Verbose -Message 'Checking for Lync session ...'
            $null = Get-PSSession -Name Lync -ErrorAction Stop
            Write-Verbose -Message 'Lync session found.'
        }
        Catch
        {
            Write-Warning -Message 'Unable to find Lync session. Please run Connect-Lync and try again.'
            Break
        }

		$MailboxDatabase = (Get-MailboxDatabase | Select-Object -Property Name | Out-GridView -Title "Select Mailbox Database" -OutputMode Single).Name

		If(-not $MailboxDatabase){
			Write-Warning -Message 'No mailbox database selected. Please try again.'
            Break
		}
    }

    Process{
        $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force

        If($PSCmdlet.ParameterSetName -eq 'SpecificUser')
        {
            Try
            {
                $ReferenceUser = Get-ADUser -Identity $ReferenceUsername -Properties * -ErrorAction Stop
            }
            Catch
            {
                Write-Warning -Message "Reference user lookup failed. $($_.Exception.Message)"
            }
        }
        Else
        {
            $Office = $Offices | Out-GridView -Title 'Please select a location:' -OutputMode Single
            If($null -ne $Office)
            {
                $Position = Get-ADUser -Filter "Office -like '*$Office*'" -Properties Title -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty Title |
                Sort-Object -Unique |
                Out-GridView -Title 'Please select position:' -OutputMode Single
                If($null -ne $Position)
                {
                    $UserSelection = Get-ADUser -Filter "Office -like '*$Office*' -and Title -eq '$Position'" -Properties MemberOf, Title -ErrorAction SilentlyContinue |
                    Select-Object -Property Name, SamAccountName, Title, @{
                        name = 'Memberships'
                        e    = {
                            ($_.MemberOf.ForEach({
                                        $_.split(',', 2)[0].replace('CN=', '')
                                })|
                            Sort-Object) -join "`r`n"
                        }
                    }, @{
                        name = 'MembershipCount'
                        e    = {
                            $_.MemberOf.Count
                        }
                    } |
                    Sort-Object -Property MembershipCount |
                    Out-GridView -Title 'Please select user to copy:' -OutputMode Single
                    If($null -ne $UserSelection)
                    {
                        Try
                        {
                            $ReferenceUser = Get-ADUser -Identity $UserSelection.samaccountname -Properties * -ErrorAction Stop
                        }
                        Catch
                        {
                            Write-Warning -Message "Reference user selection failed. $($_.Exception.Message)"
                        }
                    }
                    Else
                    {
                        Write-Warning -Message 'No reference user selected. Please select a user and try again.'
                    }
                }
                Else
                {
                    Write-Warning -Message 'No position selected. Please select a position and try again.'
                }
            }
            Else
            {
                Write-Warning -Message 'No location provided. Please select a location and try again.'
            }
        }
        
        If($null -ne $ReferenceUser)
        {
            $NewUserAttributes = @{
                Department            = $ReferenceUser.Department
                Manager               = $ReferenceUser.Manager
                Office                = $ReferenceUser.Office
                Description           = $ReferenceUser.Description
                Title                 = $ReferenceUser.Title
                Path                  = $ReferenceUser.DistinguishedName -split ',', 2 | Select-Object -Last 1
                ScriptPath            = $ReferenceUser.ScriptPath
                HomeDrive             = $ReferenceUser.HomeDrive
                HomeDirectory         = $ReferenceUser.HomeDirectory |
                Split-Path -Parent -ErrorAction SilentlyContinue |
                Join-Path -ChildPath "\$Username" -ErrorAction SilentlyContinue
                Company               = $ReferenceUser.Company
                SamAccountName        = $Username
                UserPrincipalName     = "$Username@$env:USERDNSDOMAIN"
                GivenName             = $FirstName
                Surname               = $LastName
                Initials              = $MiddleInitial
                DisplayName           = "$FirstName $MiddleInitial $LastName" -replace '  ', ' '
                Name                  = "$FirstName $MiddleInitial $LastName" -replace '  ', ' '
                CannotChangePassword  = $False
                AccountPassword       = $SecurePassword
                ChangePasswordAtLogon = $True
                PasswordNeverExpires  = $False
                Enabled               = $True
                Server                = $Server
                ErrorAction           = 'Stop'
            }

            If($PSCmdlet.ShouldProcess($NewUserAttributes.Name))
            {
                Try
                {
                    Write-Verbose -Message 'Creating new user ...'
                    New-ADUser @NewUserAttributes
                    Write-Verbose -Message 'New user created successfully.'

                    $Groups = Get-ADPrincipalGroupMembership -Identity $ReferenceUser.samaccountname |
                    Where-Object -Property Name -NE -Value 'Domain Users' |
                    Select-Object -ExpandProperty SamAccountName

                    Foreach($Group in $Groups)
                    {
                        Try
                        {
                            Write-Verbose -Message "Adding user to $Group group ..."
                            Add-ADGroupMember -Identity $Group -Members $Username -Server $Server -ErrorAction Stop
                            Write-Verbose -Message "User added to $Group group successfully."
                        }
                        Catch
                        {
                            Write-Warning -Message "Unable to add user to $Group group. $($_.Exception.Message)"
                        }
                    }

                    Try
                    {
                        Write-Verbose -Message 'Creating Home Directory ...'

                        $null = New-Item -Path $NewUserAttributes.HomeDirectory -ItemType Directory -ErrorAction Stop

                        $Exists = $False

                        do
                        {
                            $Exists = Test-Path -Path $NewUserAttributes.HomeDirectory
                        }
                        until($Exists)

                        $AccessRuleObject = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList "$env:USERDOMAIN\$Username", 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'

                        $ACL = Get-Acl -Path $NewUserAttributes.HomeDirectory

                        Try
                        {
                            $ACL.AddAccessRule($AccessRuleObject)
                            Set-Acl -Path $NewUserAttributes.HomeDirectory -AclObject $ACL -ErrorAction Stop
                            Write-Verbose -Message 'Home Directory created successfully.'
                        }
                        Catch
                        {
                            Write-Warning -Message "Could not set permissions on home directory. $($_.Exception.Message)"
                        }
                    }
                    Catch
                    {
                        Write-Warning -Message "Home Directory creation failed. $($_.Exception.Message)"
                    }

                    Try
                    {
                        Write-Verbose -Message 'Creating user mailbox ...'
                        $null = Enable-Mailbox -Identity $NewUserAttributes.UserPrincipalName -Database $MailboxDatabase -DomainController $Server -ErrorAction Stop
                        Write-Verbose -Message 'User mailbox created successfully.'
                    }
                    Catch
                    {
                        Write-Warning -Message "User mailbox creation failed. $($_.Exception.Message)"
                    }
                    
                    Try
                    {
                        Write-Verbose -Message 'Providing Lync access ...'
                        $null = Enable-CsUser -Identity $NewUserAttributes.UserPrincipalName -RegistrarPool (Get-PSSession -Name Lync).ComputerName -SipAddressType UserPrincipalName -ErrorAction Stop
                        Write-Verbose -Message 'Lync access provided successfully.'
                    }
                    Catch
                    {
                        Write-Warning -Message "Could not provide access to Lync. $($_.Exception.Message)"
                    }
                }
                Catch
                {
                    Write-Warning -Message "New user creation failed. $($_.Exception.Message)"
                }
            }
        }
    }

    End{}
}

# SIG # Begin signature block
# MIIVqAYJKoZIhvcNAQcCoIIVmTCCFZUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP2EBtDWG0Z9oBexEJuBhI/jn
# YcmgghF4MIIDmDCCAoCgAwIBAgIQFTuOD6CJ+6NFVKZ6+fJQbzANBgkqhkiG9w0B
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
# AQkEMRYEFDcrZkSTRPq6pmGC0u63AReXDA6hMA0GCSqGSIb3DQEBAQUABIGAjQq/
# EDOR89THF0Fr33WcIEkxYE+uRcocHfjbkOk/ruodbuCWMDQoi5qXZCVY0Jwdj4pY
# IhX9PGSCZ2nyTkv8io2YJipW/+YalF+DCbrszU3uV+Lo98ElS5wobpOktZTxMx3p
# 8SnWqIPSDTGq1SeWsWWvh2/yHp/Gr2ul4KichS6hggILMIICBwYJKoZIhvcNAQkG
# MYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMg
# Q29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vy
# dmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwMjA2MTg1
# ODU3WjAjBgkqhkiG9w0BCQQxFgQUFPz67prBYIAQDWgpN8C7zRPruw4wDQYJKoZI
# hvcNAQEBBQAEggEAUIJvqHlO/aek26rb8zQ/RWl+EYpDpb15s4KGR5sdgpH62fVQ
# dSJN0eYAcYok5/MtRyIi10L98jPqVAVKd1wCPKzdeNiUx+7EFHC+2mrrJrWZyZLm
# 0cuXcZMq37bT4YpznJOK2bQbyFZGFzaY6+AoZ+vRL0fM1BOmDyJ1JW1eY7s0Li7P
# HosyRy5LIac24OcC1wKGRecJlAeujMTJkvoaibp2+HovZwUBw+2A6cChUHL/TpsE
# +3fj9B/5gAkB4h9jN0NigWJEiezthWM4XuP3vh1sK1EQJ0qBiD9ilSXGuxCD62YV
# i++C2DAefqAPyt6UjY39Jm/Dz52GLHhnz+Ptdg==
# SIG # End signature block
