CREATE PROCEDURE [dbo].[ResetServer]
	@serverName NVARCHAR(1023)
AS

UPDATE [Servers] SET [isActive] = 1, [ServerComplete] = 0 WHERE [ServerName] = @serverName
GO
