function New-DynamicParameter
{ 
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'Low')]
    
    Param ( 
        [Parameter(Mandatory = $True)]
        [string]$Name,
        
        [Parameter(Mandatory = $False)]
        [array]$ValidateSetOptions,
        
        [Parameter(Mandatory = $False)]
        [System.Type]$TypeConstraint = [string],
        
        [Parameter(Mandatory = $False)]
        [switch]$Mandatory,
        
        [Parameter(Mandatory = $False)]
        [string]$ParameterSetName = $null,
        
        [Parameter(Mandatory = $False)]
        [switch]$ValueFromPipeline,
        
        [Parameter(Mandatory = $False)]
        [switch]$ValueFromPipelineByPropertyName,
        
        [Parameter(Mandatory = $False)]
        [System.Management.Automation.RuntimeDefinedParameterDictionary]$ParameterDictionary = $null
    )
    
    Begin{}
    
    Process{
        If($PSCmdlet.ShouldProcess((Get-PSCallStack).FunctionName, 'Create Dynamic Parameter')){
            $AttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
        
            $ParamAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
        
            $ParamAttribute.Mandatory = $Mandatory
        
            If($null -ne $ParameterSetName)
            {
                $ParamAttribute.ParameterSetName = $ParameterSetName
            }
        
            $ParamAttribute.ValueFromPipeline = $ValueFromPipeline
        
            $ParamAttribute.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName
        
            $AttributeCollection.Add($ParamAttribute)
        
            If($null -ne $ValidateSetOptions)
            {
                $ParameterOptions = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSetOptions
                $AttributeCollection.Add($ParameterOptions)
            }
        
            $RuntimeParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ($Name, $TypeConstraint, $AttributeCollection)
        
            If($null -ne $ParameterDictionary)
            {
                $ParameterDictionary.Add($Name,$RuntimeParameter)
            }
            Else
            {
                $ParameterDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
                $ParameterDictionary.Add($Name,$RuntimeParameter)
            }
        
            $ParameterDictionary
        }
    }
    
    End{}
}

Export-ModuleMember -Function * -Verbose:$False


