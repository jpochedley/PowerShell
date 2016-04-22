#requires -Version 2
function Add-WorkstationPrinter
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('Server')]
        [string]$PrintServer,

        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('Printer')]
        [string[]]$PrinterName,
        
        [Parameter(Mandatory = $False,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = 'localhost',
        
        [Parameter(Mandatory = $False)]
        [pscredential]$Credential = $null
    )
    
    Begin{}
    
    Process{
        [scriptblock]$Scriptblock = {
            $VerboseSwitch = $Using:PSBoundParameters.Verbose
            $WarningPreference = $Using:WarningPreference

            Foreach($Printer in $Using:PrinterName)
            {
                Start-Process -FilePath $env:windir\System32\rundll32.exe -ArgumentList "printui.dll,PrintUIEntry /ga /n`"\\$Using:PrintServer\$Printer`"" -Verb RunAs -PassThru -WindowStyle Hidden | Wait-Process -TimeoutSec 20 -ErrorAction SilentlyContinue
                
                $Verification = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' |
                ForEach-Object -Process {
                    $PSItem |
                    Get-ItemProperty -Name Printer |
                    Select-Object -ExpandProperty Printer
                } |
                Where-Object -FilterScript {
                    $PSItem -imatch "\\\\$Using:PrintServer\\$Printer"
                }
                
                If($null -ne $Verification)
                {
                    Write-Verbose -Message "$($Printer.ToUpper()) printer successfully added to $($env:computername.ToUpper())." -Verbose:$VerboseSwitch
                }
                Else
                {
                    Write-Error -Message "Failed to add $($Printer.ToUpper()) printer to $($env:computername.ToUpper())"
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


