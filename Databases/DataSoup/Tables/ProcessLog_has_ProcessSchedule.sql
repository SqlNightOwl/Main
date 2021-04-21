use DataSoup
go
ALTER TABLE [tcu].[ProcessLog] ADD CONSTRAINT [ProcessLog_has_ProcessSchedule] FOREIGN KEY 
	(
		[ProcessId],
		[ScheduleId]
	) REFERENCES [tcu].[ProcessSchedule] (
		[ProcessId],
		[ScheduleId]
	) NOT FOR REPLICATION 
GO
alter table [tcu].[ProcessLog] nocheck constraint [ProcessLog_has_ProcessSchedule]
GO
GO