#requires -Version 2
function Test-Ping
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $True,Position = 0)]
        [string[]]$ComputerName
    )
    
    Begin{}
    
    Process{
        $Connectivity = @()
        
        $Connectivity += Test-Connection -ComputerName $ComputerName -Count 1 -AsJob |
        Wait-Job |
        Receive-Job

        $Results = $Connectivity.where({
                $_.StatusCode -eq 0
        },'Split')

        ForEach($Item in $Results[1])
        {
            Write-Warning -Message "Unable to ping $($Item.Address)."
        }

        $Results[0].Address
    }
    
    End{}
}


