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

		Class  ARToolsBitlockerKey {
			[string]$ComputerName
			[string]$RecoveryKey

			#Method
			[void] Read() {
				[char[]]$Characters = $this.RecoveryKey

				Foreach($Char in $Characters){
					New-AudioNotification -Message $Char
				}
			}

			#Constructor
			ARToolsBitlockerKey ([string]$ComputerName,[string]$RecoveryKey) {
				$this.ComputerName = $ComputerName
				$this.RecoveryKey = $RecoveryKey
			}
		}
	}

	Process{
		Foreach($Computer in $ComputerName){
			Try{
				$null = Get-ADComputer -Identity $Computer -ErrorAction Stop

				[ARBitlockerKey]::New($Computer.ToUpper(),$BitlockerKeys.Where({$_.DistinguishedName -match "CN=$Computer,"})[-1].'msFVE-RecoveryPassword')
			}
			Catch{
				Write-Warning -Message "$($_.Exception.Message)"
			}
		}
	}

	End{}
}


