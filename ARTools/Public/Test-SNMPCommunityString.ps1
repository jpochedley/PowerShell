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
                    
                        Test-SNMPCommunityString -StartIPAddress $($Using:Range.StartIPAddress) -EndIPAddress $($Using:Range.EndIPAddress) -Community $Using:Community -QueryDescription -Verbose:$VerboseSwitch
                    }
                }
                Else
                {
                    Write-Verbose -Message "Starting background job to scan IP $($Range.StartIPAddress) ..."
            
                    $Jobs += Start-Job -Name "$($Range.StartIPAddress)" -ScriptBlock {
                        Import-Module -Name ARTools -Force
                        Import-Module -Name DnsClient
                    
                        Test-SNMPCommunityString -StartIPAddress $($Using:Range.StartIPAddress) -Community $Using:Community -QueryDescription -Verbose:$VerboseSwitch
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

