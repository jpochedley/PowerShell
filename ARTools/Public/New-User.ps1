#requires -Version 3

function New-User
{
    [cmdletbinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]

    Param(
        [Parameter(Mandatory = $True,ParameterSetName = 'SpecificUser')]
        [string]$ReferenceUsername,

        [Parameter(Mandatory = $True,ParameterSetName = 'Browse')]
        [switch]$Browse,

		[Parameter(Mandatory = $True, ParameterSetName = 'Browse')]
		[string[]]$Offices,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    $ProposedUsername = $_
                    $Exists = Get-ADUser -Filter "SamAccountName -eq '$ProposedUsername'" -ErrorAction Stop
                    If($Exists)
                    {
                        Throw "Object found with identity: '$ProposedUsername'."
                    }
                    Else
                    {
                        If($ProposedUsername -cmatch "^[a-z0-9\.]{1,19}$")
                        {
                            $True
                        }
                        Else
                        {
                            Throw 'Please ensure username contains only lowercase letters, numbers, and/or a period.'
                        }
                    }
                }
        )]
        [ValidateLength(3,20)]
        [Alias('Username')]
        [string]$SamAccountName,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    If($_ -cmatch "^[A-Z][A-Za-z0-9_-]{1,19}$")
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please capitalize first letter of first name.'
                    }
                }
        )]
        [string]$FirstName,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({
                    If($_ -cmatch "^[A-Z][A-Za-z0-9_-]{1,19}$")
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please capitalize first letter of last name.'
                    }
                }
        )]
        [string]$LastName,
        
        [Parameter(Mandatory = $False)]
        [ValidateScript({
                    If($_ -cmatch "^[A-Z]$")
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please capitalize middle initial.'
                    }
                }
        )]
        [string]$MiddleInitial = $null,
        
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [securestring]$Password = (New-RandomPassword).SecureStringObject,
        
        [Parameter(Mandatory = $True)]
        [string]$Server
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

		$MailboxDatabase = (Get-MailboxDatabase | Select-Object -Property Name | Out-GridView -Title "Select Mailbox Database" -OutputMode Single).Name

		If(-not $MailboxDatabase){
			Write-Warning -Message 'No mailbox database selected. Please try again.'
            Break
		}
    }

    Process{
        If($PSCmdlet.ParameterSetName -eq 'SpecificUser')
        {
            Try
            {
                $ReferenceUser = Get-ADUser -Identity $ReferenceUsername -Properties * -ErrorAction Stop
            }
            Catch
            {
                Write-Warning -Message "Reference user lookup failed. $($_.Exception.Message)"
            }
        }
        Else
        {
            $Office = $Offices | Out-GridView -Title 'Please select a location:' -OutputMode Single
            If($null -ne $Office)
            {
                $Position = Get-ADUser -Filter "Office -like '*$Office*'" -Properties Title -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty Title |
                Sort-Object -Unique |
                Out-GridView -Title 'Please select position:' -OutputMode Single
                If($null -ne $Position)
                {
                    $UserSelection = Get-ADUser -Filter "Office -like '*$Office*' -and Title -eq '$Position'" -Properties MemberOf, Title -ErrorAction SilentlyContinue |
                    Select-Object -Property Name, SamAccountName, Title, @{
                        name = 'Memberships'
                        e    = {
                            ($_.MemberOf.ForEach({
                                        $_.split(',', 2)[0].replace('CN=', '')
                                })|
                            Sort-Object) -join "`r`n"
                        }
                    }, @{
                        name = 'MembershipCount'
                        e    = {
                            $_.MemberOf.Count
                        }
                    } |
                    Sort-Object -Property MembershipCount |
                    Out-GridView -Title 'Please select user to copy:' -OutputMode Single
                    If($null -ne $UserSelection)
                    {
                        Try
                        {
                            $ReferenceUser = Get-ADUser -Identity $UserSelection.samaccountname -Properties * -ErrorAction Stop
                        }
                        Catch
                        {
                            Write-Warning -Message "Reference user selection failed. $($_.Exception.Message)"
                        }
                    }
                    Else
                    {
                        Write-Warning -Message 'No reference user selected. Please select a user and try again.'
                    }
                }
                Else
                {
                    Write-Warning -Message 'No position selected. Please select a position and try again.'
                }
            }
            Else
            {
                Write-Warning -Message 'No location provided. Please select a location and try again.'
            }
        }
        
        If($null -ne $ReferenceUser)
        {
            $NewUserAttributes = @{
                Department            = $ReferenceUser.Department
                Manager               = $ReferenceUser.Manager
                Office                = $ReferenceUser.Office
                Description           = $ReferenceUser.Description
                Title                 = $ReferenceUser.Title
                Path                  = $ReferenceUser.DistinguishedName -split ',', 2 | Select-Object -Last 1
                ScriptPath            = $ReferenceUser.ScriptPath
                HomeDrive             = $ReferenceUser.HomeDrive
                HomeDirectory         = $ReferenceUser.HomeDirectory |
                Split-Path -Parent -ErrorAction SilentlyContinue |
                Join-Path -ChildPath "\$SamAccountName" -ErrorAction SilentlyContinue
                Company               = $ReferenceUser.Company
                SamAccountName        = $SamAccountName
                UserPrincipalName     = "$SamAccountName@$env:USERDNSDOMAIN"
                GivenName             = $FirstName
                Surname               = $LastName
                Initials              = $MiddleInitial
                DisplayName           = "$FirstName $MiddleInitial $LastName" -replace '  ', ' '
                Name                  = "$FirstName $MiddleInitial $LastName" -replace '  ', ' '
                CannotChangePassword  = $False
                AccountPassword       = $Password
                ChangePasswordAtLogon = $True
                PasswordNeverExpires  = $False
                Enabled               = $True
                Server                = $Server
                ErrorAction           = 'Stop'
            }

            If($PSCmdlet.ShouldProcess($NewUserAttributes.Name))
            {
                Try
                {
                    Write-Verbose -Message 'Creating new user ...'
                    New-ADUser @NewUserAttributes
                    Write-Verbose -Message 'New user created successfully.'

                    $Groups = Get-ADPrincipalGroupMembership -Identity $ReferenceUser.samaccountname |
                    Where-Object -Property Name -NE -Value 'Domain Users' |
                    Select-Object -ExpandProperty SamAccountName

                    Foreach($Group in $Groups)
                    {
                        Try
                        {
                            Write-Verbose -Message "Adding user to $Group group ..."
                            Add-ADGroupMember -Identity $Group -Members $SamAccountName -Server $Server -ErrorAction Stop
                            Write-Verbose -Message "User added to $Group group successfully."
                        }
                        Catch
                        {
                            Write-Warning -Message "Unable to add user to $Group group. $($_.Exception.Message)"
                        }
                    }

                    Try
                    {
                        Write-Verbose -Message 'Creating Home Directory ...'

                        $null = New-Item -Path $NewUserAttributes.HomeDirectory -ItemType Directory -ErrorAction Stop

                        $Exists = $False

                        do
                        {
                            $Exists = Test-Path -Path $NewUserAttributes.HomeDirectory
                        }
                        until($Exists)

                        $AccessRuleObject = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList "$env:USERDOMAIN\$SamAccountName", 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'

                        $ACL = Get-Acl -Path $NewUserAttributes.HomeDirectory

                        Try
                        {
                            $ACL.AddAccessRule($AccessRuleObject)
                            Set-Acl -Path $NewUserAttributes.HomeDirectory -AclObject $ACL -ErrorAction Stop
                            Write-Verbose -Message 'Home Directory created successfully.'
                        }
                        Catch
                        {
                            Write-Warning -Message "Could not set permissions on home directory. $($_.Exception.Message)"
                        }
                    }
                    Catch
                    {
                        Write-Warning -Message "Home Directory creation failed. $($_.Exception.Message)"
                    }

                    Try
                    {
                        Write-Verbose -Message 'Creating user mailbox ...'
                        $null = Enable-Mailbox -Identity $NewUserAttributes.UserPrincipalName -Database $MailboxDatabase -DomainController $Server -ErrorAction Stop
                        Write-Verbose -Message 'User mailbox created successfully.'
                    }
                    Catch
                    {
                        Write-Warning -Message "User mailbox creation failed. $($_.Exception.Message)"
                    }
                    
                    Try
                    {
                        Write-Verbose -Message 'Providing Lync access ...'
                        $null = Enable-CsUser -Identity $NewUserAttributes.UserPrincipalName -RegistrarPool (Get-PSSession -Name Lync).ComputerName -SipAddressType UserPrincipalName -ErrorAction Stop
                        Write-Verbose -Message 'Lync access provided successfully.'
                    }
                    Catch
                    {
                        Write-Warning -Message "Could not provide access to Lync. $($_.Exception.Message)"
                    }
                }
                Catch
                {
                    Write-Warning -Message "New user creation failed. $($_.Exception.Message)"
                }
            }
        }
    }

    End{}
}


