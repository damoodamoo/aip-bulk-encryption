#
# Utility.ps1
#

$extensionTranslate = @(
	@{pre = ".txt"; post = ".ptxt"},
	@{pre = ".xml"; post = ".pxml"},
	@{pre = ".jpg"; post = ".pjpg"},
	@{pre = ".jpeg"; post = ".pjpeg"},
	@{pre = ".pdf"; post = ".ppdf"},
	@{pre = ".png"; post = ".ppng"},
	@{pre = ".tif"; post = ".ptif"},
	@{pre = ".tiff"; post = ".ptiff"},
	@{pre = ".bmp"; post = ".pbmp"},
	@{pre = ".gif"; post = ".pgif"},
	@{pre = ".jpe"; post = ".pjpe"},
	@{pre = ".jfif"; post = ".pjfif"},
	@{pre = ".jt"; post = ".pjt"}
)

Function TranslateFileName(){
	param(
		[string] $newFileName,
		[string] $direction
	)

	$outName = ""
	$ext = [System.IO.Path]::GetExtension($newFileName)
	
	foreach($item in $extensionTranslate){
		if($direction -eq "encrypt"){
			if($item.post -eq $ext){
				$outName = [System.IO.Path]::ChangeExtension($newFileName, $item.pre)
				return $outName;
			}
		}else{
			if($item.pre -eq $ext){
				$outName = [System.IO.Path]::ChangeExtension($newFileName, $item.post)
				return $outName;
			}
		}
	}

	# deal with random files
	if(($direction -eq "decrypt")){
		$outName = $newFileName + ".pfile"
		return $outName
	}else{
		if($ext -eq ".pfile"){
			$outName = $newFileName.Replace(".pfile","")
			return $outName
		}	
	}
}

Function TryToMatchFile(){
	param(
		$files,
		$fileName
	)

	foreach($file in $files){
		if($file.FilePath -eq $fileName){
			return $file;
			break;
		}
	}

	return $null;
}

Function IsNull($objectToCheck) {
    if ($objectToCheck -eq $null) {
        return $true
    }

    if ($objectToCheck -is [String] -and $objectToCheck -eq [String]::Empty) {
        return $true
    }

    if ($objectToCheck -is [DBNull] -or $objectToCheck -is [System.Management.Automation.Language.NullString]) {
        return $true
    }

    return $false
}

Function Get-ShortPath(){
	param(
		[string] $path
	)

	$path = $path.Trim('\\')
	$parts = $path.Split('\\');

	$shortPath = "\\" + $parts[0] + "\" + $parts[1]
	for($i = 2;$i -lt $parts.Length -1;$i++){		
		$tempPath = $shortPath + "\" + $parts[$i]

			$tempLeaf = $tempPath | Get-ShortName

			# If 8.3 is disabled, barf so the caller knows to try another approach
			If($parts[$i] -eq $tempLeaf){
				$m = "Get-ShortPath failed to get 8.3 path. TempPath=" + $tempPath
				Write-Log -message $m -severity 4
				Throw [System.Exception] "8.3 failed"
			}
		
		$shortPath += "\" + $tempLeaf
	}

	$shortPath += "\" + $parts[$parts.Length -1]
	return $shortPath	
}

Function Get-ShortName
{
	BEGIN { $fso = New-Object -ComObject Scripting.FileSystemObject }
	PROCESS {
		$fso.getfolder($_).ShortName
	} 
}

Function MapPath(){
	param(
		[string] $path
	)	
	
	$parts = $path.Split('\\');
	$totalLength = 0
	$pathToMapTo = ""
	$keepAdding = $true
	$leafPath = ""
	$finalPath = ""

	$finishedRootPath = $false
	For($i=0; $i -lt $parts.Length; $i++){
		If(($pathToMapTo.Length + $parts[$i].Length -gt 247) -or ($finishedRootPath -eq $true) -or ($i -eq ($parts.Length -1))){
			$finishedRootPath = $true
			$leafPath += $parts[$i] + "\"
		}Else{
			$pathToMapTo += $parts[$i] + "\"
		}
	}

	$pathToMapTo = $pathToMapTo.TrimEnd("\")
	$leafPath = $leafPath.TrimEnd("\")

	# Find a free drive
	$letters = $Config.AvailableDriveLetters.Split(';')
	$driveLetter = $null;
	foreach($letter in $letters){
		If((Test-Path -Path "${letter}:\") -eq $false){
			$driveLetter = $letter
			break;
		}
	}

	If($driveLetter -eq $null){
		$m = "No drive letters available to map to"
		Throw [Exception] $m
	}

	If($leafPath.Length -gt 256){
		$m = "Leaf of mapped drive still too long"
		Throw [Exception] $m
	}

	# Map the drive letter
	Try{
		$drive = New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $pathToMapTo -Persist -Scope "Global"
	}Catch [System.Exception]{
		$m = "Failed to map drive letter, retry later: " + $_.Exception.Message
		Throw [Exception] $m
	}

	$finalPath = "${driveLetter}:\$leafPath"

	return $finalPath
}

Function UnMapPath(){
	param(
		[string] $path
	)

	$driveLetter = $path[0]

	If((Test-Path -Path "${driveLetter}:\") -eq $true){
		Remove-PSDrive -Name $driveLetter -PSProvider FileSystem

		$m = "Unmapped drive letter " + $driveLetter
		Write-Log -severity 4 -message $m
	}	
}

Function Write-Log(){
	param(
		[string] $message,
		[int] $severity = 1
	)

	# Logging Levels
	# 1 = Normal
	# 2 = Error
	# 3 = Warning
	# 4 = Verbose
	# 5 = Debug

	$message = $severity.ToString() + ", " + [System.DateTime]::UtcNow.ToString("yyyy-MM-dd-HH-mm-ss-fff") + ", " + $message

    switch ($severity)
    {
        '1' {Write-Output $message;break}
        '2' {Write-Error $message;break}
        '3' {Write-Warning $message;break}
        '4' {Write-Verbose $message;break}
        '5' {Write-Debug $message;break}
        Default {Write-Host $message}
    }
    
}