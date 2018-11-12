Set-ExecutionPolicy -ExecutionPolicy Unrestricted

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\Get-FolderItem.ps1"

$width = 2
$depth = 1

$currentDirectory = Get-Location

$testdatapath = "C:\test"
#remove-item $testdatapath -Force -Recurse -EA 0
remove-item "c:\temp\sqlinsert.sql" -Force -Recurse -EA 0

mkdir $testdatapath

### Create new folder to hold lots of files.
New-Item -ItemType Directory -path "$testdatapath\bulktestsource"
New-Item -ItemType Directory -path "$testdatapath\bulktesttree"
Copy-Item -Recurse -Path "C:\temp\bulktestsource" -Destination "$testdatapath\" -Container 


Function RecurseFolders(){
	param(
		[string] $parentFolder,
		[int] $width,
		[int] $depth,
		[int] $currentDepth,
		[bool] $isMapped
	)
	
	1..$width | ForEach-Object {
		$newName = $parentFolder + "bulktesttree" + "-" + $_.ToString()
		Copy-Item -Recurse -Path "$testdatapath\bulktestsource\" -Destination $newName -Verbose
	}

	$children = Get-ChildItem -Path $parentFolder | ?{ $_.PSIsContainer }

	if($currentDepth -lt $depth){
		foreach($child in $children){
			$newCurrent = $currentDepth + 1
			$fol = $child.FullName + "\"		
			RecurseFolders -parentFolder $fol -width $width -depth $depth -currentDepth $newCurrent -isMapped $isMapped
		}
	}
}


RecurseFolders -parentFolder "$testdatapath\bulktesttree\" -width $width -depth $depth

Read-Host "Make any manual changes you want then carry on..."

## Create the SQL insert script
Write-Host "Generating SQL Insert script...."
Get-FolderItem  "$testdatapath\bulktesttree" | ForEach-Object {"INSERT INTO [Files]([Status],[FileServerId],[LabelId],[FilePath]) VALUES (1,1,4,'$($_.FullName)')" | Out-File -Append -FilePath "c:\temp\sqlinsert.sql"}

Set-Location -Path $currentDirectory