function Get-DomainPC
{
    [cmdletbinding(DefaultParameterSetName = 'Default')]
    
    Param(
		[Parameter(Mandatory = $True,ParameterSetName = 'ByName')]
		[string]$Name,

		[Parameter(Mandatory = $True,ParameterSetName = 'ByDescription')]
		[string]$Description,

        [Parameter(Mandatory = $True)]
        [string]$OU
    )
    
    Begin{}
    
    Process{
		If($PSCmdlet.ParameterSetName -eq 'ByName')
		{
			$Filter = "name -like '$Name'"
		}
		ElseIf($PSCmdlet.ParameterSetName -eq 'ByDescription')
		{
			$Filter = "description -like '$Description'"
		}
		Else
		{
			$Filter = '*'
		}

		Get-ADComputer -Filter $Filter -SearchBase $OU -Properties Description
    }
    
    End{}
}

Get-Alias -Name gpcs -ErrorAction SilentlyContinue | Remove-Item -Force
New-Alias -Name gpcs -Value Get-DomainPC -Description 'Get all domain PCs.'


