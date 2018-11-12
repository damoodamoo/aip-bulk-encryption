#
# MappedPathTests.ps1
#

# Includes
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptLoc = Get-Item -Path $PSScriptRoot
$ScriptLoc = $ScriptLoc.Parent
. "$($ScriptLoc.FullName)\ConfigManager.ps1"
. "$($ScriptLoc.FullName)\Utility.ps1"
. "$($ScriptLoc.FullName)\Delabeller.ps1"

# Get local config
$Config = Get-Config

# 1 - long file name
$excelPath = "C:\temp\bulktestsource\Test File.xls"
$pptPath = "C:\temp\bulktestsource\Test File.ppt"
$docPath = "C:\temp\bulktestsource\Test File.docx"

RemoveMarking -path $excelPath
RemoveMarking -path $pptPath
RemoveMarking -path $docPath
