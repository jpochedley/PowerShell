#requires -Version 2
function Save-Credential
{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        [string]$Username = $env:USERNAME,
        
        [Parameter(Mandatory = $False)]
        [SecureString]$SecurePassword,
        
        [Parameter(Mandatory = $False)]
        [string]$Domain = $env:USERDNSDOMAIN,
    
        [Parameter(Mandatory = $False)]
        [ValidateScript({
                    $IsContainer = Get-Item -Path $_ -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSIsContainer
                    If($IsContainer)
                    {
                        $True
                    }
                    Else
                    {
                        Throw 'Please specify folder location.'
                    }
                }
        )]
        [string]$Path = $null
    )

    Begin{}

    Process{
        If(-not $PSBoundParameters.ContainsKey('SecurePassword'))
        {
            $SecurePassword = Read-Host -AsSecureString -Prompt "Please enter password for $Domain\$Username`:"
        }
        
        $TransformedPassword = $SecurePassword | ConvertFrom-SecureString -ErrorAction Stop

        If(-not $PSBoundParameters.ContainsKey('Path'))
        {
            If(-not (Test-Path -Path "$env:APPDATA\SavedCreds"))
            {
                $Path = New-Item -ItemType Container -Path "$env:APPDATA\SavedCreds" | Select-Object -ExpandProperty FullName
            }
            Else
            {
                $Path = "$env:APPDATA\SavedCreds"
            }
        }
        
        $FilePath = "$Path\CredStore.xml"
        
        If(-not (Test-Path -Path $FilePath))
        {
            $XmlWriter = New-Object -TypeName System.XMl.XmlTextWriter -ArgumentList ($FilePath, $null)
            $XmlWriter.Formatting = 'Indented'
            $XmlWriter.Indentation = 1
            $XmlWriter.IndentChar = "`t"
            $XmlWriter.WriteStartDocument()
            $XmlWriter.WriteProcessingInstruction('xml-stylesheet', "type='text/xsl' href='style.xsl'")
            $XmlWriter.WriteStartElement('Accounts')
            $XmlWriter.WriteStartElement('Account')
            $XmlWriter.WriteElementString('Domain', "$Domain")
            $XmlWriter.WriteElementString('Username', "$Username")
            $XmlWriter.WriteStartElement('Password')
            $XmlWriter.WriteRaw("$TransformedPassword")
            $XmlWriter.WriteEndElement()
            $XmlWriter.WriteEndElement()
            $XmlWriter.WriteEndDocument()
            $XmlWriter.Flush()
            $XmlWriter.Close()
        }
        Else
        {
            [xml]$XML = Get-Content -Path $FilePath
            $Query = Select-Xml -Xml $XML -XPath "//Account[Username='$Username' and Domain='$Domain']"
            If($null -eq $Query)
            {
                $Item = Select-Xml -Xml $XML -XPath '//Account[1]'
                $NewNode = $Item.Node.CloneNode($True)
                $NewNode.Username = "$Username"
                $NewNode.Domain = "$Domain"
                $NewNode.Password = "$TransformedPassword"
                $Accounts = Select-Xml -Xml $XML -XPath '//Accounts'
                $null = $Accounts.Node.AppendChild($NewNode)
                $XML.Save("$FilePath")
            }
            Else
            {
                $Query.Node.Password = "$TransformedPassword"
                $XML.Save($FilePath)
            }
        }
    }

    End{}
}


