function Test-TCPPort 
{
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
        [int[]]$Port,
        
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
                    
                        Test-TCPPort -StartIPAddress $($Using:Range.StartIPAddress) -EndIPAddress $($Using:Range.EndIPAddress) -Port $Using:Port -Verbose:$Using:VerbosePreference
                    }
                }
                Else
                {
                    Write-Verbose -Message "Starting background job to scan IP $($Range.StartIPAddress) ..."
            
                    $Jobs += Start-Job -Name "$($Range.StartIPAddress)" -ScriptBlock {
                        Import-Module -Name ARTools -Force
                        Import-Module -Name DnsClient
                    
                        Test-TCPPort -StartIPAddress $($Using:Range.StartIPAddress) -Port $Using:Port -Verbose:$Using:VerbosePreference
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
        
            $i = 1
    
            Foreach($IP in $IPList)
            {
                Foreach($P in $Port)
                {
                    $TCPClient = New-Object -TypeName System.Net.Sockets.TcpClient
                    $Connection = $TCPClient.BeginConnect($IP,$P,$null,$null)  
                    $Connected = $Connection.AsyncWaitHandle.WaitOne($TimeOut,$False)  
                    
                    If(-not $Connected)
                    {  
                        $TCPClient.Close() 
                         
                        Write-Verbose -Message "TCP connection to $IP`:$P could not be established."
                    } 
                    Else
                    {
                        Try
                        { 
                            $null = $TCPClient.EndConnect($Connection)
                            $TCPClient.Close()  
        
                            $Hostname = Resolve-DnsName -Name $IP -ErrorAction SilentlyContinue -Verbose:$False | Select-Object -ExpandProperty NameHost
    
                            $Properties = [ordered]@{
                                IPAddress = $IP
                                HostName  = If($Hostname)
                                {
                                    $Hostname
                                }
                                Else
                                {
                                    '<Unknown>'
                                }
                                Port      = $P
                            }
    
                            $Object = New-Object -TypeName PSObject -Property $Properties
                            $Object.PSObject.Typenames.Insert(0,'ARTools.TCPReturn')
                            $Object
                        }
                        Catch [System.Net.Sockets.SocketException] 
                        {
                            Write-Verbose -Message "TCP connection to $IP`:$P could not be established. $($_.Exception.Message)"
                        }
                        Catch
                        {
                            $_
                        }
                    }      

                
                    Write-Progress -Activity 'Attempting TCP connection, waiting for response' -Status "Testing $IP`:$P" -PercentComplete (($i / ($IPList.length*$Port.length))  * 100)
                
                    $i++
                }
            }
        }
    
        
    }

    End{}
}


