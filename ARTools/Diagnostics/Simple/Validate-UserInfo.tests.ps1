[cmdletbinding()]

Param(
    [Parameter(Mandatory = $True)]
    [string]$OU,
        
    [Parameter(Mandatory = $False)]
    [string[]]$OfficesList,
    
    [Parameter(Mandatory = $False)]
    [string[]]$TitlesList,
    
    [Parameter(Mandatory = $False)]
    [string[]]$DepartmentsList
)

'TitlesList','DepartmentsList','OfficesList' | 
ForEach-Object -Process{
    If(-not $PSBoundParameters.ContainsKey($_))
    {
        Set-Variable -Name $_ -Value (Get-Content -Path $PSScriptRoot\Validate-UserInfo-$_.txt)
    }

    If($null -eq (Get-Variable -Name $_ -ValueOnly))
    {
        Write-Warning -Message "$_ is empty."
    }
}

$Users = Get-ADUser -Filter * -SearchBase $OU -Properties Office, Title, Department

Write-Verbose -Message "Found $($Users.Count) user accounts." -Verbose:$True

Describe "User Info" {
    Foreach($User in $Users){
        If($null -ne $TitlesList){
            It "$($User.Name) has a valid title." {
                $User.Title -in $TitlesList | Should Be $True
            }
        }
        
        If($null -ne $DepartmentsList){
            It "$($User.Name) has a valid department." {
                $User.Department -in $DepartmentsList | Should Be $True
            }
        }
        
        If($null -ne $OfficesList){
            It "$($User.Name) has a valid office." {
                $User.Office -in $OfficesList | Should Be $True
            }
        }
    }
}

