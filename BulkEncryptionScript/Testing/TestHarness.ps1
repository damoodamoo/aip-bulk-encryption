#
# TestHarness.ps1
#

# Includes
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptLoc = Get-Item -Path $PSScriptRoot
$ScriptLoc = $ScriptLoc.Parent
. "$($ScriptLoc.FullName)\ConfigManager.ps1"
. "$($ScriptLoc.FullName)\Utility.ps1"
. "$($ScriptLoc.FullName)\AIPConnector.ps1"

Try
{
	# Get local and global config, and open a SQL connection
	$Config = Get-Config
	$serMes = ("Starting Test on " + $Config.ServerName)
	Write-Log -message $serMes

	$files = @("X:\docs\ValidDoc1.docx",
				"X:\docs\ValidDoc2.docx",
				"X:\docs\ValidDoc3.docx",
				"X:\docs\ValidDoc4.docx",
				"X:\docs\ValidDoc5.docx",
				"X:\docs\ValidSpread1.xlsx",
				"X:\docs\ValidSpread2.xlsx",
				"X:\docs\ValidSpread3.xlsx",
				"X:\docs\ValidSpread4.xlsx",
				"X:\docs\ValidSpread5.xlsx",
				"X:\docs\OldDoc.doc",
				"X:\docs\OldSpread.xls",
				"X:\docs\CorruptedDoc.docx",
				"X:\docs\CorruptedOldDoc.doc",
				"X:\docs\CorruptedSpread.xlsx",
				"X:\docs\CorruptedOldSpread.xls",
				"X:\docs\MissingDoc.docx",
				"X:\docs\MisingSpread.docx",
				"X:\docs\AccessDeniedDoc.docx",
				"X:\docs\AccessDeniedSpread.xlsx",
				"X:\docs\TextFile.txt",
				"X:\docs\Image.jpg")

	foreach($file in $files){
		Set-Label -filePath $file -labelName "Secret" -labelGuid $Config.ManualLabelGuid
	}

}
Catch [System.Exception]
{
	# Set exception
	$ScriptException = $_.Exception.Message
	Write-Log -message "Test Exception: $ScriptException" -severity 3
}
Finally
{	
	$doneMes = ("Test run ended. Log file generated at " + $Config.LogFileFullName)
	Write-Log -message $doneMes

}
