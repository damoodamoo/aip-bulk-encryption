CREATE TABLE [dbo].[Files]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [FilePath] NVARCHAR(1023) NOT NULL, 
    [FileServerId] INT NULL, 
    [Location] NVARCHAR(1023) NULL, 
    [Status] INT NOT NULL DEFAULT 1, 
    [StartedWhen] DATETIME NULL, 
    [CompletedWhen] DATETIME NULL, 
    [Exception] NVARCHAR(1023) NULL, 
    [AttemptCount] INT NULL, 
    [InstanceId] INT NULL,
	[LabelId] INT NOT NULL,
	[NewFileName] NVARCHAR(1023) NULL,
	[NewFileSize] BIGINT NULL,
	[OriginalFileSize] BIGINT NULL,
	[LastModifiedWhen] DATETIME2 NULL,
	[Owner] NVARCHAR(1023) NULL,

	FOREIGN KEY (InstanceId) REFERENCES Instances(Id),
	FOREIGN KEY (LabelId) REFERENCES Labels(Id),
	FOREIGN KEY (FileServerId) REFERENCES FileServers(Id)
)
