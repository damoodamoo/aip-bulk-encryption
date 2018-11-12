
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptLoc = Get-Item -Path $PSScriptRoot
$ScriptLoc = $ScriptLoc.Parent
. "$($ScriptLoc.FullName)\Utility.ps1"

Function TestFile(){
	param(
		[string] $filename,
		[string] $expected,
		[string] $direction
	)

	$result = TranslateFileName -newFileName $filename -direction $direction
	if($result -ne $expected){
		Throw "FAIL: Expected $expected, Got: $result"
	}
}

# Encrypt
TestFile -filename "C:\test\myfile.ppdf" -expected "C:\test\myfile.pdf" -direction "encrypt"
TestFile -filename "C:\test\myfile.ptxt" -expected "C:\test\myfile.txt" -direction "encrypt"
TestFile -filename "C:\test\ptxt.ptxt" -expected "C:\test\ptxt.txt" -direction "encrypt"
TestFile -filename "\\UNC-HERE\share$\test\\another\another\sub\myfile.ppdf" -expected "\\UNC-HERE\share$\test\\another\another\sub\myfile.pdf" -direction "encrypt"
TestFile -filename "C:\test\rich-text.rtf.pfile" -expected "C:\test\rich-text.rtf" -direction "encrypt"
TestFile -filename "C:\test\random.random.pfile" -expected "C:\test\random.random" -direction "encrypt"

# Decrypt
TestFile -filename "C:\test\myfile.pdf" -expected "C:\test\myfile.ppdf" -direction "decrypt"
TestFile -filename "C:\test\myfile.txt" -expected "C:\test\myfile.ptxt" -direction "decrypt"
TestFile -filename "C:\test\ptxt.txt" -expected "C:\test\ptxt.ptxt" -direction "decrypt"
TestFile -filename "\\UNC-HERE\share$\test\\another\another\sub\myfile.pdf" -expected "\\UNC-HERE\share$\test\\another\another\sub\myfile.ppdf" -direction "decrypt"
TestFile -filename "C:\test\rich-text.rtf" -expected "C:\test\rich-text.rtf.pfile" -direction "decrypt"
TestFile -filename "C:\test\random.random" -expected "C:\test\random.random.pfile" -direction "decrypt"
