#######################################################
#													  #
# AZURE INFORMATION PROTECTION BULK ENCRYPTION SCRIPT #
# Author: David Moore | damoo@microsoft.com           #
#													  #
# NOTE: This script comes with NO warranty or support #
# It is your responsibility to check and run the	  #
# script in Dev / Test environments first.			  #
#													  #
# YOU RUN THIS SCRIPT AT YOUR OWN RISK.				  #
#													  #
#######################################################

# USAGE
# .\LocalBulkOrchestrator.ps1

# Includes
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\ConfigManager.ps1"
. "$PSScriptRoot\SQLConnector.ps1"
. "$PSScriptRoot\Utility.ps1"
. "$PSScriptRoot\AIPConnector.ps1"

Try
{
	# Get local and global config, and open a SQL connection
	$Config = Get-Config
	$serMes = "Starting Local Encryption Orchestrator on " + $Config.ServerName
	Write-Log -message $serMes -severity 1

	# Open the SQL Connection
	$Conn = Open-SQLConnection	

	# Get all the servers that aren't complete + where the time is ok
	Get-ServerConfig

	# Check Server Time + If Continuous... 
	$timeNow = [System.DateTime]::UtcNow
	$endTime = [System.DateTime]::Parse($Config.EndTime) 
	If ($timeNow -gt $endTime -and $Config.ContinuousMode -ne "true"){
        Write-Log -severity 1 -message "Ignoring run due to end time: $endTime"
		break;
	}	

	# Check if Server is Active
	If(($Config.ServerActive -ne $true) -or ($Config.ServerComplete -eq $true)){
		Write-Log -severity 1 -message "Server is InActive or Complete - ending..."
		break;
	}

	# Check the instances in SQL
	$instances = Get-ActiveInstances -serverId $Config.ServerId
	$runningInstances = 0
	foreach($ins in $instances){
		$runningInstances++
	}

	$instancesToStart = $Config.NumberInstances - $runningInstances	
	$instancesToEnd = $runningInstances - $Config.NumberInstances

	$m = "...Server " + $Config.ServerName + ": Has " + $runningInstances + " instances running. Should have: " + $Config.NumberInstances
	Write-Log -message $m -severity 1

	If(($instancesToStart -eq 0) -and ($runningInstances -eq 0) -and ($instancesToEnd -eq 0)){
		continue;
	}

	# ----------------- BOOTSTRAP THE SERVER ------------------------- #
	If($runningInstances -eq 0){			
		Write-Log -message "......Bootstrapping the server..." -severity 1

		# Command
		$aadLogFileName = "logs\" + "AADConnector-" + [System.DateTime]::UtcNow.ToString("yyyy-MM-dd-HH-mm-ss-fff") + ".txt"
		$aadConnect =  [scriptblock]::Create("cd " + $Config.ScriptDirectory + "; .\AADConnector.ps1 -verbose 4>&1 3>&1 2>&1 > " + $aadLogFileName)
		
		Invoke-Command -scriptBlock $aadConnect 
		
		Write-Log -message "......Server bootstrapped." -severity 1
	}
		

	# ----------------- SCALE UP ------------------- #
	If($instancesToStart -gt 0){
		$m = "......Scaling Up: Starting " + $instancesToStart + " instances on " + $Config.ServerName + "..."
		Write-Log -message $m -severity 1

		$logFileName = "logs\" + $Config.LocalLogFileName + "-" + [System.DateTime]::UtcNow.ToString("yyyy-MM-dd-HH-mm-ss-fff") + ".txt"
		$p =  [scriptblock]::Create("cd " + $Config.ScriptDirectory + "; .\MultiThreader.ps1 -threadCount " + $instancesToStart)		
		Invoke-Command -scriptBlock $p
	}
		
	# ----------------- SCALE DOWN ----------------- #
	If($instancesToEnd -gt 0){
		$m = "......Scaling Down: Shutting down " + $instancesToEnd + " instances on " + $Config.ServerName + "..."
		Write-Log -message $m -severity 1
			
		If($runningInstances -eq 1){
			$instanceToEnd = $instances.ItemArray[0]
			End-Instance -instanceId $instanceToEnd
		}else{
			for($i = 0; $i -lt $instancesToEnd; $i++){	
				$instanceToEnd = $instances[$i].ItemArray[0]
				End-Instance -instanceId $instanceToEnd
			}
		}		
	}
}
Catch [System.Exception]
{
	# Set exception
	$ScriptException = $_.Exception.Message
	Write-Log -message "Orchestrator Exception: $ScriptException" -severity 2
}
Finally
{	
	If ($Conn -ne $null){ 
		Close-SQLConnection
	}

	$doneMes = "Orchestrator run ended"
	Write-Log -message $doneMes -severity 1
}
