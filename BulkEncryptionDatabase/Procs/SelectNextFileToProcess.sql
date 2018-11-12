CREATE PROCEDURE [dbo].[SelectNextFileToProcess]
	@serverId INT,
	@scriptInstanceId INT,
	@maxRetries INT,
	@mode NVARCHAR(50)
AS

BEGIN TRANSACTION

	-- Get the next row to process
	DECLARE @rowId INT = 0

	IF @mode = 'encrypt'
	BEGIN
		SELECT @rowId = Id
			FROM Files f
			WITH (TABLOCKX, HOLDLOCK) 
			WHERE 
				(f.[Status] = 1 OR f.[Status] = 4)
				AND f.[FileServerId] IN (SELECT [FileServerId] FROM [ServersFileServers] sfs WHERE sfs.ServerId = @serverId)
				AND (f.[AttemptCount] IS NULL OR f.[AttemptCount] < @maxRetries)
			ORDER BY f.[AttemptCount] DESC, f.[Id] ASC
	END

	IF @mode = 'decrypt'
	BEGIN
		SELECT @rowId = Id 
			FROM Files f 
			WITH (TABLOCKX, HOLDLOCK) 
			WHERE 
				(f.[Status] = 3 OR f.[Status] = 5)
				AND f.[FileServerId] IN (SELECT [FileServerId] FROM [ServersFileServers] sfs WHERE sfs.ServerId = @serverId)
				AND (f.[AttemptCount] IS NULL OR f.[AttemptCount] < @maxRetries)
			ORDER BY f.[AttemptCount] DESC, f.[Id] ASC
	END


	IF @rowId IS NOT NULL AND @rowId > 0
	BEGIN

		-- 'Lock' the row for processing by this script
		UPDATE Files
			SET [Status] = 2, [StartedWhen] = GETUTCDATE(), [InstanceId] = @scriptInstanceId
			WHERE [Id] = @rowId

		-- Get the row (with the label info + server status) to send back to the script
		SELECT f.*, l.[LabelGuid], l.[LabelName], s.IsActive, fs.FileServer, i.IsActive as InstanceActive
		FROM Files f 
			LEFT JOIN Labels l on f.[LabelId] = l.Id
			LEFT JOIN Instances i on f.[InstanceId] = i.Id
			LEFT JOIN [Servers] s on i.ServerId = s.Id
			LEFT JOIN [FileServers] fs on fs.Id = f.FileServerId
			WHERE f.[Id] = @rowId

	END

COMMIT