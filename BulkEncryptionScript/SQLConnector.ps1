#
# SQLConnector.ps1
#
# Includes
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

. "$PSScriptRoot\Utility.ps1"

Function Get-GlobalConfig{
	$sql = "SELECT * FROM [dbo].[GlobalConfig]"
	$returnedConfig = Invoke-SQL -connectionString $Config.SQLConnectionString -sqlCommand $sql
	return $returnedConfig;
}

Function Get-ServerConfig{
	$ret = Invoke-SQLProc -procName "GetServerConfig" -parameters @{"serverName" = $Config.ServerName}
	$row = ConvertTableTo-Object -table $ret
	$Config | Add-Member -MemberType NoteProperty –Name EndTime –Value $row.EndTime
	$Config | Add-Member -MemberType NoteProperty –Name ServerId –Value $row.Id
	$Config | Add-Member -MemberType NoteProperty –Name BatchSize –Value $row.BatchSize
	$Config | Add-Member -MemberType NoteProperty –Name NumberInstances –Value $row.NumberInstances
	$Config | Add-Member -MemberType NoteProperty –Name ServerActive –Value $row.IsActive
	$Config | Add-Member -MemberType NoteProperty –Name ServerComplete –Value $row.ServerComplete

	If(IsNull($Config.BatchSize) -or $Config.BatchSize -eq 0){
		$Config.BatchSize = 1
	}
}

Function Get-ActiveServers{
	$ret = Invoke-SQLProc -procName "GetActiveServers"
	return $ret	
}

Function Get-ActiveInstances{
	param(
		[int] $serverId
	)

	$ret = Invoke-SQLProc -procName "GetActiveInstances" -parameters @{"serverId" = $serverId}
	return $ret	
}

Function End-Instance{
	param(
		[int] $instanceId
	)

	$ret = Invoke-SQLProc -procName "EndInstance" -parameters @{"instanceId" = $instanceId}
	return $ret	
}

Function Set-ScriptStart{
	$ret = Invoke-SQLProc -procName "LogScriptStart" -parameters @{"serverName" = $Config.ServerName}
	
	# Add to config object
	$Config | Add-Member -MemberType NoteProperty –Name InstanceId –Value $ret.Rows[0].ItemArray[0]
}

Function Set-ScriptEnd{
	param(
		[int] $instanceId,
		[int] $numProcessed,
		[int] $numErrors,
		[string] $exception = $null
	)
	$ret = Invoke-SQLProc -procName "LogScriptEnd" -parameters @{"instanceId" = $instanceId; "numberProcessed" = $numProcessed; "numberErrors" = $numErrors; "exception" = $exception}
}

Function Log-ServerComplete{
	param(
		[string] $serverName
	)

	$ret = Invoke-SQLProc -procName "LogServerComplete" -parameters @{"serverName" = $serverName}
}

Function Get-FileRow{
	param(
		[string] $mode
	)
	
	$table = Invoke-SQLProc -procName "SelectNextFileToProcess" -parameters @{"serverId" = $Config.ServerId; "scriptInstanceId" = $Config.InstanceId; "maxRetries" = $Config.MaxRetries; "mode" = $mode}
	$row = $null

	If($table -ne $null -and $table.Rows -ne $null -and $table.Rows.Count -gt 0){
		$row = ConvertTableTo-Object -table $table
	}
	
	return $row
}

Function Get-FileBatch{
	param(
		[string] $mode
	)
	
	$m = "Getting batch of: " + $Config.BatchSize.ToString() + " files"
	Write-Log -message $m -severity 4
	$table = Invoke-SQLProc -procName "SelectNextBatchToProcess" -parameters @{"serverId" = $Config.ServerId; "scriptInstanceId" = $Config.InstanceId; "maxRetries" = $Config.MaxRetries; "mode" = $mode; "batchSize" = $Config.BatchSize}
	$list = @()

	If($table -ne $null -and $table.Rows -ne $null -and $table.Rows.Count -gt 0){
		foreach($row in $table.Rows){
			$list += ConvertRowTo-Object -columns $table.Columns -row $row
		}		
	}
	
	Write-Log -message "Got batch" -severity 4
	return $list
}

Function Update-FileRow{
	param(
		[int] $rowId,
		[int] $attemptCount,
		[string] $exception = $null,
		[int] $status,
        [string] $newfilename,
        [long] $newfilesize,
        [long] $originalfilesize,
		[string] $lastModifiedWhen,
		[string] $owner
 	)
   
    $updated = Invoke-SQLProc -procName "UpdateFileRow" -parameters @{"rowId" = $rowId; "status" = $status; "attemptCount" = $attemptCount; "exception" = $exception; "newfilename" = $newfilename; "newfilesize" = $newfilesize; "originalfilesize" = $originalfilesize; "lastModifiedWhen" = $lastModifiedWhen; "owner" = $owner} 
    Write-Log -severity 4 -message "Updated fileRow $rowId." 
}

