#requires -Version 2
function Remove-WorkstationPrinter
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [string]$PrintServer,

        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [string[]]$PrinterName,
        
        [Parameter(Mandatory = $False,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = 'localhost',

        [Parameter(Mandatory = $False)]
        [pscredential]$Credential
    )
    
    Begin{}
    
    Process{
        [scriptblock]$Scriptblock = {
            $PrintServer = $Using:PrintServer
            $PrinterName = $Using:PrinterName
            $VerbosePreference = $Using:VerbosePreference
            $WarningPreference = $Using:WarningPreference

            Foreach($Printer in $PrinterName)
            {
                Start-Process -FilePath $env:windir\System32\rundll32.exe -ArgumentList "printui.dll,PrintUIEntry /gd /n\\$PrintServer\$Printer" -Verb RunAs -PassThru -WindowStyle Hidden | Wait-Process -TimeoutSec 20 -ErrorAction SilentlyContinue
                
                $Verification = 'Installed'
                $Verification = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' |
                ForEach-Object -Process {
                    $PSItem |
                    Get-ItemProperty -Name Printer |
                    Select-Object -ExpandProperty Printer
                } |
                Where-Object -FilterScript {
                    $PSItem -imatch "\\\\$PrintServer\\$Printer"
                }
        
                If($null -eq $Verification)
                {
                    Write-Verbose -Message "$($Printer.ToUpper()) printer successfully removed from $($env:computername.ToUpper())."
                }
                Else
                {
                    Write-Warning -Message "Failed to remove $($Printer.ToUpper()) printer from $($env:computername.ToUpper())"
                }
            }

            Get-Process -Name rundll32 -ErrorAction SilentlyContinue | Stop-Process -Force
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
        
        Invoke-Command @InvokeArgs
    }
    
    End{}
}


