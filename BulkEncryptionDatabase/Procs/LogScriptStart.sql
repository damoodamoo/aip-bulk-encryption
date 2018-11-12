CREATE PROCEDURE [dbo].[LogScriptStart]
	@serverName NVARCHAR(1023)
AS

DECLARE @rowId INT = NULL

BEGIN TRANSACTION

	-- Get the row from the Servers table
	DECLARE @serverId INT
	SELECT @serverId = [Id] FROM [Servers] s WHERE s.ServerName = @serverName

	-- Return null if there isn't a row in the server table for this
	IF @serverId = NULL RETURN NULL

	-- Add a row to the instances table to log this script as 'running'
	INSERT INTO Instances (StartTime, ServerId, IsActive)
		VALUES (GETUTCDATE(), @serverId, 1)	

	-- Return the new Id for the script to use
	SELECT SCOPE_IDENTITY()

COMMIT