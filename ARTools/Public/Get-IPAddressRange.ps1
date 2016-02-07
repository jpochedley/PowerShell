function Get-IPAddressRange
{
    [CmdletBinding()]
    
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$StartIPAddress,
        
        [Parameter(Mandatory = $true)]
        [string]$EndIPAddress
    )
    
    Begin{}
    
    Process{
        $StartIPAddressArray = $StartIPAddress -split '\.' 
        [Array]::Reverse($StartIPAddressArray)
        
        $EndIPAddressArray = $EndIPAddress -split '\.' 
        [Array]::Reverse($EndIPAddressArray)  
        
        Try
        {
            $FirstIPAddress = ([System.Net.IPAddress]($StartIPAddressArray -join '.')).Address
            $LastIPAddress = ([System.Net.IPAddress]($EndIPAddressArray -join '.')).Address
            
            For ($x = $FirstIPAddress; $x -le $LastIPAddress; $x++) 
            {     
                $IP = [System.Net.IPAddress]$x -split '\.' 
                [Array]::Reverse($IP)    
                $IP -join '.'  
            }
        }
        Catch
        {
            Write-Warning -Message "$($_.Exception.InnerException.InnerException.Message)"
        }

    }
    
    End{}
}



