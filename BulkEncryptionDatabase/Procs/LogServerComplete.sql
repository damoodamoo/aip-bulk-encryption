CREATE PROCEDURE [dbo].[LogServerComplete]
	@serverName NVARCHAR(1023)
AS

-- Update the servers table that this server is done
UPDATE [Servers] SET [ServerComplete] = 1 WHERE [ServerName] = @serverName