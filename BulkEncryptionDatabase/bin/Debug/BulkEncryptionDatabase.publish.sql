﻿/*
Deployment script for bulkencryption

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "bulkencryption"
:setvar DefaultFilePrefix "bulkencryption"
:setvar DefaultDataPath ""
:setvar DefaultLogPath ""

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
PRINT N'Dropping unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files] DROP CONSTRAINT [DF__Files__Status__72C60C4A];


GO
PRINT N'Dropping unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files] DROP CONSTRAINT [FK__Files__OriginalF__73BA3083];


GO
PRINT N'Dropping unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files] DROP CONSTRAINT [FK__Files__LabelId__74AE54BC];


GO
/*
The column [dbo].[Files].[FileServer] is being dropped, data loss could occur.
*/
GO
PRINT N'Starting rebuilding table [dbo].[Files]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_Files] (
    [Id]               INT             IDENTITY (1, 1) NOT NULL,
    [FilePath]         NVARCHAR (1023) NOT NULL,
    [FileServerId]     INT             NULL,
    [Location]         NVARCHAR (1023) NULL,
    [Status]           INT             DEFAULT 1 NOT NULL,
    [StartedWhen]      DATETIME        NULL,
    [CompletedWhen]    DATETIME        NULL,
    [Exception]        NVARCHAR (MAX)  NULL,
    [RetryCount]       INT             NULL,
    [InstanceId]       INT             NULL,
    [LabelId]          INT             NOT NULL,
    [NewFileName]      NVARCHAR (1023) NULL,
    [NewFileSize]      BIGINT          NULL,
    [OriginalFileSize] BIGINT          NULL,
    [PotentialBJLabel] BIT             NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[Files])
    BEGIN
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_Files] ON;
        INSERT INTO [dbo].[tmp_ms_xx_Files] ([Id], [FilePath], [Location], [Status], [StartedWhen], [CompletedWhen], [Exception], [RetryCount], [InstanceId], [LabelId], [NewFileName], [NewFileSize], [OriginalFileSize])
        SELECT   [Id],
                 [FilePath],
                 [Location],
                 [Status],
                 [StartedWhen],
                 [CompletedWhen],
                 [Exception],
                 [RetryCount],
                 [InstanceId],
                 [LabelId],
                 [NewFileName],
                 [NewFileSize],
                 [OriginalFileSize]
        FROM     [dbo].[Files]
        ORDER BY [Id] ASC;
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_Files] OFF;
    END

DROP TABLE [dbo].[Files];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_Files]', N'Files';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'Altering [dbo].[ServersFileServers]...';


GO
ALTER TABLE [dbo].[ServersFileServers] DROP COLUMN [FileServer];


GO
ALTER TABLE [dbo].[ServersFileServers]
    ADD [FileServerId] INT NOT NULL;


GO
PRINT N'Starting rebuilding table [dbo].[GlobalConfig]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_GlobalConfig] (
    [Id]    INT             IDENTITY (1, 1) NOT NULL,
    [Key]   NVARCHAR (1023) NOT NULL,
    [Value] NVARCHAR (MAX)  NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[GlobalConfig])
    BEGIN
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_GlobalConfig] ON;
        INSERT INTO [dbo].[tmp_ms_xx_GlobalConfig] ([Id], [Key], [Value])
        SELECT   [Id],
                 [Key],
                 [Value]
        FROM     [dbo].[GlobalConfig]
        ORDER BY [Id] ASC;
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_GlobalConfig] OFF;
    END

DROP TABLE [dbo].[GlobalConfig];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_GlobalConfig]', N'GlobalConfig';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'Creating [dbo].[FileServers]...';


GO
CREATE TABLE [dbo].[FileServers] (
    [Id]            INT             IDENTITY (1, 1) NOT NULL,
    [FileServer]    NVARCHAR (1023) NOT NULL,
    [BJPCStartDate] DATETIME        NULL,
    [BJPCEndDate]   DATETIME        NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


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
PRINT N'Creating unnamed constraint on [dbo].[Files]...';


GO
ALTER TABLE [dbo].[Files] WITH NOCHECK
    ADD FOREIGN KEY ([FileServerId]) REFERENCES [dbo].[FileServers] ([Id]);


GO
PRINT N'Creating unnamed constraint on [dbo].[ServersFileServers]...';


GO
ALTER TABLE [dbo].[ServersFileServers] WITH NOCHECK
    ADD FOREIGN KEY ([FileServerId]) REFERENCES [dbo].[FileServers] ([Id]);


GO
PRINT N'Altering [dbo].[SelectNextFileToProcess]...';


GO
ALTER PROCEDURE [dbo].[SelectNextFileToProcess]
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
				AND f.[FileServerId] IN (SELECT [FileServerId] FROM [ServersFileServers] sfs WHERE sfs.ServerId = @serverId)
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
		SELECT f.*, l.[LabelGuid], l.[LabelName], s.IsActive, fs.FileServer, fs.BJPCStartDate, fs.BJPCEndDate
		FROM Files f 
			LEFT JOIN Labels l on f.[LabelId] = l.Id
			LEFT JOIN Instances i on f.[InstanceId] = i.Id
			LEFT JOIN [Servers] s on i.ServerId = s.Id
			LEFT JOIN [FileServers] fs on fs.Id = f.FileServerId
			WHERE f.[Id] = @rowId

	END

COMMIT
GO
PRINT N'Altering [dbo].[UpdateFileRow]...';


GO
ALTER PROCEDURE [dbo].[UpdateFileRow]
	@rowId INT,
	@exception NVARCHAR(MAX) = NULL,
	@retryCount INT = NULL,
	@status INT,
	@newfilename NVARCHAR(1024) = NULL,
	@newfilesize BIGINT = NULL,
	@originalfilesize BIGINT = NULL,
	@potentialBJLabel BIT = NULL

AS

-- Is this an error or are we good?
-- DECLARE @status INT = 3
-- IF @exception IS NOT NULL AND @exception != '' SET @status = 4

-- Update the row
UPDATE Files
	SET [Status] = @status, [CompletedWhen] = GETUTCDATE(), [Exception] = @exception, [RetryCount] = @retryCount, [NewFileName] = @newfilename, [NewFileSize] = @newfilesize, [OriginalFileSize] = @originalfilesize, [PotentialBJLabel] = @potentialBJLabel
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
