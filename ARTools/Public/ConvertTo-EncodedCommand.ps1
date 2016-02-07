function ConvertTo-EncodedCommand
{
    [cmdletbinding()]
    
    Param(
        [Parameter(Mandatory = $True,Position=0)]
        [string]$Command
    )
    
    Begin{}
    
    Process{
        $ByteForm = [System.Text.Encoding]::Unicode.GetBytes($Command)
        [Convert]::ToBase64String($ByteForm)
    }
    
    End{}
}


