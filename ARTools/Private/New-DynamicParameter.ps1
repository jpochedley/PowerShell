using namespace System.Management.Automation

function New-DynamicParameter
{ 
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'Low')]
    
    Param ( 
        [Parameter(Mandatory = $True)]
        [string]$Name,
        
        [Parameter(Mandatory = $False)]
        [string[]]$ValidateSetOptions,
        
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
        [RuntimeDefinedParameterDictionary]$ParameterDictionary = $null
    )
    
    Begin{}
    
    Process{
        If($PSCmdlet.ShouldProcess((Get-PSCallStack).FunctionName, 'Create Dynamic Parameter')){
            $AttributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        
            $ParamAttribute = [ParameterAttribute]::new()
        
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
                $ParameterOptions = [ValidateSetAttribute]::new($ValidateSetOptions)
                $AttributeCollection.Add($ParameterOptions)
            }
        
            $RuntimeParameter = [RuntimeDefinedParameter]::new($Name, $TypeConstraint, $AttributeCollection)
        
            If($null -ne $ParameterDictionary)
            {
                $ParameterDictionary.Add($Name,$RuntimeParameter)
            }
            Else
            {
                $ParameterDictionary = [RuntimeDefinedParameterDictionary]::new()
                $ParameterDictionary.Add($Name,$RuntimeParameter)
            }
        
            $ParameterDictionary
        }
    }
    
    End{}
}


