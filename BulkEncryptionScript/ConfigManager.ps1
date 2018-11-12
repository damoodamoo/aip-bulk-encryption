#
# ConfigManager.ps1
#

# Includes
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\SQLConnector.ps1"
. "$PSScriptRoot\Utility.ps1"

Function Get-Config
{
	$fileName = "config.json"

	# Read the config file into an object we can use
	$Config = Get-Content "$PSScriptRoot\$fileName" | ConvertFrom-Json

	# Generate + add the Log file path
	$dtNow = [System.DateTime]::UtcNow.ToString("yyyy-MM-dd-HH-mm")
	$logFileFullName = $Config.LogFileName + "-" + $dtNow + ".csv"
	$Config | Add-Member -MemberType NoteProperty –Name LogFileFullName –Value $logFileFullName

	# Add the server name
	$hostname = hostname
	$Config | Add-Member -MemberType NoteProperty –Name ServerName –Value $hostname

    Write-Log -severity 4 -message "Read local config successfully"

	return $Config
}

Function Extend-Config
{
	# Get the rest of the config from the SQL table
	$sqlConfig = Get-GlobalConfig
	$sqlConfig | ForEach-Object{
		$propName = $_.ItemArray[1]
		$propVal = $_.ItemArray[2]
		$Config | Add-Member -MemberType NoteProperty –Name $propName –Value $propVal
	}

	# Get the server config - for when this script should stop
	Get-ServerConfig

	# Decrypt the AAD token strings as needed
	If(-not [String]::IsNullOrEmpty($Config.AADToken)){
		$key = Get-Content $Config.TokenDecryptKeyFile
		$ssToken = ConvertTo-SecureString $Config.AADToken -Key $key
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ssToken)
		$openToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		$Config.AADToken = $openToken
	}

	If(-not [String]::IsNullOrEmpty($Config.AADWebAppKey)){
		$key = Get-Content $Config.TokenDecryptKeyFile
		$ssAppKey = ConvertTo-SecureString $Config.AADWebAppKey -Key $key
		$BSTRAppKey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ssAppKey)
		$openAppKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTRAppKey)
		$Config.AADWebAppKey = $openAppKey
	}

	If(-not [String]::IsNullOrEmpty($Config.AADToken)){
		[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)		
	}

	If(-not [String]::IsNullOrEmpty($Config.AADWebAppKey)){
		[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTRAppKey)
	}

	Write-Log -severity 4 -message "Read SQL Config successfully"
}