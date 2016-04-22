#requires -Version 2
Function New-RandomPassword 
{
    [cmdletbinding(SupportsShouldProcess = $True,ConfirmImpact = 'Low')]
 
    Param (
        [Parameter(Mandatory = $False)]
        [ValidateRange(1,128)]
        [Int]$PasswordLength = 9,
        
        [Parameter(Mandatory = $False)]
        [switch]$ExcludeSpecialCharacters,
        
        [Parameter(Mandatory = $False)]
        [char[]]$ExcludeCharacters = "&*=;:'``.,<>`"|%()[]{}\/",
        
        [Parameter(Mandatory = $False)]
        [Int]$Samples = 1
    )
    
    Begin{
        $CharacterSet = $null
    
        [char[]]$CharacterSet += 97..122 # Lowercase Letters
        
        [char[]]$CharacterSet += 65..90 # Uppercase Letters
        
        [char[]]$CharacterSet += 48..57 # Numbers
        
        If(-not $ExcludeSpecialCharacters)
        {
            [char[]]$Symbols += (33..47) + (58..64) + (91..96) + (123..126) # Symbols
            [char[]]$CharacterSet += $Symbols
        }
        
        Foreach($Character in $ExcludeCharacters)
        {
            $CharacterSet = $CharacterSet | Where-Object -FilterScript {
                $_ -ne $Character
            }
        }
    }
    
    Process{
        If($PSCmdlet.ShouldProcess('Generate'))
        {
            1..$Samples | ForEach-Object -Process {
                do
                {
                    [char[]]$GeneratedPassword = $CharacterSet | Get-Random -Count $PasswordLength

                    $HasSymbols = $False
                    $HasNumbers = $False
                    $HasUppercase = $False
                    $HasLowercase = $False
				
                    Foreach($Char in $GeneratedPassword)
                    {
                        If($Char -in $Symbols)
                        {
                            $HasSymbols = $True
                        }

                        If($Char -in @([char[]](48..57)))
                        {
                            $HasNumbers = $True
                        }

                        If($Char -in @([char[]](65..90)))
                        {
                            $HasUppercase = $True
                        }

                        If($Char -in @([char[]](97..122)))
                        {
                            $HasLowercase = $True
                        }
                    }
                }
                until(($HasSymbols -or $ExcludeSpecialCharacters) -and $HasNumbers -and $HasUppercase -and $HasLowercase)
        
                $Password = -join $GeneratedPassword
    
                [hashtable]$Properties = @{
                    Password              = $Password
                    PhoneticForm          = $Password |
                    Get-Phonetic |
                    Select-Object -ExpandProperty PhoneticForm
                    SecureStringPlainText = ConvertTo-SecureString -AsPlainText -String $Password -Force | ConvertFrom-SecureString
                    SecureStringObject    = ConvertTo-SecureString -AsPlainText -String $Password -Force
                }
    
                $Object = New-Object -TypeName PSObject -Property $Properties
                $Object.PSObject.Typenames.Insert(0,'ARTools.RandomPassword')
                $Object
            }
        }
    }
    
    End{}
}

Get-Alias -Name New-Password -ErrorAction SilentlyContinue | Remove-Item -Force
New-Alias -Name New-Password -Value New-RandomPassword


