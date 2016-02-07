function Get-BitlockerKey
{
	[CmdletBinding()]

	Param(
		[Parameter(Mandatory = $True,Position = 0,ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputerName','DNSHostName')]
        [string[]]$ComputerName
	)

	Begin{
		$BitlockerKeys = get-adobject -filter "objectclass -eq 'msFVE-RecoveryInformation'" -Properties DistinguishedName, msFVE-RecoveryPassword, WhenCreated
	}

	Process{
		Foreach($Computer in $ComputerName){
			Try{
				$null = Get-ADComputer -Identity $Computer -ErrorAction Stop

				[pscustomobject]@{
					ComputerName = $Computer.ToUpper()
					RecoveryKey = $BitlockerKeys.Where({$_.DistinguishedName -match "CN=$Computer,"})[-1].'msFVE-RecoveryPassword'
				}
			}
			Catch{
				Write-Warning -Message "$($_.Exception.Message)"
			}
		}
	}

	End{}
}


