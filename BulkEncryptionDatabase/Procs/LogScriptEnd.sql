CREATE PROCEDURE [dbo].[LogScriptEnd]
	@instanceId INT,
	@numberProcessed INT = NULL,
	@numberErrors INT = NULL,
	@exception NVARCHAR(MAX) = NULL
AS

-- Update the instances table to mark this script as 'done'... at least for now
UPDATE Instances
SET 
	[EndTime] = GETUTCDATE(),
	[NumberProcessed] = @numberProcessed,
	[NumberErrors] = @numberErrors,
	[Exception] = @exception,
	[IsActive] = 0
WHERE [Id] = @instanceId
