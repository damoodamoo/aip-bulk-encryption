﻿/*
Deployment script for BulkEncryptionDatabase_1

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "BulkEncryptionDatabase_1"
:setvar DefaultFilePrefix "BulkEncryptionDatabase_1"
:setvar DefaultDataPath "C:\Users\damoo\AppData\Local\Microsoft\VisualStudio\SSDT\BulkEncryption"
:setvar DefaultLogPath "C:\Users\damoo\AppData\Local\Microsoft\VisualStudio\SSDT\BulkEncryption"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET ARITHABORT ON,
                CONCAT_NULL_YIELDS_NULL ON,
                CURSOR_DEFAULT LOCAL 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET PAGE_VERIFY NONE,
                DISABLE_BROKER 
            WITH ROLLBACK IMMEDIATE;
    END


GO
ALTER DATABASE [$(DatabaseName)]
    SET TARGET_RECOVERY_TIME = 0 SECONDS 
    WITH ROLLBACK IMMEDIATE;


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET QUERY_STORE (QUERY_CAPTURE_MODE = AUTO, OPERATION_MODE = READ_WRITE) 
            WITH ROLLBACK IMMEDIATE;
    END


GO
PRINT N'Creating [dbo].[Files]...';


GO
CREATE TABLE [dbo].[Files] (
    [Id]               INT             IDENTITY (1, 1) NOT NULL,
    [FilePath]         NVARCHAR (1023) NOT NULL,
    [FileServer]       NVARCHAR (1023) NOT NULL,
    [Location]         NVARCHAR (1023) NULL,
    [Status]           INT             NOT NULL,
    [StartedWhen]      DATETIME        NULL,
    [CompletedWhen]    DATETIME        NULL,
    [Exception]        NVARCHAR (MAX)  NULL,
    [RetryCount]       INT             NULL,
    [InstanceId]       INT             NULL,
    [LabelId]          INT             NOT NULL,
    [NewFileName]      NVARCHAR (1023) NULL,
    [NewFileSize]      BIGINT          NULL,
    [OriginalFileSize] BIGINT          NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating [dbo].[GlobalConfig]...';


GO
CREATE TABLE [dbo].[GlobalConfig] (
    [Id]    INT             IDENTITY (1, 1) NOT NULL,
    [Key]   NVARCHAR (1023) NOT NULL,
    [Value] NVARCHAR (1023) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating [dbo].[Instances]...';


GO
CREATE TABLE [dbo].[Instances] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [StartTime]       DATETIME       NOT NULL,
    [EndTime]         DATETIME       NULL,
    [NumberProcessed] INT            NULL,
    [NumberErrors]    INT            NULL,
    [Exception]       NVARCHAR (MAX) NULL,
    [ServerId]        INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating [dbo].[Labels]...';


GO
CREATE TABLE [dbo].[Labels] (
    [Id]        INT            IDENTITY (1, 1) NOT NULL,
    [LabelName] NVARCHAR (255) NOT NULL,
    [LabelGuid] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating [dbo].[Servers]...';


GO
CREATE TABLE [dbo].[Servers] (
    [Id]              INT             IDENTITY (1, 1) NOT NULL,
    [StartTime]       TIME (7)        NOT NULL,
    [EndTime]         TIME (7)        NOT NULL,
    [ServerName]      NVARCHAR (1023) NOT NULL,
    [NumberInstances] INT             NOT NULL,
    [ServerComplete]  BIT             NULL,
    [IsActive]        BIT             NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating [dbo].[ServersFileServers]...';


GO
CREATE TABLE [dbo].[ServersFileServers] (
    [Id]         INT             IDENTITY (1, 1) NOT NULL,
    [ServerId]   INT             NOT NULL,
    [FileServer] NVARCHAR (1023) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files]
    ADD DEFAULT 1 FOR [Status];


GO
PRINT N'Creating unnamed constraint on [dbo].[Servers]...';


GO
ALTER TABLE [dbo].[Servers]
    ADD DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files] WITH NOCHECK
    ADD FOREIGN KEY ([InstanceId]) REFERENCES [dbo].[Instances] ([Id]);


GO
PRINT N'Creating unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files] WITH NOCHECK
    ADD FOREIGN KEY ([LabelId]) REFERENCES [dbo].[Labels] ([Id]);


GO
PRINT N'Creating unnamed constraint on [dbo].[Instances]...';


GO
ALTER TABLE [dbo].[Instances] WITH NOCHECK
    ADD FOREIGN KEY ([ServerId]) REFERENCES [dbo].[Servers] ([Id]);


GO
PRINT N'Creating unnamed constraint on [dbo].[ServersFileServers]...';


GO
ALTER TABLE [dbo].[ServersFileServers] WITH NOCHECK
    ADD FOREIGN KEY ([ServerId]) REFERENCES [dbo].[Servers] ([Id]);


GO
PRINT N'Creating [dbo].[GetActiveInstances]...';


GO
CREATE PROCEDURE [dbo].[GetActiveInstances]
	@serverId INT
AS

-- Get all the running scripts for this server
SELECT * FROM [Instances] i 
	WHERE i.[ServerId] = @serverId AND i.[EndTime] IS NULL
GO
PRINT N'Creating [dbo].[GetActiveServers]...';


GO
CREATE PROCEDURE [dbo].[GetActiveServers]

AS

-- Get all the servers which should be running
DECLARE @timeNow TIME(7) = CONVERT (time, GETUTCDATE())

SELECT * FROM [Servers] s 
	WHERE 
		s.[StartTime] < @timeNow 
		AND s.[EndTime] > @timeNow 
		AND (s.[ServerComplete] IS NULL OR s.[ServerComplete] <> 1)
		AND s.IsActive = 1
GO
PRINT N'Creating [dbo].[GetServerConfig]...';


GO
CREATE PROCEDURE [dbo].[GetServerConfig]
	@serverName NVARCHAR(1023)
AS

SELECT * FROM [Servers] s 
	WHERE s.[ServerName] = @serverName
GO
PRINT N'Creating [dbo].[LogScriptEnd]...';


GO
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
	[Exception] = @exception
WHERE [Id] = @instanceId
GO
PRINT N'Creating [dbo].[LogScriptStart]...';


GO
CREATE PROCEDURE [dbo].[LogScriptStart]
	@serverName NVARCHAR(1023)
AS

DECLARE @rowId INT = NULL

BEGIN TRANSACTION

	-- Get the row from the Servers table
	DECLARE @serverId INT
	SELECT @serverId = [Id] FROM [Servers] s WHERE s.ServerName = @serverName

	-- Return null if there isn't a row in the server table for this
	IF @serverId = NULL RETURN NULL

	-- Add a row to the instances table to log this script as 'running'
	INSERT INTO Instances (StartTime, ServerId)
		VALUES (GETUTCDATE(), @serverId)	

	-- Return the new Id for the script to use
	SELECT SCOPE_IDENTITY()

COMMIT
GO
PRINT N'Creating [dbo].[LogServerComplete]...';


GO
CREATE PROCEDURE [dbo].[LogServerComplete]
	@serverName NVARCHAR(1023)
AS

-- Update the servers table that this server is done
UPDATE [Servers] SET [ServerComplete] = 1 WHERE [ServerName] = @serverName
GO
PRINT N'Creating [dbo].[SelectNextFileToProcess]...';


GO
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
				AND f.[FileServer] IN (SELECT [FileServer] FROM [ServersFileServers] sfs WHERE sfs.ServerId = @serverId)
				AND (f.[RetryCount] IS NULL OR f.[RetryCount] < @maxRetries)
			ORDER BY f.[RetryCount] DESC, f.[Id] ASC
	END

	IF @mode = 'decrypt'
	BEGIN
		SELECT @rowId = Id 
			FROM Files f 
			WITH (TABLOCKX, HOLDLOCK) 
			WHERE 
				(f.[Status] = 3 OR f.[Status] = 5)
				AND f.[FileServer] IN (SELECT [FileServer] FROM [ServersFileServers] sfs WHERE sfs.ServerId = @serverId)
				AND (f.[RetryCount] IS NULL OR f.[RetryCount] < @maxRetries)
			ORDER BY f.[RetryCount] DESC, f.[Id] ASC
	END


	IF @rowId IS NOT NULL AND @rowId > 0
	BEGIN

		-- 'Lock' the row for processing by this script
		UPDATE Files
			SET [Status] = 2, [StartedWhen] = GETUTCDATE(), [InstanceId] = @scriptInstanceId
			WHERE [Id] = @rowId

		-- Get the row (with the label info + server status) to send back to the script
		SELECT f.*, l.[LabelGuid], l.[LabelName], s.IsActive 
		FROM Files f 
			LEFT JOIN Labels l on f.[LabelId] = l.Id
			LEFT JOIN Instances i on f.[InstanceId] = i.Id
			LEFT JOIN [Servers] s on i.ServerId = s.Id
			WHERE f.[Id] = @rowId

	END

COMMIT
GO
PRINT N'Creating [dbo].[UpdateFileRow]...';


GO
CREATE PROCEDURE [dbo].[UpdateFileRow]
	@rowId INT,
	@exception NVARCHAR(MAX) = NULL,
	@retryCount INT = NULL,
	@status INT,
	@newfilename NVARCHAR(1024) = NULL,
	@newfilesize BIGINT = NULL,
	@originalfilesize BIGINT = NULL

AS

-- Is this an error or are we good?
-- DECLARE @status INT = 3
-- IF @exception IS NOT NULL AND @exception != '' SET @status = 4

-- Update the row
UPDATE Files
	SET [Status] = @status, [CompletedWhen] = GETUTCDATE(), [Exception] = @exception, [RetryCount] = @retryCount, [NewFileName] = @newfilename, [NewFileSize] = @newfilesize, [OriginalFileSize] = @originalfilesize
	WHERE [Id] = @rowId

-- Get the row to send back to the script
SELECT * FROM Files f WHERE f.[Id] = @rowId
GO
/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

/* STATUS VALUES 
1 - Awaiting Processing
2 - In Process
3 - Complete
4 - Error
5 - Error rolling back (removing label)
*/

