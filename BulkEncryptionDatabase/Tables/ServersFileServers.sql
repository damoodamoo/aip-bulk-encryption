CREATE TABLE [dbo].[ServersFileServers]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [ServerId] INT NOT NULL,
	[FileServerId] INT NOT NULL

	FOREIGN KEY ([ServerId]) REFERENCES [Servers](Id),
	FOREIGN KEY ([FileServerId]) REFERENCES [FileServers](Id)
)
