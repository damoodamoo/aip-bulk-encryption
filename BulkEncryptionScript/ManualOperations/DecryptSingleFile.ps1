If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptLoc = Get-Item -Path $PSScriptRoot
$ScriptLoc = $ScriptLoc.Parent
. "$($ScriptLoc.FullName)\ConfigManager.ps1"
. "$($ScriptLoc.FullName)\Utility.ps1"
. "$($ScriptLoc.FullName)\AIPConnector.ps1"

# Get local config
$Config = Get-Config 

$output = Set-AIPFileLabel -Path $Config.SingleFilePath -RemoveLabel -PreserveFileDetails -JustificationMessage "Decrypted by Bulk Encryption Administrators"
	
If($output.Status -ne "Success"){
	$m = "File failed to be rolled back: " + $output.Comment
	Write-Log -message $m -severity 1
}
	
Write-Log -message "Removed label from file [$($Config.SingleFilePath)] successfully" -severity 1
