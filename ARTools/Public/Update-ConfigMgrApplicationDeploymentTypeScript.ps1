Function Update-ConfigMgrApplicationDeploymentTypeScript
{
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
    
    Param(
        [Parameter(Mandatory = $True)]
        [System.IO.FileInfo]$ScriptPath
    )
    
    DynamicParam{
        $CMSite = Get-ConfigMgrSite
        
        $RuntimeParamDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        
        $DynamicParameterOptions = @(
            @{
                Name                = 'ApplicationName'
                Mandatory           = $True
                ParameterDictionary = $RuntimeParamDictionary
                ValidateSetOptions  = Get-WmiObject -ComputerName $CMSite.SiteServer -Namespace "root\SMS\site_$($CMSite.SiteCode)" -Class SMS_Application -Filter 'IsLatest=1' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalizedDisplayName
            }, 
            @{
                Name                = 'DeploymentTypeName'
                Mandatory           = $True
                ParameterDictionary = $RuntimeParamDictionary
                ValidateSetOptions  = Get-WmiObject -ComputerName $CMSite.SiteServer -Namespace "root\SMS\site_$($CMSite.SiteCode)" -Class SMS_DeploymentType -Filter 'IsLatest=1' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalizedDisplayName
            }
        )
        
        Foreach($Param in $DynamicParameterOptions)
        {
            $null = New-DynamicParameter @Param
        }
        
        $RuntimeParamDictionary
    }
    
    Begin{
        $ApplicationName = $PSBoundParameters['ApplicationName']
        
        $DeploymentTypeName = $PSBoundParameters['DeploymentTypeName']
    
        # Ensure FileSystem location is used as Get-Content functionality used below only functions with the FileSystem PS Provider.
        Push-Location -Path C:\Windows\System32
    
        $EncodedScriptBeginTag = "`r`n`r`n# ENCODEDSCRIPT # Begin Configuration Manager encoded script block # "

        $EncodedScriptEndTag = " # ENCODEDSCRIPT# End Configuration Manager encoded script block`r`n`r`n"
    }

    Process{
        If(-not $ScriptPath.Exists)
        {
            Throw "Script file '$ScriptPath' does not exist."
        }
        
        # Obtain script contents in both text and binary form. Binary form is necessary for proper parsing by ConfigMgr client.
        $Script = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
        $BinaryScript = Get-Content -Path $ScriptPath -Encoding byte -Raw -ErrorAction Stop
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        
        # Connect to ConfigMgr site so ConfigurationManager cmdlets and functions can be used.
        Connect-ConfigMgr
        
        # Choose application deployment to update
        $DeploymentType = Get-CMDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $DeploymentTypeName
        
        If($null -eq $DeploymentType)
        {
            Throw 'Could not find application or deployment type matching input parameters.'
        }
        
        If($DeploymentType.Technology -notmatch 'MSI|Script')
        {
            Throw "Can only modify MSI & Script deployment types. Deployment type was of type '$($DeploymentType.Technology)'"
        }
    
        If($PSCmdlet.ShouldProcess($($DeploymentType.LocalizedDisplayName)))
        {   
            # Add script text to StringBuilder
            # This part isn't completely necessary but we want to make sure anybody casually looking at this in the admin console will know that editing it is a bad idea  
            $null = $StringBuilder.AppendLine('## WARNING!! DO NOT MANUALLY EDIT THIS SCRIPT IN THE ADMINISTRATOR CONSOLE.')
            $null = $StringBuilder.AppendLine('## IT WILL BREAK THE SCRIPT EXECUTION ON THE CLIENT.')
            $null = $StringBuilder.AppendLine()
            $null = $StringBuilder.Append($Script)
        
            # Append binary blob including begin/end tags to StringBuilder.
            # This part is absolutely critical as it is this blob that will be processed by the ConfigMgr client during detection.
            $null = $StringBuilder.Append($EncodedScriptBeginTag)
            $null = $StringBuilder.Append([Convert]::ToBase64String($BinaryScript))
            $null = $StringBuilder.Append($EncodedScriptEndTag)
            
            $ScriptContent = $StringBuilder.ToString()
            
            # Update detection script with script contents in both text and binary form
            $DeploymentType | Set-CMDeploymentType -MsiOrScriptInstaller -ScriptType PowerShell -ScriptContent $ScriptContent -DetectDeploymentTypeByCustomScript -ErrorAction Stop
        }
    }
    
    End{
        Pop-Location
    }
}


