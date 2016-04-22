function Search-ADAccountByName
{
    [cmdletbinding()]

    Param(
        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('Givenname','First Name')]
        [string]$FirstName,

        [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
        [Alias('Surname','Last Name')]
        [string]$LastName
    )

    Begin{
        Set-StrictMode -Version Latest
    }

    Process{
        $QueryResults = @()
    
        $PreferredNameSearch = $False
    
        $QueryResults += Get-ADUser -Filter "anr -like `"$LastName`"" -ErrorAction SilentlyContinue

        If(-not $QueryResults)
        {
            $QueryResults += Get-ADUser -Filter "anr -like `"$FirstName`"" -ErrorAction SilentlyContinue
        
            $PreferredNameSearch = $True
        }

        If($QueryResults)
        {
            If($QueryResults.Count -gt 1)
            {
                $RefineResults = @()
            
                If($PreferredNameSearch)
                {
                    $RefineResults += $QueryResults | Where-Object -FilterScript {
                        $LastName -match $_.Surname
                    }
                }
                Else
                {
                    $RefineResults += $QueryResults | Where-Object -FilterScript {
                        $_.GivenName -match $FirstName
                    }
            
                    If(-not $RefineResults)
                    {
                        $RefineResults += $QueryResults | Where-Object -FilterScript {
                            $_.GivenName -like "$($FirstName.Substring(0,1))*"
                        }
                    }
                }
            
                If($RefineResults.Count -gt 1)
                {
                    $User = $RefineResults | Out-GridView -Title "Please select AD account for $FirstName $LastName`:" -PassThru
                }
                ElseIf($RefineResults.Count -eq 1)
                {
                    $User = $RefineResults
                }
                Else
                {
                    $User = $QueryResults | Out-GridView -Title "Please select AD account for $FirstName $LastName`:" -PassThru
                }
            }
            ElseIf($QueryResults.Count -eq 1)
            {
                $User = $QueryResults
            }
            Else
            {
                $User = $null
            }
        
            If(-not $User)
            {
                Write-Warning -Message "No AD account selected for '$FirstName $LastName'."
            }
            Else
            {
                $User
            }
        }
        Else
        {
            Write-Warning -Message "AD account for '$FirstName $LastName' could not be found."
        }
    }

    End{}
}


