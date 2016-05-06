Remove-Item $PSScriptRoot\..\ARTools -Recurse -Force

Copy-Item $PSScriptRoot\..\..\ARTools\ARTools -Destination $PSScriptRoot\..\ -Container -Recurse

Get-ChildItem -Path $PSScriptRoot\..\ARTools -File -Recurse -Include *-XP*,*Data*,*-CNS*,*-TeR*,Validate-*.txt | Remove-Item -Force

$FunctionsToExport = (Get-ChildItem -Path $PSScriptRoot\..\ARTools\Public | Select -ExpandProperty BaseName | Foreach{"'$_'"}) -join ",`r`n`t`t"

@"
@{
    ModuleVersion     = '2016.5.5'
	PrivateData       = @{
        PSData = @{
            # ReleaseNotes of this module
            ReleaseNotes = 'Fixed issue with New-User function.'

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''
        }
    }
    GUID              = 'd7a7df2e-b156-4992-a7f9-c7f66a5d823a'
    Author            = 'Adrian Rodriguez'
	Description       = 'PowerShell module for performing various tasks.'
    Copyright         = '(c) 2015 Adrian Rodriguez. All rights reserved.'
    PowerShellVersion = '5.0'
    RequiredModules   = @()
	RootModule        = '.\ARTools.psm1'
    TypesToProcess    = '.\ARtools.ps1xml'
    FormatsToProcess  = '.\ARTools.format.ps1xml'
    NestedModules     = @()
    FunctionsToExport = @(
        $FunctionsToExport
    )
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
}
"@ | Out-File -FilePath $PSScriptRoot\..\ARTools\ARTools.psd1 

Get-ChildItem -Path $PSScriptRoot\..\ARTools -File -Recurse |
Remove-Signature