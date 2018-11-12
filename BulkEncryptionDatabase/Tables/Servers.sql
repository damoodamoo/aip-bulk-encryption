CREATE TABLE [dbo].[Servers]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [StartTime] TIME NOT NULL, 
    [EndTime] TIME NOT NULL, 
    [ServerName] NVARCHAR(1023) NOT NULL, 
    [NumberInstances] INT NOT NULL, 
	[BatchSize]	INT NOT NULL,
    [ServerComplete] BIT NULL, 
    [IsActive] BIT NULL DEFAULT 1
)
