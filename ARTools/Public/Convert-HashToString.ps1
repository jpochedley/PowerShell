function Convert-HashToString
{
    [cmdletbinding()]
    
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [Hashtable[]]$Hashtable,
        
        [Parameter(Mandatory=$False)]
        [switch]$Flatten
    )
    
    Begin{
        If($Flatten)
        {
            $Mode = 'Append'
        }
        Else
        {
            $Mode = 'AppendLine'
        }
        
        If($Flatten)
        {
            $Indenting = ''
        }
        Else{
            $Indenting = '    '
            $RecursiveIndenting = '    ' * (Get-PSCallStack).Where({$_.Command -eq 'Convert-HashToString' -and $_.InvocationInfo.CommandOrigin -eq 'Internal' -and $_.InvocationInfo.Line -notmatch '\$This'}).Count
        }
        
    }
    
    Process{
        Foreach($Item in $Hashtable)
        {
            $StringBuilder = [System.Text.StringBuilder]::new()
            
            [void]$StringBuilder.$Mode("@{")
            
            Foreach($Key in $Item.Keys)
            {
                $Value = $Item[$Key]
                
                If($Key -match '\s')
                {
                    $Key = "'$Key'"
                }
                
                If($Value -is [String])
                {
                    [void]$StringBuilder.$Mode($Indenting + $RecursiveIndenting + "$Key = '$Value'")
                }
                ElseIf($Value -is [int] -or $Value -is [double])
                {
                    [void]$StringBuilder.$Mode($Indenting + $RecursiveIndenting + "$Key = $($Value.ToString())")
                }
                ElseIf($Value -is [array])
                {
                    $Value = Convert-ArrayToString -Array $Value
                    
                    [void]$StringBuilder.$Mode($Indenting + $RecursiveIndenting + "$Key = $Value")
                }
                ElseIf($Value -is [hashtable])
                {
                    $Value = Convert-HashToSTring -Hashtable $Value -Flatten:$Flatten
                    [void]$StringBuilder.$Mode($Indenting + $RecursiveIndenting + "$Key = $Value")
                }
                Else
                {
                    Throw "Key value is not of known type."    
                }
                
                If($Flatten){[void]$StringBuilder.Append("; ")}
            }
            
            [void]$StringBuilder.Append($RecursiveIndenting + "}")
            
            $StringBuilder.ToString().Replace("; }",'}')
        }
    }
    
    End{}
}

Remove-TypeData -TypeName System.Collections.HashTable -ErrorAction SilentlyContinue
Update-TypeData -TypeName System.Collections.HashTable -MemberType ScriptMethod -MemberName ToString -Value {Convert-HashToString $This}


