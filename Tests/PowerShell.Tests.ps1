$Overrides = @{}

If($PSVersionTable.PSVersion.Major -ge 5){
    Describe "Adrian's PowerShell Scripts"{
        Import-Module -Name "$PSScriptRoot\PSScriptAnalyzer\1.2.0\PSScriptAnalyzer.psd1"
    
        $ItemsToEvaluate = Get-ChildItem -Path "$PSScriptRoot\..\" -Recurse -File -Include *.ps1, *psm1, *psd1, *ps1xml | Where-Object -Property Directory -NotMatch -Value 'Tests' 

        Foreach($Item in $ItemsToEvaluate)
        {
            It "$($Item.Name) conforms to PowerShell best practices." {
                $BPAVioloations = Invoke-ScriptAnalyzer -Path $Item.FullName -ExcludeRule PSUsePSCredentialType, PSAvoidUsingWMICmdlet -Severity Warning, Error

                Foreach($Violation in $BPAVioloations)
                {
                    If($Overrides.Keys -contains $Violation.RuleName)
                    { 
                        $Violation | 
                        Where-Object -FilterScript {
                            $Overrides.$($Violation.RuleName) -notmatch $Violation.FileName
                        } | 
                        Select-Object -ExpandProperty RuleName | 
                        ForEach-Object -Process {
                            Write-Warning -Message "$_ rule violation: $($Item.FullName)"
                        
                            $Violation |
                            Should Be $Null
                        }
                    }
                    Else
                    {
                        $Violation | 
                        Select-Object -ExpandProperty RuleName | 
                        ForEach-Object -Process {
                            Write-Warning -Message "$_ rule violation: $($Item.FullName)"
                        
                            $Violation |
                            Should Be $Null
                        }
                    }
                }
            }
        }
    }
}
