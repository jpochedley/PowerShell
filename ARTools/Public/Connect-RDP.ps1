function Connect-RDP
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName')]
        [string[]]$ComputerName = $null,
        
        [Parameter(Mandatory = $False)]
        [switch]$Force
    )
    
    Begin{}

    Process{
        If($PSBoundParameters.ContainsKey('ComputerName'))
        {
            Foreach($Computer in $ComputerName)
            {
                $ADSearcher = [adsisearcher]"(&(objectclass=computer)(name=$Computer))"
                
                If($ADSearcher.FindOne().Properties.dnshostname)
                {
                    $Computer = $ADSearcher.FindOne().Properties.dnshostname
                }
                
                If((Test-Connection -ComputerName $Computer -Count 1 -Quiet) -or $Force)
                {
                    Write-Verbose -Message "Connecting to $Computer ..."
                    Start-Process -FilePath $env:windir\System32\mstsc.exe -ArgumentList "/v:$Computer /f" -WindowStyle Normal
                }
                Else
                {
                    Write-Warning -Message "Cannot contact $Computer."
                }
            }
        }
        Else
        {
            Start-Process -FilePath $env:windir\System32\mstsc.exe
        }
    }

    End{}
}


