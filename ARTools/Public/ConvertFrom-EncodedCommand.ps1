function ConvertFrom-EncodedCommand
{
    [cmdletbinding()]
    
    Param(
        [Parameter(Mandatory = $True,Position=0)]
        [string]$EncodedCommand
    )
    
    Begin{}
    
    Process{
        [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedCommand));
    }
    
    End{}
}


