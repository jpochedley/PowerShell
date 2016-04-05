#requires -Version 2
function Get-WorkstationPrinter
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $False)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = 'localhost',
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )
    
    Begin{}
    
    Process{
        [scriptblock]$ScriptBlock = {
            $WarningPreference = $Using:WarningPreference
            
            $Connections = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' | ForEach-Object -Process {
                $PSItem |
                Get-ItemProperty -Name Printer |
                Select-Object -ExpandProperty Printer
            }
            
            Foreach($Connection in $Connections)
            {
                $null = $Connection -match "^\\\\(?<PrintServer>.*)\\(?<PrinterName>.*)$"
                
                [pscustomobject]@{
                    PrintServer = $Matches.PrintServer
                    PrinterName = $Matches.PrinterName
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
        
        $InvokeArgs.ScriptBlock = $ScriptBlock
        
        Invoke-Command @InvokeArgs | Select-Object -Property * -ExcludeProperty RunspaceID
    }
    
    End{}
}


