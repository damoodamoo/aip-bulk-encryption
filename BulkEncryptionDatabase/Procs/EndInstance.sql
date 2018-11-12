CREATE PROCEDURE [dbo].[EndInstance]
	@instanceId INT
AS

UPDATE [Instances] SET IsActive = 0 WHERE Id = @instanceId

