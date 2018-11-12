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

# USAGE - This script is called from the LocalBulkOrchestrator
# .\MultiThreader.ps1 -threadCount 10

Param(
    [int] $threadCount
)

# .\MultiThreader.ps1 -threadCount 5 5>&1 4>&1 3>&1 2>&1> ./logs/multioutput.txt

$now = [system.datetime]::UtcNow.ToString("yyyy-MM-dd-HH-mm-ss-fff")
$multiThreaderLogFileName = "logs\multi-threader-log-" + $now + ".txt"
Add-Content -Value "Starting run @ $now" -Path $multiThreaderLogFileName

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\ConfigManager.ps1"

$Config = Get-Config

# Output details about current RunspacePools
Write-Output "Runspaces before job start"
$PoshRS_RunspacePools


# Start job
1..$threadCount | start-rsjob -name $_ -Throttle 100 -ArgumentList $Config.ScriptDirectory -ScriptBlock {
    param(
    [string] $scriptDirectory
          )
    cd $scriptDirectory
    $logfilename = "logs\log-" + [system.datetime]::UtcNow.ToString("yyyy-MM-dd-HH-mm-ss-fff") + ".txt"
    .\BulkEncryptionScript.ps1 -verbose 4>&1 3>&1 2>&1 > $logfilename
	Start-Sleep -Seconds 5
    }

#region Error checking

# Check to see if any of the RSJobs have errors
# Not all jobs might have been run at this point if the pool is throttled.
# [array]$runSpaceErrors = Get-RSJob | Where-Object {$_.HasErrors -eq $true}
# Add-Content -Value "$($runSpaceErrors.Count) RSJobs had errors when launched from the Multithreader." -Path $multiThreaderLogFileName

#foreach ($item in $runSpaceErrors)
#{
#    Add-Content -Value "Error detected in RSJob :" -Path $multiThreaderLogFileName
#    Add-Content -Value "Job ID: $($item.ID)" -Path $multiThreaderLogFileName
#    Add-Content -Value "Job Name: $($item.Name)" -Path $multiThreaderLogFileName
#    Add-Content -Value "Job HasMoreData: $($item.HasMoreData)" -Path $multiThreaderLogFileName
#    Add-Content -Value "$($item.Error.Count) errors detected." -Path $multiThreaderLogFileName
#    foreach($runtimeError in $item.Error)
#    {
#        Add-Content -Value $runtimeError.ToString() -Path $multiThreaderLogFileName
#    }    
#}

#endregion

# Output details about current RunspacePools
Write-Output "Runspaces AFTER job start"
$PoshRS_RunspacePools

while($true)
{
    $running = Get-RSJob | Where-Object {$_.State -ne "Completed"}
    if($running -ne $null)
    {
        Start-sleep -Seconds 10
    }else{
        Get-RSJob | Remove-RSJob -Force
        write-host "All threads ended!"
        break;
    }
}

$now = [system.datetime]::UtcNow.ToString("yyyy-MM-dd-HH-mm-ss-fff")
Add-Content -Value "Ending run @ $now" -Path $multiThreaderLogFileName

