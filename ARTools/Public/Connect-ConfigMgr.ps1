#requires -Version 2
function Connect-ConfigMgr
{
    Try
    {
        Import-Module -Name "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1" -Global -ErrorAction Stop
        $SiteCode = (Get-PSDrive -PSProvider CMSite).Name
        Set-Location -Path "$SiteCode`:\"
    }
    Catch
    {
        Write-Warning -Message "Could not import ConfigurationManager module. $($_.Exception.Message)"
    }
}


