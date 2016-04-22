#requires -Version 2
function Get-Phonetic 
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true,ValueFromPipeLine = $true)]
        [Char[]]$Char
        
    )
    
    Begin{
        [HashTable]$PhoneticTable = @{
            'a' = 'Alpha'
            'b' = 'Bravo'
            'c' = 'Charlie'
            'd' = 'Delta'
            'e' = 'Echo'
            'f' = 'Foxtrot'
            'g' = 'Golf'
            'h' = 'Hotel'
            'i' = 'India'
            'j' = 'Juliett'
            'k' = 'Kilo'
            'l' = 'Lima'
            'm' = 'Mike'
            'n' = 'November'
            'o' = 'Oscar'
            'p' = 'Papa'
            'q' = 'Quebec'
            'r' = 'Romeo'
            's' = 'Sierra'
            't' = 'Tango'
            'u' = 'Uniform'
            'v' = 'Victor'
            'w' = 'Whiskey'
            'x' = 'X-ray'
            'y' = 'Yankee'
            'z' = 'Zulu'
            '0' = 'Zero'
            '1' = 'One'
            '2' = 'Two'
            '3' = 'Three'
            '4' = 'Four'
            '5' = 'Five'
            '6' = 'Six'
            '7' = 'Seven'
            '8' = 'Eight'
            '9' = 'Nine'
            '.' = 'Period'
            '!' = 'Exclamationmark'
            '?' = 'Questionmark'
            '@' = 'At'
            '{' = 'Left-brace'
            '}' = 'Right-brace'
            '[' = 'Left-bracket'
            ']' = 'Left-bracket'
            '+' = 'Plus'
            '>' = 'Greater-than'
            '<' = 'Less-than'
            '\' = 'Back-slash'
            '/' = 'Forward-slash'
            '|' = 'Pipe'
            ':' = 'Colon'
            ';' = 'Semi-colon'
            '"' = 'Double-quote'
            "'" = 'Single-quote'
            '(' = 'Left-paranthesis'
            ')' = 'Right-paranthesis'
            '*' = 'Asterisk'
            '-' = 'Hyphen'
            '#' = 'Pound'
            '^' = 'Caret'
            '~' = 'Tilde'
            '=' = 'Equals'
            '&' = 'Ampersand'
            '%' = 'Percent'
            '$' = 'Dollar'
            ',' = 'Comma'
            '_' = 'Underscore'
            '`' = 'Backtick'
        }
    }
    
    Process {
        $Result = Foreach($Character in $Char) 
        {
            if($PhoneticTable.ContainsKey("$Character")) 
            {
                if([Char]::IsUpper([Char]$Character)) 
                {
                    [PSCustomObject]@{
                        Char     = $Character
                        Phonetic = "Capital-$($PhoneticTable["$Character"])"
                    }
                }
				ElseIf([Char]::IsLower([Char]$Character)) 
                {
                    [PSCustomObject]@{
                        Char     = $Character
                        Phonetic = "Lowercase-$($PhoneticTable["$Character"])"
                    }
                }
				ElseIf([Char]::IsNumber([Char]$Character))
                {
                    [PSCustomObject]@{
                        Char     = $Character
                        Phonetic = "Number-$($PhoneticTable["$Character"])"
                    }
                }
                else 
                {
                    [PSCustomObject]@{
                        Char     = $Character
                        Phonetic = $PhoneticTable["$Character"]
                    }
                }
            }
            else 
            {
                [PSCustomObject]@{
                    Char     = $Character
                    Phonetic = $Character
                }
            }
        }
        
        $InputText = -join $Char
        
        $TableFormat = $Result |
        Format-Table -AutoSize |
        Out-String
        
        $StringFormat = $Result.Phonetic -join '  '
        
        [hashtable]$Properties = @{
            PhoneticForm = $StringFormat
            Table        = $TableFormat
            InputText    = $InputText
        }
        
        $Object = New-Object -TypeName PSObject -Property $Properties
        $Object.PSObject.Typenames.Insert(0,'ARTools.Phonetic')
        $Object
    }
    
    End{}
}