-- GLOBAL CONFIG --
SET IDENTITY_INSERT [GlobalConfig] ON

INSERT INTO [GlobalConfig] 
(Id,		[Key],							[Value])
VALUES 
(1,			'MaxRetries',					'5'),
(2,			'AADWebAppId',					'ABC-123'),
(3,			'AADWebAppKey',					'XXX'),
(4,			'AADNativeAppId',				'123'),
(5,			'AADToken',						'Token-1')

SET IDENTITY_INSERT [GlobalConfig] OFF

-- LABELS --
SET IDENTITY_INSERT [Labels] ON

INSERT INTO [Labels] 
(Id,		LabelName,					LabelGuid)
VALUES 
(1,			'Public',					'1234'),
(2,			'Restricted External',		'1234'),
(3,			'Restricted Internal',		'1234'),
(4,			'Confidential',				'1234'),
(5,			'Secret',					'd9f23ae3-a239-45ea-bf23-f515f824c57b')

SET IDENTITY_INSERT [Labels] OFF

-- SERVERS --
SET IDENTITY_INSERT [Servers] ON
INSERT INTO [Servers] 
(Id,	ServerName,			StartTime,			EndTime,		NumberInstances,		ServerComplete)
VALUES
(1,		'DAVROS',			'09:00:00',			'17:00:00',		1,						NULL),
(2,		'MININT-RDS9B7O',	'09:00:00',			'17:00:00',		2,						NULL)
SET IDENTITY_INSERT [Servers] OFF

