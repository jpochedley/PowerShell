#requires -Version 2
function Get-ConfigMgrAppInfo 
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('LocalizedDisplayName')]
        [string]$ApplicationName
    )

    Begin{
        Push-Location
        
        Connect-ConfigMgr
    }

    Process{
        $Applications = Get-CMApplication -Name $ApplicationName
        
        Foreach($Application in $Applications)
        {
            [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Deserialize($Application.SDMPackageXML)
        }
    }

    End{
        Pop-Location
    }
}


