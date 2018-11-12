#
# AIPConnector.ps1
#
# Includes

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\Utility.ps1"

Function ConnectTo-AAD {

	# Connect to AAD using the keys from the DB
	# NOTE: The token used below must have already been generated and stored in the DB. Without specifying the token, the script will prompt for interactive login

	# this happens at the beginning of a run, once
	# If you only have a token, just use: $auth = Set-AIPAuthentication -token $Config.AADToken
	# You could hardcode the values below if you want - or store them in the database and use the $Config object.
	$auth = Set-AIPAuthentication -token $Config.AADToken -WebAppId $Config.AADWebAppId -WebAppKey $Config.AADWebAppKey -NativeAppId $Config.AADNativeAppId 

	Write-Log -severity 4 -message "Connected to AAD successfully"
}

Function Set-Label {
	param(
		[string] $filePath,
		[string] $labelName,
		[string] $labelGuid
	)
	
	$fileStatus = Get-AIPFileStatus -Path $filePath
	If($fileStatus.IsRMSProtected -eq $true){
		$m = "File already encrypted"
		Throw [Exception] $m
	}

	$output = Set-AIPFileLabel -LabelId $labelGuid -Path $filePath -PreserveFileDetails 

	If($output.Status -ne "Success"){
		$m = "File failed to be labelled: " + $output.Comment
		Throw [Exception] $m
	}

	Write-Log -message "Set label [$labelName] on file [$filePath] successfully"

    return $output
}	

Function Check-Encrypted{
	param(
		[string] $filePath
	)

	$fileStatus = Get-AIPFileStatus -Path $filePath
	return $fileStatus.IsRMSProtected
}

Function Check-EncryptedBatch{
	param(
		$filePaths
	)

	$fileStatuses = Get-AIPFileStatus -Path $filePaths
	return $fileStatuses
}

Function Set-LabelBatch {
	param(
		$filePaths,
		[string] $labelName,
		[string] $labelGuid,
		[string] $owner
	)

	$output = Set-AIPFileLabel -LabelId $labelGuid -Path $filePaths -PreserveFileDetails -ErrorAction SilentlyContinue

    return $output
}	

Function Remove-LabelBatch {
	param(
		$filePaths
	)

	$output = Set-AIPFileLabel -Path $filePaths -PreserveFileDetails -RemoveLabel -JustificationMessage "Removed by Bulk Encryption Script Rollback" -ErrorAction SilentlyContinue

    return $output
}	

Function Remove-Label {
	param(
		[string] $filePath
	)

	$output = Set-AIPFileLabel -Path $filePath -RemoveLabel -PreserveFileDetails -JustificationMessage "Removed by Bulk Encryption Script Rollback"
	
	If($output.Status -ne "Success"){
		$m = "File failed to be rolled back: " + $output.Comment
		Throw [Exception] $m
	}
	
	Write-Log -message "Removed label from file [$filePath] successfully"

	return $output

}