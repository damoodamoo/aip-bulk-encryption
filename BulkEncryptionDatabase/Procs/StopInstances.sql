CREATE PROCEDURE [dbo].[StopInstances]
	@serverName NVARCHAR(1023)
AS

DECLARE @ServerID AS INT

SELECT @ServerID = Id FROM [SERVERS] WHERE [Servername] = @serverName

-- Set the Server as InActive so no new instances can start.
-- UPDATE [Servers] SET [isActive] = 0 WHERE [ServerName] = @serverName

-- Set existing running instances at inactive.
-- This will ensure any running instances are returned an empty file set and shutdown.
UPDATE [Instances] SET [isActive] = 0, [EndTime] = GETUTCDATE() WHERE [ServerId] = @ServerID and [IsActive] = 1

GO