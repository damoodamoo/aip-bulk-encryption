
CREATE PROCEDURE [dbo].[SelectNextBatchToProcess]
       @serverId            INT,
       @scriptInstanceId    INT,
       @maxRetries          INT,
       @mode                NVARCHAR(50),
       @batchSize           INT
AS
BEGIN

       DECLARE @status TABLE (Id INT)

       IF @mode = 'encrypt'
       BEGIN
            INSERT INTO @status (Id)
            VALUES (1), (4)
       END

       IF @mode = 'decrypt'
       BEGIN
            INSERT INTO @status (Id)
            VALUES (3), (5)
       END


        DECLARE @rowIds TABLE (Id INT PRIMARY KEY)

        -- 'Lock' the rows for processing by this script
        UPDATE f_
        SET
            [Status] = 2,
            [StartedWhen] = GETUTCDATE(),
            [InstanceId] = @scriptInstanceId
        OUTPUT
            inserted.Id
        INTO @rowIds
        FROM
        (
            SELECT TOP (@batchSize) *
            FROM Files f
            WHERE
                f.[Status] IN (SELECT * FROM @status)
            AND EXISTS
                (
                    SELECT 1
                    FROM [ServersFileServers] sfs
                    WHERE
                        sfs.ServerId = @serverId
                    AND sfs.[FileServerId] = f.[FileServerId]
                )
            AND f.[AttemptCount] < @maxRetries
            ORDER BY 
                f.[AttemptCount] ASC,
                f.[Id] ASC
        ) f_

	   DECLARE @rowCount INT = @@ROWCOUNT

        IF (@rowCount > 0)
        BEGIN

            -- Get the rows (with the label info + server status) to send back to the script
            SELECT f.*, l.[LabelGuid], l.[LabelName], s.IsActive, fs.FileServer, i.IsActive as InstanceActive
            FROM Files f 
            LEFT JOIN Labels l ON l.Id = f.[LabelId]
            LEFT JOIN Instances i ON i.Id = f.[InstanceId]
            LEFT JOIN [Servers] s ON s.Id = i.ServerId
            LEFT JOIN [FileServers] fs ON fs.Id = f.FileServerId
            WHERE
                f.[Id] IN (SELECT Id FROM @rowIds)

        END
END
