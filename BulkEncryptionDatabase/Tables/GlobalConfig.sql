﻿CREATE TABLE [dbo].[GlobalConfig]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [Key] NVARCHAR(1023) NOT NULL, 
    [Value] NVARCHAR(MAX) NOT NULL
)