-- SERVERS - FILE SERVERS --
INSERT INTO [ServersFileServers] 
(ServerId,		FileServer)
VALUES
(1,				'X'),
(1,				'Y'),
(1,				'Z'),
(2,				'A'),
(2,				'B')


-- FILES --
INSERT INTO [Files]
([Status],	 [FileServer],	[LabelId],		[FilePath])
VALUES
(1,			'X',			5,				'X:\docs\ValidDoc1.docx'),
(1,			'X',			5,				'X:\docs\ValidDoc2.docx'),
(1,			'X',			5,				'X:\docs\ValidDoc3.docx'),
(1,			'X',			5,				'X:\docs\ValidDoc4.docx'),
(1,			'X',			5,				'X:\docs\ValidDoc5.docx'),
(1,			'X',			5,				'X:\docs\ValidSpread1.xlsx'),
(1,			'X',			5,				'X:\docs\ValidSpread2.xlsx'),
(1,			'Y',			5,				'X:\docs\ValidSpread3.xlsx'),
(1,			'Y',			5,				'X:\docs\ValidSpread4.xlsx'),
(1,			'Y',			5,				'X:\docs\ValidSpread5.xlsx'),
(1,			'Y',			5,				'X:\docs\OldDoc.doc'),
(1,			'Y',			5,				'X:\docs\OldSpread.xls'),
(1,			'Y',			5,				'X:\docs\CorruptedDoc.docx'),
(1,			'Y',			5,				'X:\docs\CorruptedOldDoc.doc'),
(1,			'X',			5,				'X:\docs\CorruptedSpread.xlsx'),
(1,			'X',			5,				'X:\docs\CorruptedOldSpread.xls'),
(1,			'X',			5,				'X:\docs\MissingDoc.docx'),
(1,			'Z',			5,				'X:\docs\MisingSpread.docx'),
(1,			'X',			5,				'X:\docs\AccessDeniedDoc.docx'),
(1,			'X',			5,				'X:\docs\AccessDeniedSpread.xlsx'),
(1,			'Z',			5,				'X:\docs\TextFile.txt'),
(1,			'Z',			5,				'X:\docs\Image.jpg'),
(1,			'A',			5,				'c:\test\1.docx'),
(1,			'A',			5,				'c:\test\2.docx'),
(1,			'A',			5,				'c:\test\3.docx'),
(1,			'B',			5,				'c:\test\4.docx'),
(1,			'B',			5,				'c:\test\5.docx'),
(1,			'B',			5,				'c:\test\6.docx')


