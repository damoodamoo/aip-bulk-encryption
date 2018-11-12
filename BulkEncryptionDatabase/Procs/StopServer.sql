CREATE PROCEDURE [dbo].[StopServer]
	@serverName NVARCHAR(1023)
AS

DECLARE @ServerID AS INT

SELECT @ServerID = Id FROM [SERVERS] WHERE [Servername] = @serverName

-- Set the Server as InActive so no new instances can start.
UPDATE [Servers] SET [isActive] = 0 WHERE [ServerName] = @serverName

GO
