Import-Module ARTools -Force

Remove-Item $PSScriptRoot\..\ARTools -Recurse -Force

Copy-Item $PSScriptRoot\..\..\ARTools\ARTools -Destination $PSScriptRoot\..\ -Container -Recurse

Get-ChildItem -Path $PSScriptRoot\..\ARTools -File -Recurse -Include *-XP*,*Data*,*-CNS*,*-TeR*,Validate-*.txt | Remove-Item -Force

$FunctionsToExport = (Get-ChildItem -Path $PSScriptRoot\..\ARTools\Public).BaseName

$Manifest = Import-PowerShellDataFile -Path $PSScriptRoot\..\ARTools\ARTools.psd1
$Manifest.FunctionsToExport = $FunctionsToExport
Convert-HashToSTring $Manifest | Out-File -FilePath $PSScriptRoot\..\ARTools\ARTools.psd1

Get-ChildItem -Path $PSScriptRoot\..\ARTools -File -Recurse | Remove-Signature