#requires -Version 2
function Get-ConfigMgrSite
{
    [cmdletbinding()]

    Param()
    
    Begin{}
    
    Process{
        $ManagementPointSearcher = [adsisearcher]'ObjectClass=mssmsmanagementpoint'
        $ManagementPointADObject = $ManagementPointSearcher.FindOne() | Select-Object -ExpandProperty Properties
        
        [pscustomobject]@{
            SiteServer = $ManagementPointADObject.mssmsmpname[0]
            SiteCode   = $ManagementPointADObject.mssmssitecode[0]
            PSTypeName = 'ARTools.ConfigMgrSite'
        }
    }
    
    End{}
}

Export-ModuleMember -Function * -Verbose:$False


