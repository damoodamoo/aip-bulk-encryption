#
# MappedPathTests.ps1
#

# Includes
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptLoc = Get-Item -Path $PSScriptRoot
$ScriptLoc = $ScriptLoc.Parent
. "$($ScriptLoc.FullName)\ConfigManager.ps1"
. "$($ScriptLoc.FullName)\Utility.ps1"


# Get local config
$Config = Get-Config

# 1 - long file name
$path = "\\SERVER\test\bulktesttree\bulktesttree-1\bulktesttree-1\bulktesttree-1\bulktesttree-1\bulktesttree-1\bulktesttree-1\bulktesttree-2as dasdasdasdasda sdasd asdasdasd asd asdasdasd asdasd asd asdasda\bulktesttree-2asdasdasdas dasdasdasdasd\bulktesttree-2\bulktesttree-2\Image.JPG"
$path = Get-ShortPath -Path $path
$mappedPath = MapPath -Path $path
Write-Host $mappedPath

Get-AIPFileStatus -Path $mappedPath
UnMapPath -path $mappedPath

	