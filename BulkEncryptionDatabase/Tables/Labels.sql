﻿CREATE TABLE [dbo].[Labels]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [LabelName] NVARCHAR(255) NOT NULL, 
    [LabelGuid] NVARCHAR(255) NOT NULL
)