Function Update-FileRows{
	param(
		$batch
 	)

	$sqlString = ""
	$params = @()
	$p = 0
	foreach($item in $batch){
		
		$exceptionParam = "@exception" + $p.ToString()
		$exceptionParamValue = $item.Exception
		$e = @{"name" = $exceptionParam; "value" = $exceptionParamValue}
		$params += $e

		$fileNameParam = "@fileName" + $p.ToString()
		$fileNameParamValue = $item.NewFileName
		$f = @{"name" = $fileNameParam; "value" = $fileNameParamValue}
		$params += $f

		$ownerParam = "@owner" + $p.ToString()
		$ownerParamValue = $item.Owner
		$o = @{"name" = $ownerParam; "value" = $ownerParamValue}
		$params += $o

		$origSizeParam = "@origSize" + $p.ToString()
		$origSizeParamValue = $item.OriginalFileSize
		$os = @{"name" = $origSizeParam; "value" = $origSizeParamValue}
		$params += $os

		$newSizeParam = "@newSize" + $p.ToString()
		$newSizeParamValue = $item.NewFileSize
		$ns = @{"name" = $newSizeParam; "value" = $newSizeParamValue}
		$params += $ns

		$modDateParam = "@lastModifiedWhen" + $p.ToString()
		$modDateParamValue = $item.LastModifiedWhen
		$mod = @{"name" = $modDateParam; "value" = $modDateParamValue}
		$params += $mod

		$attemptParam = "@attemptCount" + $p.ToString()
		$attemptParamValue = $item.AttemptCount
		$at = @{"name" = $attemptParam; "value" = $attemptParamValue}
		$params += $at

		$statusParam = "@status" + $p.ToString()
		$statusParamValue = $item.Status
		$st = @{"name" = $statusParam; "value" = $statusParamValue}
		$params += $st

		$sqlString += " ;UPDATE [Files] SET [CompletedWhen] = GETUTCDATE(), [Status] = $statusParam, [AttemptCount] = $attemptParam, [Exception] = $exceptionParam, [NewFileName] = $fileNameParam, [NewFileSize] = $newSizeParam, [OriginalFileSize] = $origSizeParam, [LastModifiedWhen] = $modDateParam, [Owner] = $ownerParam WHERE [Id] = " + $item.Id
		
		$p++
	}
   
    $updated = Invoke-SQLWithParams -sqlCommand $sqlString -params $params

    Write-Log -severity 4 -message "Updated Rows" 
}

# ----------------------------------------------------------------------------------------------
# SQL Utilities
# ----------------------------------------------------------------------------------------------

Function Open-SQLConnection{
	$connection = new-object system.data.SqlClient.SQLConnection($Config.SQLConnectionString)
	$connection.Open()
	Write-Log -severity 4 -message "Successfully connected to SQL Server"
	return $connection
}

Function Close-SQLConnection{
	$Conn.Close()
	$Conn.Dispose()
	Write-Log -severity 4 -message "SQL Connection Closed"
}

function Invoke-SQL {
    param(
        [string] $sqlCommand = $(throw "Please specify a query.")
      )
	  
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$Conn)
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null    
	
	$message = ("Ran query: [$sqlCommand]. Returned " + $dataSet.Tables[0].Rows.Count.ToString() + " row(s).")
	Write-Log -severity 5 -message $message
	return $dataSet.Tables
}
function Invoke-SQLWithParams {
    param(
        [string] $sqlCommand = $(throw "Please specify a query."),
		$params = @()
      )
	  
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$Conn)

	Foreach($param in $params){
		$command.Parameters.AddWithValue($param.name, $param.value)
	}	

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null    
	
	$message = ("Ran query: [$sqlCommand]. Returned " + $dataSet.Tables[0].Rows.Count.ToString() + " row(s).")
	Write-Log -severity 5 -message $message
	return $dataSet.Tables
}

function Invoke-SQLProc {
    param(
        [string] $procName = $(throw "Please specify a stored procedure."),
		[hashtable] $parameters=@{}
      )

    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$Conn)
	$command.CommandType = [System.Data.CommandType]::StoredProcedure
	$command.CommandText = $procName
	$paramText = ""
	foreach($p in $parameters.Keys){
        $command.Parameters.AddWithValue("@$p",[string]$parameters[$p]).Direction = [System.Data.ParameterDirection]::Input
		$paramText += ($p + " = " + [string]$parameters[$p] + ", ")
    }

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

	$message = ("Ran proc: [$procName] with parameters [$paramText]. Returned " + $dataSet.Tables[0].Rows.Count.ToString() + " row(s).")
	Write-Log -severity 5 -message $message
	return $dataSet.Tables
}

Function ConvertTableTo-Object {
	param(
		$table = $null
	)

	$row = @{}

	for($i = 0; $i -lt $table.Columns.Count; $i++){
		$colName =  $table.Columns[$i]
		$val = $table.Rows[0].ItemArray[$i]
		$row | Add-Member -MemberType NoteProperty –Name $colName –Value $val
	}

	return $row
}

Function ConvertRowTo-Object {
	param(
		$columns = $null,
		$row = $null
	)

	$obj = @{}

	for($i = 0; $i -lt $columns.Count; $i++){
		$colName =  $columns[$i]
		$val = $row.ItemArray[$i]
		$obj | Add-Member -MemberType NoteProperty –Name $colName –Value $val
	}

	return $obj
}