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

# GetList of Active Servers
$activeServers = Invoke-SQLProc -procName "GetActiveServers"	

foreach ($server in $activeServers.ServerName)
{
    # Stop the server so no more instances can start.
    Write-Log -severity 1 -message "Marking ** $server ** as Inactive. All running Instances should automatically be closed down by the script."
    Invoke-SQLProc -procName "StopServer" -parameters @{"serverName" = $server }
    Write-Log -severity 1 -message "Server row updated."
}

