#requires -Version 2
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


