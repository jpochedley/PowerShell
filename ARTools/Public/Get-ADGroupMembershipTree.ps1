#requires -Version 2
function Get-ADGroupMembershipTree
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
        Try
        {
            $InitialADGroup = Get-ADGroup -Identity $Identity -ErrorAction Stop
        }
        Catch
        {
            $_
            Break
        }
        
        If(-not($PSBoundParameters.ContainsKey('Inheritence')))
        {
            $Inheritence = $InitialADGroup.Name
        }
        
        $InitialADGroup |
        
        Get-ADGroupMember | 
        
        ForEach-Object -Process {
            $Object = $_
                        
            If($Object.Objectclass -eq 'user')
            {
                If($Inheritence)
                {
                    $Object |
                    Select-Object -Property Name, SamAccountName, DistinguishedName, @{
                        n = 'Inheritence'
                        e = {
                            $Inheritence
                        }
                    } 
                }
                Else
                {
                    $Object |
                    Select-Object -Property Name, SamAccountName, DistinguishedName, @{
                        n = 'Inheritence'
                        e = {
                            $InitialADGroup.Name
                        }
                    }
                }
            }
            ElseIf($Object.ObjectClass -eq 'group')
            {
                If($Inheritence)
                {
                    $NewInheritence = "$Inheritence > $($Object.Name)"
                    
                    Get-ADGroupMembershipTree -Identity $Object.DistinguishedName -Inheritence $NewInheritence
                }
                Else
                {
                    Get-ADGroupMembershipTree -Identity $Object.DistinguishedName -Inheritence $Object.Name
                }
            }
        } |
        
        Sort-Object -Property Name
    }

    End{}
}


