#requires -Version 2
function Test-PSRemoting 
{
    [cmdletbinding()]
    
    Param(
        [Parameter(Mandatory = $True,Position = 0)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )
    
    Begin{}
    
    Process{
        $ScriptBlock = {$env:COMPUTERNAME}
    
        $InvokeArgs = @{
            ComputerName = $ComputerName
            ScriptBlock = $ScriptBlock
        }
        
        If($null -ne $Credential){
            $InvokeArgs.Credential = $Credential
        }
        
        Invoke-Command @InvokeArgs -ErrorAction SilentlyContinue -ErrorVariable Failures
            
        ForEach($Item in $Failures){
            Write-Warning -Message "Unable to establish remote session with $($Item.TargetObject)."
        }
    }
    
    End{}
}


