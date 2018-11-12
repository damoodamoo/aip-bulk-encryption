CREATE PROCEDURE [dbo].[GetServerConfig]
	@serverName NVARCHAR(1023)
AS

SELECT * FROM [Servers] s 
	WHERE s.[ServerName] = @serverName

