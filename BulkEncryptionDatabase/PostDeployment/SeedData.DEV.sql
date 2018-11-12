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
(2,			'AADWebAppId',					'AAD-web-app-guid-here'),
(3,			'AADWebAppKey',					'encrypted-AAD-key-here'),
(4,			'AADNativeAppId',				'AAD-native-app-guid-here'),
(5,			'AADToken',						'token'),
(6,			'MinDocAgeDays',				'365')


SET IDENTITY_INSERT [GlobalConfig] OFF

-- LABELS --
SET IDENTITY_INSERT [Labels] ON

INSERT INTO [Labels] 
(Id,		LabelName,					LabelGuid)
VALUES 
(1,			'Public',					'label-guid-here'),
(2,			'Restricted',				'label-guid-here'),
(4,			'Confidential',				'label-guid-here'),
(5,			'Secret',					'label-guid-here')

SET IDENTITY_INSERT [Labels] OFF

-- SERVERS --
SET IDENTITY_INSERT [Servers] ON
INSERT INTO [Servers] 
(Id,	ServerName,							StartTime,			EndTime,		NumberInstances,		ServerComplete,	IsActive)
VALUES
(1,		'EXECUTING-SERVER-NAME',			'09:00:00',			'17:00:00',		1,						0,				1)
SET IDENTITY_INSERT [Servers] OFF

-- FILE SERVERS --
SET IDENTITY_INSERT [FileServers] ON
INSERT INTO [FileServers] 
(Id,	FileServer,					BJPCStartDate,			BJPCEndDate)
VALUES
(1,		'FILESERVER-X',				'2018-08-06',		'2018-08-10'),
(2,		'FILESERVER-Y',				'2018-09-06',		'2018-09-10')
SET IDENTITY_INSERT [FileServers] OFF

-- SERVERS - FILE SERVERS --
INSERT INTO [ServersFileServers] 
(ServerId,		FileServerId)
VALUES
(1,				1),
(1,				2)


-- STATUS CODES --
INSERT INTO [StatusCodes] (Status) VALUES 
('NotStarted'),('InProgress'),('SuccessfulEncrypt'),('EncryptError'),('FailedDecrypt'),('WillNotEncrypt'),('NotFound'), ('UnderMinAge')

