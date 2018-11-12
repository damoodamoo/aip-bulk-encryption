--RESET START
--UPDATE files SET Status = 1, StartedWhen = null, CompletedWhen = null, InstanceId = null, Exception = null, retrycount=0 WHERE id = 42; 

--SET IDENTITY_INSERT [Files] ON
--INSERT INTO [Files]([id],[Status],[FileServer],[LabelId],[FilePath]) VALUES (42,1,'oscillator',5,'c:\test\blah.txt')
--SET IDENTITY_INSERT [Files] OFF

delete from files where fileserver='oscillator'
delete from instances where serverid=3 
delete from dbo.serversfileservers where serverid=3
delete from dbo.servers where id=3

INSERT INTO [Files]([Status],[FileServer],[LabelId],[FilePath]) VALUES (1,'oscillator',5,'c:\test\blah.txt')
INSERT INTO [Files]([Status],[FileServer],[LabelId],[FilePath]) VALUES (1,'oscillator',5,'c:\test\testfolder')
INSERT INTO [Files]([Status],[FileServer],[LabelId],[FilePath]) VALUES (1,'oscillator',5,'c:\test\badfile.txt')
INSERT INTO [Files]([Status],[FileServer],[LabelId],[FilePath]) VALUES (1,'oscillator',5,'c:\test\listing')
INSERT INTO [Files]([Status],[FileServer],[LabelId],[FilePath]) VALUES (1,'oscillator',5,'c:\test\unlabeled.docx')
INSERT INTO [Files]([Status],[FileServer],[LabelId],[FilePath]) VALUES (1,'oscillator',5,'c:\test\alreadylabeled.docx')

SET IDENTITY_INSERT [Servers] ON
INSERT INTO [Servers] (Id,ServerName,StartTime,EndTime,NumberInstances,ServerComplete) VALUES (3,'oscillator','09:00:00','17:00:00',1,NULL)
SET IDENTITY_INSERT [Servers] OFF

INSERT INTO [ServersFileServers] (ServerId,FileServer) VALUES (3,'oscillator')

select * from dbo.servers where id=3
SELECT * FROM [dbo].[ServersFileServers] where serverid=3
SELECT * FROM [dbo].[Files] where fileserver='oscillator'
SELECT count(*) FROM [dbo].[Files] where fileserver='oscillator'
select * from instances where serverid=3
--RESET END


--update servers set servercomplete=null where id=3

