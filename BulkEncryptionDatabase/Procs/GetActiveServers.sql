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

