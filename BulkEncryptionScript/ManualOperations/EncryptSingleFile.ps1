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

Set-AIPFileLabel -Path $Config.SingleFilePath -LabelId $Config.ManualLabelGuid -JustificationMessage "Manual operation by Bulk Encryption Administrators" -PreserveFileDetails
