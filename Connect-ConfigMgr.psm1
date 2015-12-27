#requires -Version 3
function Connect-ConfigMgr
{
    [cmdletbinding()]
    
    Param()
    
    Begin{}
    
    Process{
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
    
    End{}
}
