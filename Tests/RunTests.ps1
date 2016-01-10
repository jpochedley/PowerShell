Import-Module -Name "$PSScriptRoot\Pester\3.3.5\Pester.psd1"

$BuildResult = Invoke-Pester -Script "$PSScriptRoot\PowerShell*.Tests.ps1" -OutputFormat NUnitXml -OutputFile "$PSScriptRoot\TestResult.xml" -PassThru

If($BuildResult.FailedCount -gt 0){
	Throw "$($BuildResult.FailedCount) tests failed."
}