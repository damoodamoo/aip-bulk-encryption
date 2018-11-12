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

# Setting a server to an initial state.
# Old instances will NOT be restarted.
# Previously processes files will NOT be reprocesed.
Write-Log -severity 1 -message "Resetting a ** $($Config.ServerToStopOrReset) ** for a new run. Previously encrypted files will not be re-processed."
Invoke-SQLProc -procName "ResetServer" -parameters @{"serverName" = $Config.ServerToStopOrReset}
Write-Log -severity 1 -message "Server reset."