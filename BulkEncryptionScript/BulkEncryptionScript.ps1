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

# USAGE - this script is usually called by the MultiThreader.ps1 script, but can be run independantly

# These are the levels of tracing you can enable and the commands to ensure the output from all streams goes to a single file.
# .\BulkEncryptionScript.ps1 5>&1 4>&1 3>&1 2>&1> ".\output.txt"
# .\BulkEncryptionScript.ps1 -verbose 5>&1 4>&1 3>&1 2>&1> ".\output.txt"
# .\BulkEncryptionScript.ps1 -debug 5>&1 4>&1 3>&1 2>&1> ".\output.txt"

[CmdletBinding(SupportsShouldProcess=$true)]
Param ()



If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

#cls

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\ConfigManager.ps1"
. "$PSScriptRoot\SQLConnector.ps1"
. "$PSScriptRoot\AIPConnector.ps1"
. "$PSScriptRoot\Utility.ps1"
. "$PSScriptRoot\Delabeller.ps1"

# Setup
$NumProcessed = 0
$NumErrors = 0
$ScriptException = $null
$happyStatus = $null
$unhappyStatus = $null
$mappedDrives = @()
$mutex = $null

Try
{
	# Get local and global config, and open a SQL connection
	$Config = Get-Config 
	Write-Log -severity 1 -message ("Starting Bulk Encryption on Server " + $Config.ServerName)

	# Open the SQL Connection
	$Conn = Open-SQLConnection

	# Extend the config to get SQL settings
	Extend-Config	

	# Log that i've started in the Instances table - InstanceId is added to $Config
	Set-ScriptStart
	Write-Log -severity 4 -message "Set Script Instance start in SQL."
	
	$ShouldRun = $true
	$DocsComplete = $null	
	$endTime = [System.DateTime]::Parse($Config.EndTime)    

    Write-Log -severity 1 -message ("Starting to process in mode: " + $Config.EncryptionMode)	

	While ($ShouldRun -eq $true){
		
		$toProcess = @()
		$toCheckPaths = @()
		$toProcessPaths =@()
		$mappedDrives = @()
		$setLabelResult = $null

		# Check stop time
		$timeNow = [System.DateTime]::UtcNow
		If ($timeNow -gt $endTime -and $Config.ContinuousMode -ne "true"){
			$shouldRun = $false
            Write-Log -severity 1 -message "Stopping script due to end time: $endTime"
			break;
		}	
		
		Try
		{
			# Get next batch to process, and 'lock' rows
			$Files = [array](Get-FileBatch -mode $Config.EncryptionMode)

			# Check that a new row has been returned from the DB. A null means there are no more rows to process.
			If(((IsNull($Files)) -eq $true) -or ($Files.Count -eq 0)){
				$ShouldRun = $false
				$DocsComplete = $true
				Write-Log -severity 1 -message "No more files for this server to process"
				break;
			}

			# Are we still allowed to process, or am I being killed?
			If(($Files[0].IsActive -ne $true) -or ($Files[0].InstanceActive -ne $true)){
				$ShouldRun = $false
				Write-Log -severity 1 -message "Shutting down due to server / instance marked as Inactive"

				$s = 1
				If($Config.EncryptionMode -eq "decrypt"){  $s = 3}

				# Update all files and hand them back to SQL
				Foreach ($f in $Files){
					$f.Status = $s					 
				}			
				Update-FileRows -batch $Files

				break;
			}

			# Loop the batch
			Foreach($File in $Files){
				Try{
					$path = $null
					$fileName = $null

					# Set the attempt count if needed
					If(IsNull($File.AttemptCount)){
						 $File.AttemptCount = 0
					}
					$File.AttemptCount++

					# Is the 'new' filename different to the original? if yes, construct the 'real' path:
					If(IsNull($File.NewFileName)){
						$File.NewFileName = ""
					}Else{
						$fileName = [System.IO.Path]::GetFileName($File.FilePath)
						If($fileName -ne $File.NewFileName){
							$File.FilePath = $File.FilePath.Replace($fileName, $File.NewFileName)
						}	
					}

					# This is the item about to be processed.
					Write-Log -severity 1 -message ("Processing: " + $File.FilePath + ", Id: " + $File.Id.ToString())

					# Are we > 260 characters? If so, shorten the path then try and map a network drive
					If($File.FilePath.Length -gt 247){
						Write-Log -severity 4 -message "...long file path found"
						$path = $File.FilePath
				
						# try 8.3
						Try{
							$path = Get-ShortPath -path $path							
						} Catch [System.Exception] {
							# 8.3 has failed - use the long path and see what we can do...
							If($path.Length -gt 494){
								$m = "Path too long, no short path available"
								Write-Log -severity 3 -message $m
								$File.Status = 6
								$File.Exception = $m
								$NumErrors++
								Continue;
							}
						}	

						$m = "...mapping drive letter for doc " + $path
						Write-Log -severity 4 -message $m

						Try
						{
							$File.FilePath = MapPath -Path $path
							$mappedDrives += $File.FilePath[0]
						} Catch [System.Exception] {
							$m = "Error mapping path: " + $_.Exception.Message
							Write-Log -severity 3 -message $m
							$File.Status = 6
							$File.Exception = $m
							$NumErrors++
							Continue
						}
					}

					Write-Log -severity 4 -message "...checking path"

					# Check to make sure the item exists on server
					$pathCheck = Test-Path -literalpath $File.FilePath
					if(-not $pathCheck)
					{
						$m = "...path not found on server"
						Write-Log -severity 3 -message $m
						$File.Exception = $m
						$File.Status = 7 
						$NumErrors++
						Continue;
					}

					Write-Log -severity 4 -message "...got path - checking if is a folder..."

					# Check for item across network
					$item = Get-Item -literalpath $File.FilePath

					# Check to see if item is a folder - we don't encrypt those
					if($item.PSIsContainer)
					{
						$m = "...item is a folder"
						Write-Log -severity 3 -message $m
						$File.Exception = $m
						$File.Status = 6  
						$NumErrors++
						Continue;
					}

					# Check to see if the document is under the minimum age of documents
					If(((IsNull($Config.MinDocAgeDays)) -ne $true) -and ($Config.MinDocAgeDays -ne '0')){
						$days = [Int]::Parse($Config.MinDocAgeDays)
						$minAgeDate = $item.LastWriteTime.AddDays($days)
						$minAgeCompare = [System.DateTime]::Compare($minAgeDate, [System.DateTime]::Now)
						If($minAgeCompare -gt 0){
							Write-Log -message "...document is too recent to process" -severity 4
							$File.Status = 8
							$File.Exception = "Document too recent to process"
							$File.LastModifiedWhen = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
							Continue;
						}							
					}			

					# Are we removing labels, and does it have a label from another product already?
					If($Config.RemovePreviousLabels -eq "true"){
						Write-Log -message "...checking file for previous labels metadata" -severity 4
						$prev = RemovePreviousLabel -path $File.FilePath
					}

					# -------------------------------------------------------------
					# File passes checks and is ready for processing.        
					# -------------------------------------------------------------    	

					# Record original size as adding AIP changes this
					Write-Log -severity 4 -message "...not a folder - recording the file size and checking modified date..."
					$File.OriginalFileSize = $item.Length					

					$toCheckPaths += $File.FilePath

				} Catch [System.Exception]{
					# Catch file-level error. Update statuses and continue batch.
					$File.Status = 4
					$File.Exception = $_.Exception.Message
				}
			}					

			If (($toCheckPaths -ne $null) -and ($toCheckPaths.Count -gt 0))
			{
				Try
				{
					# Create a mutex to queue up encryption commands rather than run them in parallel
					$createdHere = $false
					$mutex = New-Object -TypeName System.Threading.Mutex($true, "BE-MUTEX", [ref]$createdHere)
					If($createdHere -eq $false){
						Write-Log -message "Waiting for mutex..." -severity 1
						$mutex.WaitOne() | Out-Null
					}		

					# Batch-check for already encrypted
					If($Config.EncryptionMode -eq "encrypt"){
						Write-Log -message "Batch checking for already encrypted..." -severity 1
						$fileStatuses = Check-EncryptedBatch -filePaths $toCheckPaths
						Write-Log -message "Updating batch to remove already encrypted..." -severity 1
						foreach($file in $Files){
							$match = $false
							foreach($status in $fileStatuses){							
								If($file.FilePath -eq $status.FileName){
									if($status.IsRMSProtected -eq $true){
										$file.Status = 7
										$file.Exception = "Already encrypted"

										$m = "...file " + $file.FilePath + " already encrypted"
										Write-Log -severity 3 -message $m
										$NumErrors++
									}else{
										$toProcess += $file
										$toProcessPaths += $file.FilePath
									}	
									$match = $true
									break;
								}
							}
							if($match -eq $false){
								$file.Status = 9 #Pre-Encryption Error
								$file.Exception = "Pre-Encryption Error - possibly corrupt file"
							}
						}
					}
					
					# Do the labelling
					If($Config.EncryptionMode -eq "encrypt")
					{						
						If(((IsNull($toProcess)) -eq $false) -and ($toProcess.Count -ne $null) -and ($toProcess.Count -gt 0)){
							# Try to process with AIP
							#TODO - separate out label types into separate operations to support different labels per file
							$m = "About to set label batch for [" + $toProcess[0].LabelName + "], " + $toProcess.Count + " files"
							Write-Log -message $m -severity 1
							$setLabelResult = Set-LabelBatch -filePaths $toProcessPaths -labelName $toProcess[0].LabelName -labelGuid $toProcess[0].LabelGuid
							$happyStatus = 3
							$unhappyStatus = 4
							$m = "Set label batch for [" + $toProcess[0].LabelName + "] successfully"
							Write-Log -message $m -severity 1
						}						
					}ElseIf($Config.EncryptionMode -eq "decrypt"){
						Write-Log -message "About to remove label batch..." -severity 1
						$setLabelResult = Remove-LabelBatch -filePaths $toCheckPaths				
						Write-Log -message "Removed label batch successfully" -severity 1
						$happyStatus = 1
						$unhappyStatus = 5
					}	
				}Catch [System.Exception] {
					Throw $_
				}Finally{
					$mutex.ReleaseMutex()
					$mutex.Dispose()
					Write-Log -message "Released mutex" -severity 1
				}		
		
				# Loop results - update the files batch 		
				Write-Log -message "...updating statuses" -severity 4
				For($i = 0; $i -lt $setLabelResult.Count; $i++){
					$m = "......" + $setLabelResult[$i].FileName + " = " + $setLabelResult[$i].Status
					Write-Log -message $m -severity 4

					$fileToUpdate = TryToMatchFile -files $Files -fileName $setLabelResult[$i].FileName
					if($fileToUpdate -eq $null){
						$translatedFileName = TranslateFileName -newFileName $setLabelResult[$i].FileName -direction $Config.EncryptionMode
						$fileToUpdate = TryToMatchFile -files $Files -fileName $translatedFileName
					}

					if($fileToUpdate -ne $null){						
						If($setLabelResult[$i].Status -ne "Success"){
							$fileToUpdate.Status = $unhappyStatus
							$fileToUpdate.Exception = $setLabelResult[$i].Comment
							
							$NumErrors++;
							$m = "......error encrypting file " + $fileToUpdate.FilePath + ". Exception: " + $setLabelResult[$i].Comment
							Write-Log -message $m -severity 3

						}Else{
							$fileToUpdate.Status = $happyStatus
							$fileToUpdate.NewFileName = [System.IO.Path]::GetFileName($setLabelResult[$i].FileName)						

							Try{
								$updatedItem = Get-Item -literalpath $setLabelResult[$i].FileName
								$fileToUpdate.NewFileSize = $updatedItem.Length;
								$fileToUpdate.LastModifiedWhen = $updatedItem.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
								Try{ $fileToUpdate.Owner = $updatedItem.GetAccessControl().Owner } Catch [System.Exception] {}
							}Catch [System.Exception] {
								# do nothing, likely intermittent network issue
							}

							$NumProcessed++
						}	
					}					
				}
			} else{
				Write-Log -message "Batch contained no items to process" -severity 1
			}	

			# Update SQL
			Write-Log -message "Updating SQL with entire batch..." -severity 1
			Update-FileRows -batch $Files
			Write-Log -message "...completed SQL update" -severity 4
						
		}
		Catch [System.Exception]
		{			
			$m = "Exception: " + $_.Exception.Message
			Write-Log -message $m -severity 2
		}
		Finally
		{	
			Foreach($drive in $mappedDrives){
				UnMapPath -Path $drive
			}
		}
	}	
}
Catch [System.Exception]
{
    $ScriptException = $_.Exception.Message
    Write-Log -severity 2 -message "Script Exception: $ScriptException"
}
Finally
{	
	# Log the end of the script
	Set-ScriptEnd -instanceId $Config.InstanceId -numErrors $NumErrors -numProcessed $NumProcessed -exception $ScriptException
    Write-Log -severity 4 -message ("Set script instance end in SQL. Item Successes: " + $NumProcessed.ToString() + ", Item Failues: " + $NumErrors.ToString())
    
    Write-Log -severity 1 -message ""
    Write-Log -severity 1 -message ("Labels successfully applied: " + $NumProcessed.ToString())
    Write-Log -severity 1 -message ("Errors encountered: " + $NumErrors.ToString())
    Write-Log -severity 1 -message ""

	Foreach($drive in $mappedDrives){
		UnMapPath -Path $drive
	}

	# Update the Servers table that this server is done
	If($DocsComplete -eq $true){
		Log-ServerComplete -serverName $Config.ServerName
        Write-Log -severity 4 -message ("Updated SQL to set server " + $Config.ServerName + " as complete")
	}

	If ($Conn -ne $null){ 
		Close-SQLConnection
	}

	# Close office apps if they're open
	If($script:wordApp -ne $null){
		$script:wordApp.Quit()
	}
	If($script:excelApp -ne $null){
		$script:excelApp.Quit()
	}
	If($script:pptApp -ne $null){
		$script:pptApp.Quit()
	}

	Write-Log -severity 1 -message ("Script run ended")
}