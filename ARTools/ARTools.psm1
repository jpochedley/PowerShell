$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

Foreach($Import in @($Public + $Private))
{
    Try
    {
        . $Import.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($Import.FullName): $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function $Public.Basename -Alias *

$RequiredModules = @(
	@{Path = 'C:\windows\system32\windowspowershell\v1.0\Modules\ActiveDirectory';Name = 'ActiveDirectory'}
)

Foreach($Module in $RequiredModules)
{
    $Installed = Get-Module -Name $Module.Path -ListAvailable -ErrorAction SilentlyContinue
    
    If(-not $Installed)
    {
        Throw "Unable to import ARTools module. The following critical dependency is missing: $($Module.Name) PowerShell module"
    }
}

$RecommendedModules = @(
	@{Path = "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1";Name = 'ConfigurationManager'}
)

Foreach($Module in $RecommendedModules)
{
    $Installed = Get-Module -Name $Module.Path -ListAvailable -ErrorAction SilentlyContinue
    
    If(-not $Installed)
    {
        Write-Warning "The following component is missing and may affect performance of ARTools module: $($Module.Name) PowerShell module"
    }
}


