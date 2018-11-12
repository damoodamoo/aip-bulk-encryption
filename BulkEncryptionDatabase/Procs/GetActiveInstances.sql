CREATE PROCEDURE [dbo].[GetActiveInstances]
	@serverId INT
AS

-- Get all the running scripts for this server
SELECT * FROM [Instances] i 
	WHERE i.[ServerId] = @serverId AND i.[EndTime] IS NULL AND i.[IsActive] = 1

