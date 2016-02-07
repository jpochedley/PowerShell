#requires -Version 2
function Send-NetMessage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [string[]]$ComputerName,
    
        [Parameter(Mandatory = $True)]
        [string]$Message,
    
        [Parameter(Mandatory = $False)]
        [string[]]$Username = $null,
    
        [Parameter(Mandatory = $False)]
		[AllowNull()]
        [int]$TimeoutSeconds = 300
    )
  
    Begin{}

    Process{
        If($null -ne $TimeoutSeconds)
        {
            $PromptSettings = "/TIME:$Timeout"
        }
        Else
        {
            $PromptSettings = '/W'
        }

        If(-not $PSBoundParameters.ContainsKey('Username'))
        {
            $Username = '*'
        }

        Foreach($User in $Username)
        {
            $ArgumentList = "$PromptSettings $User $Message"
            
            $ScriptBlock = {
                Start-Process -FilePath C:\windows\System32\msg.exe -ArgumentList $using:ArgumentList
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
        
            Invoke-Command @InvokeArgs
        }

        Write-Verbose -Message 'Message sent.'
    
    }

    End{}
}


