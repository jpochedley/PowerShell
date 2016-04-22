function Get-DellWarranty 
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [string[]]$ComputerName
    )

    Begin{
        $DellWebProxy = New-WebServiceProxy -Uri 'http://xserv.dell.com/services/AssetService.asmx?WSDL'
        $DellWebProxy.Url = 'http://xserv.dell.com/services/AssetService.asmx'

        $CMSite = Get-ConfigMgrSite
    }

    Process{
        Foreach($Computer in $ComputerName)
        {
            $ResourceID = Get-WmiObject -Namespace "root\sms\site_$($CMSite.SiteCode)" -ComputerName $CMSite.SiteServer -ClassName SMS_R_System -Filter "Name='$Computer'" | Select-Object -ExpandProperty ResourceID

            $ServiceTag = Get-WmiObject -Namespace "root\sms\site_$($CMSite.SiteCode)" -ComputerName $CMSite.SiteServer -ClassName SMS_G_System_PC_BIOS -Filter "ResourceID='$ResourceID'" | 
            ForEach-Object -Process{
                If($_.Manufacturer -match 'Dell')
                {
                    $_.SerialNumber
                }
                Else
                {
                    Write-Warning -Message "$($Computer.ToUpper()) is not a Dell product."
                    Return
                }
            }

            $Model = Get-WmiObject -Namespace "root\sms\site_$($CMSite.SiteCode)" -ComputerName $CMSite.SiteServer -ClassName SMS_G_System_COMPUTER_SYSTEM -Filter "ResourceID='$ResourceID'" | Select-Object -ExpandProperty Model

            $WarrantyInformation = $WebProxy.GetAssetInformation(([guid]::NewGuid()).Guid, 'Dell Warranty', $ServiceTag)
            $Info = $WarrantyInformation |
            Select-Object -ExpandProperty Entitlements |
            Where-Object -FilterScript{
                $_.EntitlementType -eq 'Active'
            }

            If($null -ne $Info)
            {
                $Info | Select-Object -Property @{
                    n = 'ComputerName'
                    e = {
                        $Computer.ToUpper()
                    }
                }, @{
                    n = 'Model'
                    e = {
                        $Model
                    }
                }, @{
                    n = 'SerialNumber'
                    e = {
                        $ServiceTag
                    }
                }, *
            }
        }
    }

    End{}
}


