function Disable-User
{
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]

    Param(
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    $Identity = $PSItem
                    Try
                    {
                        $null = Get-ADUser -Identity $Identity -ErrorAction Stop
                        $True
                    }
                    Catch
                    {
                        Throw "Cannot find user or group with identity: '$Identity'"
                    }
        })]
        [string[]]$Username,

        [Parameter(Mandatory = $True)]
        [string]$Server,

		[Parameter(Mandatory = $True)]
		[ValidateScript({
                    $Identity = $PSItem
                    Try
                    {
                        $null = Get-ADOrganizationalUnit -Identity $Identity -ErrorAction Stop
                        $True
                    }
                    Catch
                    {
                        Throw "Cannot find the following OU: '$Identity'"
                    }
        })]
		[string]$ExpiredOU,
        
        [Parameter(Mandatory = $False)]
        [double]$DaysToRetain
    )

    Begin{
        Try
        {
            Write-Verbose -Message 'Checking for Exchange session ...'
            $null = Get-PSSession -Name Exchange -ErrorAction Stop
            Write-Verbose -Message 'Exchange session found.'
        }
        Catch
        {
            Write-Warning -Message 'Unable to find Exchange session. Please run Connect-Exchange and try again.'
            Break
        }
        
        Try
        {
            Write-Verbose -Message 'Checking for Lync session ...'
            $null = Get-PSSession -Name Lync -ErrorAction Stop
            Write-Verbose -Message 'Lync session found.'
        }
        Catch
        {
            Write-Warning -Message 'Unable to find Lync session. Please run Connect-Lync and try again.'
            Break
        }
    }

    Process{
        Foreach($User in $Username)
        {
            If($PSCmdlet.ShouldProcess($User))
            {
                $Description = "Disabled on $((Get-Date).ToString('MM-dd-yy')) by $env:USERDOMAIN\$env:USERNAME"
                
                If($null -ne $DaysToRetain)
                {
                    $Description += " | Retain Until $((Get-Date).AddDays($DaysToRetain).ToString('MM-dd-yy'))"
                }
                
				Disable-ADAccount -Identity $User -PassThru -Server $Server -ErrorAction Stop | 

                Move-ADObject -TargetPath $ExpiredOU -Server $Server -PassThru -ErrorAction Stop | 

                Set-ADUser -Description $Description -Server $Server -PassThru -ErrorAction Stop |

                Get-ADUser -Server $Server -Properties MemberOf -ErrorAction Stop |

                Select-Object -ExpandProperty MemberOf |

                ForEach-Object -Process {
                    Remove-ADGroupMember -Identity $_ -Members $User -Server $Server -Confirm:$False -ErrorAction Stop
                }

                Reset-ADPassword -Username $User -Confirm:$False -Server $Server

                Get-Mailbox -Identity $User -DomainController $Server -ErrorAction SilentlyContinue | Set-Mailbox -HiddenFromAddressListsEnabled:$True -DomainController $Server

                Get-CsUser -Identity $User -DomainController $Server -ErrorAction SilentlyContinue | Disable-CsUser -DomainController $Server
            }
        }
    }

    End{}
}

