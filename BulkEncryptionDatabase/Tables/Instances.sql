CREATE TABLE [dbo].[Instances]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [StartTime] DATETIME NOT NULL, 
    [EndTime] DATETIME NULL,
    [NumberProcessed] INT NULL, 
    [NumberErrors] INT NULL, 
    [Exception] NVARCHAR(MAX) NULL, 
    [ServerId] INT NOT NULL,
	[IsActive] BIT NULL,

	FOREIGN KEY (ServerId) REFERENCES [Servers](Id)
)
