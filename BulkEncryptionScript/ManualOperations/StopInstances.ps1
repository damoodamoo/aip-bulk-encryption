If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptLoc = Get-Item -Path $PSScriptRoot
$ScriptLoc = $ScriptLoc.Parent
. "$($ScriptLoc.FullName)\ConfigManager.ps1"
. "$($ScriptLoc.FullName)\Utility.ps1"
. "$($ScriptLoc.FullName)\SQLConnector.ps1"
. "$($ScriptLoc.FullName)\AIPConnector.ps1"

# Get local and global config, and open a SQL connection
$Config = Get-Config 
# Open the SQL Connection
$Conn = Open-SQLConnection

# Stop any running instances.
Write-Log -severity 1 -message "Stopping all running Instances on ** $($Config.ServerToStopOrReset) ** which will be marked Inactive with an EndTime applied."
Invoke-SQLProc -procName "StopInstances" -parameters @{"serverName" = $Config.ServerToStopOrReset}
Write-Log -severity 1 -message "You may have to wait for the existing file batch in any running instances to complete."

