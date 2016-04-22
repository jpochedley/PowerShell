#requires -Version 2
function New-VisualNotification
{
    [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'Low')]
    
    Param(
        [Parameter(Mandatory = $False,ValueFromPipeline)]
        [string]$Message = 'Attention. Task Completed.',

		[Parameter(Mandatory = $False,ValueFromPipeline)]
        [string]$Title = $null,

		[Parameter(Mandatory = $False,ValueFromPipeline)]
        [System.Windows.MessageBoxButton]$Button = 'OK',

		[Parameter(Mandatory = $False,ValueFromPipeline)]
        [System.Windows.MessageBoxImage]$Icon = 'Information'
	)
    
    Begin{
		Add-Type -AssemblyName PresentationFramework
	}
    
    Process{
        If($PSCmdlet.ShouldProcess("Message: $Message"))
        {
			$null = [System.Windows.MessageBox]::Show($Message,$Title,$Button,$Icon)
        }
    }
    
    End{}
}


