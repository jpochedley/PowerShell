#requires -Version 2
function Find-ErrorEventLog
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('Name')]
        [string[]]$ComputerName = 'Localhost',

        [Parameter(Mandatory = $False,ValueFromPipelineByPropertyName = $True)]
        [datetime]$StartTime = (Get-Date).AddHours(-2),

        [Parameter(Mandatory = $False,ValueFromPipelineByPropertyName = $True)]
        [datetime]$EndTime = (Get-Date),
        
        [Parameter(Mandatory = $False)]
        [string[]]$LogName = @('System', 'Application'),
        
        [Parameter(Mandatory = $False)]
        [switch]$AllLogs,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )

    Begin{}

    Process{
        $Scriptblock = {
            $VerbosePreference = $Using:VerbosePreference
            $WarningPreference = $Using:WarningPreference
            $StartTime = $Using:StartTime
            $EndTime = $Using:EndTime
            
            function Split-Array
            {
                [Cmdletbinding()]
    
                Param(
                    [Parameter(Mandatory = $True)]
                    [object]$InputObject,
        
                    [Parameter(Mandatory = $False)]
                    [int]$Limit = 32
                )
    
                Begin{}
    
                Process{
                    $NumberOfSegments = [Math]::Ceiling($InputObject.count / $Limit) 
    
                    [System.Collections.ArrayList]$ArrayList = @()
    
                    for ($i = 1; $i -le $NumberOfSegments; $i++) 
                    { 
                        $Start = (($i-1)*$Limit)
            
                        $End = (($i)*$Limit) - 1
            
                        If($End -ge $InputObject.count) 
                        {
                            $End = $InputObject.count
                        } 
        
                        $null = $ArrayList.Add(@($InputObject[$Start..$End]) )
                    } 
    
                    $ArrayList
                }
    
                End{}
            }

            
            If($Using:AllLogs)
            {
                $Logs = Get-WinEvent -ListLog * | Select-Object -ExpandProperty LogName
            }
            Else
            {
                $Logs = $Using:LogName
            }
            
            If($Logs.Count -gt 256)
            {
                $LogArray = Split-Array -InputObject $Logs -Limit 256
            }
            Else
            {
                $LogArray = @(Split-Array -InputObject $Logs -Limit 256)
            }
            
            Foreach($Items in $LogArray)
            {
                $FilterHashtable = @{
                    LogName   = [string[]]$Items
                    Level     = 1, 2
                    StartTime = $StartTime
                }

                If($EndTime)
                {
                    $FilterHashtable.EndTime = $EndTime
                }

                Try
                {
                    Get-WinEvent -FilterHashtable $FilterHashtable -ErrorAction Stop -Verbose:$False | Select-Object -Property TimeCreated, LogName, ProviderName, Level, Message, @{
                        n = 'Data'
                        e = {
                            $_.Properties.Value
                        }
                    }
                }
                Catch
                {
                    If($_.FullyQualifiedErrorID -match 'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand')
                    {
                        Write-Verbose -Message "No events were found on $Env:COMPUTERNAME that match the specified selection criteria."
                    }
                    Else
                    {
                        $_
                    }
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
        
        $InvokeArgs.ScriptBlock = $Scriptblock
        
        Invoke-Command @InvokeArgs | Select-Object PSComputerName, TimeCreated, LogName, ProviderName, Level, Message, Data -ExcludeProperty RunspaceID
    }
    
    End{}
}


