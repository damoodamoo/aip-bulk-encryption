#
# Delabeller.ps1
#
# Includes

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

#. "$PSScriptRoot\Utility.ps1"

$script:wordApp = $null
$script:excelApp = $null
$script:pptApp = $null
$oldLabels = @("Secret", "Restricted - External", "Restricted - Internal", "Unrestricted", "Confidential", "Internal Only")

Function RemovePreviousLabel(){
	param(
		[string] $path
	)

	# Add any custom metadata / custom decryption / visual marking removal logic here. 
	# The methods below are indicative and should be double checked...
	# NOTE: The RemoveMarking() method uses Office Interop to remove old labels from headers and footers. It should be used very carefully (or maybe not used at all!)
}

Function RemoveMarking(){
	param(
		[string] $path
	)

	$doc = Get-Item -literalpath $path
	$modified = $doc.LastWriteTime

	# Check it's a document we want
	$ext = [System.IO.Path]::GetExtension($path)
	switch($ext){
		".doc" {
			RemoveFromWord -path $path; break;
		}
		".docx"{
			RemoveFromWord -path $path; break;
		}
		".xls" {
			RemoveFromExcel -path $path; break;
		}
		".xlsx" {
			RemoveFromExcel -path $path; break;
		}
		".ppt" {
			#RemoveFromPowerPoint -path $path; break;
		}
		".pptx" {
			#RemoveFromPowerPoint -path $path; break;
		}
		default{ return;}
	}

	#$doc = Get-Item -literalpath $path
	$doc.LastWriteTime = $modified
}

Function RemoveFromWord(){
	param(
		[string] $path
	)

	If($script:wordApp -eq $null){
		$script:wordApp = New-Object -ComObject Word.Application 
		$script:wordApp.Visible = $false
		Write-Log -message "Starting Word Instance..." -severity 1
	}

	Try
	{
		$doc = $wordApp.Documents.Open($path)
		foreach($section in $doc.Sections){
			$footer = $section.Footers.Item(1)
			$newText = ReplaceText -text $footer.Range.Text
			$footer.Range.Text = $newText
		}	
		
		$doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdSaveChanges, [Microsoft.Office.Interop.Word.WdOriginalFormat]::wdOriginalDocumentFormat, $false)	

	} Catch [System.Exception]{
		$m = "Failed to remove visual marking: " + $_.Exception.Message
		Throw [Exception] $m
	}
}

Function RemoveFromExcel(){
	param(
		[string] $path
	)

	If($script:excelApp -eq $null){
		$script:excelApp = New-Object -ComObject Excel.Application 
		$script:excelApp.Visible = $false
		Write-Log -message "Starting Excel Instance..." -severity 1
	}

	Try
	{
		$wb = $script:excelApp.Workbooks.Open($path)
		foreach($sheet in  $wb.Sheets){
			$sheet.PageSetup.CenterFooter = ReplaceText -text $sheet.PageSetup.CenterFooter
		}
		$wb.Saved = $true;
		$wb.Close($true)
	}
	Catch [System.Exception]{
		$m = "Failed to remove visual marking: " + $_.Exception.Message
		Throw [Exception] $m
	}
}

Function RemoveFromPowerPoint(){
	param(
		[string] $path
	)

	Try{
		$script:pptApp = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application");
	} Catch [System.Exception]{
		# failed to get a running instance - let's start one

		$script:pptApp = New-Object -ComObject PowerPoint.Application 
		#$script:pptApp.Visible = [Microsoft.Office.Core.MsoTriState]::msoFalse
		Write-Log -message "Starting PowerPoint Instance..." -severity 1
	}

	Try
	{
		$pres = $global:pptApp.Presentations.Open($path)

		# Do the master template
		$master = $pres.SlideMaster
		$master.HeadersFooters.Footer.Text = ReplaceText -text $master.HeadersFooters.Footer.Text 

		# Do the custom templates
		foreach($layout in $master.CustomLayouts){
			$layout.HeadersFooters.Footer.Text = ReplaceText -text $layout.HeadersFooters.Footer.Text 
		}

		# Do the actual slides
		foreach($slide in $pres.Slides){
			$slide.HeadersFooters.Footer.Text = ReplaceText -text $slide.HeadersFooters.Footer.Text
		}

		$pres.Save()
		$pres.Close()

	} Catch [System.Exception]{
		$m = "Failed to remove visual marking: " + $_.Exception.Message
		Throw [Exception] $m
	}
}

Function ReplaceText(){
	param(
		[string] $text
	)

	foreach($label in $oldLabels){
			$text = $text.Replace($label, "")
	}

	return $text
}