-- STATUS CODES --
INSERT INTO [StatusCodes] (Status) VALUES 
('NotStarted'),('InProgress'),('SuccessfulEncrypt'),('EncryptError'),('FailedDecrypt'),('WillNotEncrypt'),('NotFound')

GO

GO
PRINT N'Checking existing data against newly created constraints';


GO
USE [$(DatabaseName)];


GO
CREATE TABLE [#__checkStatus] (
    id           INT            IDENTITY (1, 1) PRIMARY KEY CLUSTERED,
    [Schema]     NVARCHAR (256),
    [Table]      NVARCHAR (256),
    [Constraint] NVARCHAR (256)
);

SET NOCOUNT ON;

DECLARE tableconstraintnames CURSOR LOCAL FORWARD_ONLY
    FOR SELECT SCHEMA_NAME([schema_id]),
               OBJECT_NAME([parent_object_id]),
               [name],
               0
        FROM   [sys].[objects]
        WHERE  [parent_object_id] IN (OBJECT_ID(N'dbo.Files'), OBJECT_ID(N'dbo.Instances'), OBJECT_ID(N'dbo.ServersFileServers'))
               AND [type] IN (N'F', N'C')
                   AND [object_id] IN (SELECT [object_id]
                                       FROM   [sys].[check_constraints]
                                       WHERE  [is_not_trusted] <> 0
                                              AND [is_disabled] = 0
                                       UNION
                                       SELECT [object_id]
                                       FROM   [sys].[foreign_keys]
                                       WHERE  [is_not_trusted] <> 0
                                              AND [is_disabled] = 0);

DECLARE @schemaname AS NVARCHAR (256);

DECLARE @tablename AS NVARCHAR (256);

DECLARE @checkname AS NVARCHAR (256);

DECLARE @is_not_trusted AS INT;

DECLARE @statement AS NVARCHAR (1024);

BEGIN TRY
    OPEN tableconstraintnames;
    FETCH tableconstraintnames INTO @schemaname, @tablename, @checkname, @is_not_trusted;
    WHILE @@fetch_status = 0
        BEGIN
            PRINT N'Checking constraint: ' + @checkname + N' [' + @schemaname + N'].[' + @tablename + N']';
            SET @statement = N'ALTER TABLE [' + @schemaname + N'].[' + @tablename + N'] WITH ' + CASE @is_not_trusted WHEN 0 THEN N'CHECK' ELSE N'NOCHECK' END + N' CHECK CONSTRAINT [' + @checkname + N']';
            BEGIN TRY
                EXECUTE [sp_executesql] @statement;
            END TRY
            BEGIN CATCH
                INSERT  [#__checkStatus] ([Schema], [Table], [Constraint])
                VALUES                  (@schemaname, @tablename, @checkname);
            END CATCH
            FETCH tableconstraintnames INTO @schemaname, @tablename, @checkname, @is_not_trusted;
        END
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

IF CURSOR_STATUS(N'LOCAL', N'tableconstraintnames') >= 0
    CLOSE tableconstraintnames;

IF CURSOR_STATUS(N'LOCAL', N'tableconstraintnames') = -1
    DEALLOCATE tableconstraintnames;

SELECT N'Constraint verification failed:' + [Schema] + N'.' + [Table] + N',' + [Constraint]
FROM   [#__checkStatus];

IF @@ROWCOUNT > 0
    BEGIN
        DROP TABLE [#__checkStatus];
        RAISERROR (N'An error occurred while verifying constraints', 16, 127);
    END

SET NOCOUNT OFF;

DROP TABLE [#__checkStatus];


GO
PRINT N'Update complete.';


GO
