@{
        Copyright = '(c) 2015 Adrian Rodriguez. All rights reserved.'
        PrivateData = @{
            PSData = @{
                ReleaseNotes = 'Updated Convert-ArrayToString and Convert-HashToString functions.'
            }
        }
        Description = 'PowerShell module for performing various tasks.'
        PowerShellVersion = '5.0'
        TypesToProcess = '.\ARTools.ps1xml'
        Author = 'Adrian Rodriguez'
        RequiredModules = @()
        NestedModules = @()
        GUID = 'd7a7df2e-b156-4992-a7f9-c7f66a5d823a'
        RootModule = '.\ARTools.psm1'
        VariablesToExport = '*'
        AliasesToExport = '*'
        ModuleVersion = '2016.5.7.2'
        FormatsToProcess = '.\ARTools.format.ps1xml'
        FunctionsToExport = @(
            'Add-LocalGroupMember', 
            'Add-WorkstationPrinter', 
            'Confirm-ADGroupMembership', 
            'Connect-ConfigMgr', 
            'Connect-Exchange', 
            'Connect-Lync', 
            'Connect-RDP', 
            'Connect-Viewer', 
            'Convert-ArrayToString', 
            'Convert-HashToString', 
            'ConvertFrom-EncodedCommand', 
            'ConvertTo-EncodedCommand', 
            'Disable-User', 
            'Disconnect-LoggedOnUser', 
            'Enable-RemotePSRemoting', 
            'Find-AlternateEmailAddress', 
            'Find-ErrorEventLog', 
            'Find-UnquotedServicePath', 
            'Get-ADGroupMembershipTree', 
            'Get-ADPrincipalGroupMembershipTree', 
            'Get-BitlockerKey', 
            'Get-ConfigMgrAppInfo', 
            'Get-DellWarranty', 
            'Get-DomainPC', 
            'Get-InstalledProgram', 
            'Get-IPAddressRange', 
            'Get-LocalGroupMembership', 
            'Get-LockOutInfo', 
            'Get-LoggedOnUser', 
            'Get-MailboxFolderSize', 
            'Get-Phonetic', 
            'Get-ServiceExecutablePermission', 
            'Get-StaleDomainUser', 
            'Get-StaleLocalUser', 
            'Get-WorkstationPrinter', 
            'Import-Credential', 
            'Invoke-ConfigMgrInstallation', 
            'Invoke-ConfigMgrUpdate', 
            'Invoke-Installation', 
            'New-AudioNotification', 
            'New-EchosignUser', 
            'New-RandomPassword', 
            'New-User', 
            'New-VisualNotification', 
            'Remove-Installation', 
            'Remove-LocalGroupMember', 
            'Remove-Signature', 
            'Remove-UserProfile', 
            'Remove-WorkstationPrinter', 
            'Repair-Installation', 
            'Reset-ADPassword', 
            'Reset-WindowsUpdate', 
            'Save-Credential', 
            'Search-ADAccountByName', 
            'Send-NetMessage', 
            'Set-Signature', 
            'Split-Array', 
            'Start-VSDiffMerge', 
            'Test-Ping', 
            'Test-SNMPCommunityString', 
            'Test-TCPPort', 
            'Update-ConfigMgrApplicationDeploymentTypeScript'
        )
        CmdletsToExport = '*'
    }

