CREATE PROCEDURE [dbo].[UpdateFileRow]
	@rowId INT,
	@exception NVARCHAR(MAX) = NULL,
	@attemptCount INT = NULL,
	@status INT,
	@newfilename NVARCHAR(1024) = NULL,
	@newfilesize BIGINT = NULL,
	@originalfilesize BIGINT = NULL,
	@lastModifiedWhen DATETIME2 = NULL,
	@owner NVARCHAR(1023) = NULL

AS

-- Update the row
UPDATE Files
	SET [Status] = @status, [CompletedWhen] = GETUTCDATE(), [Exception] = @exception, [AttemptCount] = @attemptCount, [NewFileName] = @newfilename, [NewFileSize] = @newfilesize, [OriginalFileSize] = @originalfilesize, [LastModifiedWhen] = @lastModifiedWhen, [Owner] = @owner
	WHERE [Id] = @rowId

-- Get the row to send back to the script
SELECT * FROM Files f WHERE f.[Id] = @rowId