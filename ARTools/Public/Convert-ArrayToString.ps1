function Convert-ArrayToString
{
    [cmdletbinding()]
    
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [AllowEmptyCollection()]
        [Array]$Array
    )
    
    Begin{}
    
    Process{
        $Value = $Array.Foreach({
            If($_ -is [string])
            {
                "'$_'"
            }
            ElseIf($_ -is [int] -or $_ -is [double])
            {
                $_.ToString()
            }
            ElseIf($_ -is [bool])
            {
                "`$$Value"
            }
            ElseIf($_ -is [array])
            {
                Convert-ArrayToString -Array $_
            }
            ElseIf($_ -is [hashtable])
            {
                Convert-HashToSTring -Hashtable $_ -Flatten
            }
            Else
            {
                Throw "Key value is not of known type."    
            }
        }) -join ', '
        
        "@($Value)"
    }
    
    End{}
}

Remove-TypeData -TypeName System.Object[] -ErrorAction SilentlyContinue
Update-TypeData -TypeName System.Object[] -MemberType ScriptMethod -MemberName ToString -Value {Convert-ArrayToString $This}


