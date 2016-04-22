#requires -Version 2
function Get-ADPrincipalGroupMembershipTree
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $True,Position = 0)]
        [string]$Identity,
        
        [Parameter(Mandatory = $False,Position = 1)]
        [string]$Inheritence = $null
    )

    Begin{}

    Process{
        Get-ADPrincipalGroupMembership -Identity $Identity -ErrorAction Stop | 
        
        ForEach-Object -Process {
            $Object = $_
            
            If($Inheritence)
            {
                $Object |
                Get-ADGroup -Properties Description |
                Select-Object -Property Name, SamAccountName, DistinguishedName, Description, @{
                    n = 'Inheritence'
                    e = {
                        $Inheritence
                    }
                }
            }
            Else
            {
                $Object |
                Get-ADGroup -Properties Description |
                Select-Object -Property Name, SamAccountName, DistinguishedName, Description, @{
                    n = 'Inheritence'
                    e = {
                        $null
                    }
                }
            }
            
            If($Inheritence)
            {
                $NewInheritence = "$Inheritence > $($Object.Name)"
                    
                Get-ADPrincipalGroupMembershipTree -Identity $Object.DistinguishedName -Inheritence $NewInheritence
            }
            Else
            {
                Get-ADPrincipalGroupMembershipTree -Identity $Object.DistinguishedName -Inheritence $Object.Name
            }
        } |
        
        Sort-Object -Property Name
    }

    End{}
}


