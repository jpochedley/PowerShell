function Remove-Signature{
	[cmdletbinding()]

	Param(
		[Parameter(Mandatory = $False,Position = 0,ValueFromPipeline= $True,ValueFromPipelineByPropertyName = $True)]
		[Alias('Path')]
		[system.io.fileinfo[]]$FilePath
	)

	Begin{
		Push-Location $env:USERPROFILE
	}

	Process{
		$FilePath |
		ForEach-Object -Process {
			$Item = $_
			
			If($Item.Extension -match '\.ps1|\.psm1|\.psd1|\.ps1xml'){
				$Content = Get-Content -Path $Item.FullName
    
				$StringBuilder = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
    
				Foreach($Line in $Content)
				{

