function Confirm-ADGroupMembership
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$Identity,
        
        [Parameter(Mandatory = $True, Position = 1)]
        [string[]]$Members
    )

    Begin{
        Try
        {
            $Group = Get-ADGroup -Identity $Identity -ErrorAction Stop
            $GroupMembers = Get-ADGroupMember -Identity $Identity -Recursive | Select-Object -ExpandProperty SamAccountName
        }
        Catch
        {
            $_
            Break
        }
    }

    Process{
        Foreach($User in $Members)
        {
            [pscustomobject]@{
                Username = $User
                Group    = $Group.Name
                IsMember = $User -in $GroupMembers
            }
        }
    }

    End{}
}


