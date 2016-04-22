function Start-VSDiffMerge{
	[cmdletbinding()]

	Param(
		[Parameter(Mandatory = $True,Position=0)]
		[System.IO.FileInfo]$ReferenceFile,

		[Parameter(Mandatory = $True,Position=1)]
		[System.IO.FileInfo]$DifferenceFile
	)

	Begin{}

	Process{
		$ReferenceFile, $DifferenceFile |
		ForEach-Object -Process{
			If(-not $_.Exists){Write-Warning -Message "Cannot find path '$($_.FullName)'.";Break}
		}

		If($DTE){
			$DTE.ExecuteCommand("Tools.DiffFiles", "`"$($ReferenceFile.fullname)`" `"$($DifferenceFile.fullname)`"")
		}
		Else{
			Write-Warning -Message "Please run Start-VSDiffMerge from Visual Studio."
		}
	}

	End{}
}

