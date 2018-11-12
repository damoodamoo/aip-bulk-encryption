[CmdletBinding(SupportsShouldProcess=$true)]
Param ()


If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\ConfigManager.ps1"
. "$PSScriptRoot\SQLConnector.ps1"
. "$PSScriptRoot\AIPConnector.ps1"
. "$PSScriptRoot\Utility.ps1"


Try
{
	(New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

	# Get local and global config, and open a SQL connection
	$Config = Get-Config 
	Write-Log -severity 1 -message ("Starting AAD Connector")

	# Open the SQL Connection
	$Conn = Open-SQLConnection

	# Extend the config to get SQL settings
	Extend-Config	

	# Update the registry to set ONLINE Mode
	$registryPath = "HKCU:\Software\Microsoft\MSIP"
	$name = "EnablePolicyDownload"
	$value = "1"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
	Write-Log -message "Updated registry to set Online Mode" -severity 1

	# Connect to AAD
	ConnectTo-AAD

	# Update the registry to set OFFLINE Mode
	$value = "0"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
	Write-Log -message "Updated registry to set Offline Mode" -severity 1

}
Catch [System.Exception]
{
    $exp = $_.Exception.Message
    Write-Log -severity 2 -message "AAD Connector Script Exception: $exp"
}
Finally
{		
	If ($Conn -ne $null){ 
		Close-SQLConnection
	}

	Write-Log -severity 1 -message ("AAD Connector Script run ended")
}