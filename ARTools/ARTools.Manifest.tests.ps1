Describe "ARTools Module Manifest" {
	It "FunctionsToExport key contains all public functions." {
		$ManifestAST = [System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot\ARTools.psd1",[ref]$null,[ref]$null)

		$ManifestHashTable = $ManifestAST.FindAll({$args[0] -is [System.Management.Automation.Language.HashtableAst]}, $true).SafeGetValue()

		$FunctionsToExport = $ManifestHashTable.FunctionsToExport

		Get-ChildItem -Path $PSScriptRoot\Public | Select-Object -ExpandProperty BaseName | Where-Object -FilterScript {$_ -notin $FunctionsToExport} | Should Be $Null
	}
}


